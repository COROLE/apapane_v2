const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { google } = require('googleapis');
const { createHash, randomUUID } = require('node:crypto');
const sharp = require('sharp');
const withAppCheck = functions.runWith({ enforceAppCheck: true });
const withGeminiSecret = functions.runWith({
  secrets: ['GEMINI_API_KEY'],
});
const withPurchaseSecrets = functions.runWith({
  enforceAppCheck: true,
  secrets: ['PLAY_SERVICE_ACCOUNT_JSON', 'APPLE_SHARED_SECRET'],
});
const GOOGLE_CLOUD_TTS_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';
const GOOGLE_CLOUD_TTS_LANGUAGE_CODE = 'ja-JP';
const GOOGLE_CLOUD_TTS_VOICE_NAME = 'ja-JP-Wavenet-B';
const SAFETY_AUDIT_COLLECTION = 'aiSafetyAuditLogs';
const RATE_LIMIT_COLLECTION = 'aiRateLimits';
const CHILD_SAFE_REWRITE_MESSAGE =
  'アパパネでは、子ども向けのやさしく安全なおはなしと絵だけを作れます。別のやさしい内容で試してください。';
const STORY_GENERATION_MAX_ATTEMPTS = 3;
const STORY_RATE_LIMIT = {
  key: 'story',
  maxCalls: 12,
  windowMs: 60 * 1000,
};
const IMAGE_RATE_LIMIT = {
  key: 'image',
  maxCalls: 16,
  windowMs: 60 * 1000,
};
const TTS_RATE_LIMIT = {
  key: 'tts',
  maxCalls: 24,
  windowMs: 60 * 1000,
};
const CHILD_SAFE_STORY_PREFIX = `
You are generating content for a child-directed storytelling app.
- Keep the content gentle, reassuring, and age-appropriate for young children.
- Do not include sexual content, graphic violence, self-harm, illegal drugs, hateful abuse, or contact-seeking behavior.
- Do not ask for personal information, phone numbers, email addresses, usernames, home addresses, or external contact.
- If the user asks for unsafe content, refuse silently by producing a safe alternative adventure instead.
`.trim();
const CHILD_SAFE_IMAGE_PREFIX = `
Create a warm, child-safe illustration for a young audience.
- No nudity, fetish content, romance for adults, graphic injuries, blood, gore, weapons aimed at the viewer, drugs, alcohol, or smoking.
- Prefer bright colors, friendly expressions, soft lighting, and non-threatening scenes.
`.trim();
const UNSAFE_VISUAL_NEGATIVE_PROMPT = [
  'gore',
  'blood',
  'severed limbs',
  'graphic injury',
  'nudity',
  'sexual content',
  'drugs',
  'alcohol',
  'smoking',
  'vaping',
  'weapons aimed at viewer',
  'horror close-up',
].join(', ');
const UNSAFE_RULES = [
  {
    category: 'sexual_content',
    pattern:
      /\b(sex|sexual|nude|naked|porn|porno|fetish|erotic|genital|breast|xxx)\b|セックス|性的|裸|ヌード|ポルノ|エロ|性器|おっぱい/i,
  },
  {
    category: 'graphic_violence',
    pattern:
      /\b(kill|murder|slaughter|gore|blood|bloody|decapitat|dismember|torture|corpse)\b|殺す|殺人|流血|残酷|拷問|死体|首を切/i,
  },
  {
    category: 'self_harm',
    pattern:
      /\b(suicide|self-harm|self harm|cut myself|hurt myself)\b|自殺|自傷|死にたい|リスカ/i,
  },
  {
    category: 'drugs_or_adult_substances',
    pattern:
      /\b(cocaine|meth|heroin|marijuana|weed|vape|smoking|cigarette|vodka|beer|alcohol)\b|大麻|覚醒剤|コカイン|ヘロイン|たばこ|喫煙|飲酒|お酒/i,
  },
  {
    category: 'personal_contact',
    pattern:
      /\b(phone number|email address|home address|line id|discord|instagram|dm me|meet me)\b|電話番号|メールアドレス|住所|連絡先|会おう|DMして|ライン/i,
  },
  {
    category: 'hateful_abuse',
    pattern:
      /\b(hate crime|racial slur|nazi)\b|人種差別|ヘイト|ナチ/i,
  },
];

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

exports.generateStory = withGeminiSecret.https.onCall(async (data, context) => {
  const caller = resolveGeneratorCaller(context, data);

  const prompt = readString(data.prompt, 'prompt');
  const systemPrompt = readString(data.systemPrompt, 'systemPrompt');
  const jsonOutput = data.jsonOutput === true;
  const responseSchema =
    data.responseSchema && typeof data.responseSchema === 'object'
      ? data.responseSchema
      : data.responseJsonSchema && typeof data.responseJsonSchema === 'object'
          ? data.responseJsonSchema
          : null;

  const text = await generateSafeStory({
    callerId: caller.id,
    prompt,
    systemPrompt,
    jsonOutput,
    responseSchema,
  });

  return { text };
});

exports.generateImage = withGeminiSecret.https.onCall(async (data, context) => {
  const caller = resolveGeneratorCaller(context, data);

  const prompt = readString(data.prompt, 'prompt');
  const negativePrompt =
    typeof data.negativePrompt === 'string' ? data.negativePrompt : '';
  const seed = Number.isInteger(data.seed) ? data.seed : 0;

  return generateSafeImage({
    callerId: caller.id,
    prompt,
    negativePrompt,
    seed,
  });
});

exports.generateImageHttp = withGeminiSecret.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Headers', 'Content-Type, X-Firebase-AppCheck');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method-not-allowed' });
    return;
  }

  try {
    const body = normalizeHttpBody(req.body);
    const caller = resolveGeneratorCaller({ rawRequest: req }, body);
    const prompt = readString(body.prompt, 'prompt');
    const negativePrompt =
      typeof body.negativePrompt === 'string' ? body.negativePrompt : '';
    const seed = Number.isInteger(body.seed) ? body.seed : 0;

    const result = await generateSafeImage({
      callerId: caller.id,
      prompt,
      negativePrompt,
      seed,
    });

    res.status(200).json(result);
  } catch (error) {
    sendHttpError(res, error);
  }
});

exports.synthesizeVoice = withAppCheck.https.onCall(async (data, context) => {
  requireCallableAppCheck(context);
  const caller = resolveGeneratorCaller(context, data);

  const text = readString(data.text, 'text');
  await enforceRateLimit(caller.id, TTS_RATE_LIMIT);
  const blockedCategory = findUnsafeCategory(text);
  if (blockedCategory) {
    await writeSafetyAuditLog({
      uid: caller.id,
      feature: 'tts',
      stage: 'prompt',
      allowed: false,
      reason: blockedCategory,
      prompt: text,
    });
    throw createChildSafeError();
  }

  const audioBase64 = await synthesizeJapaneseSpeech(text);
  if (typeof audioBase64 !== 'string' || audioBase64.trim().length === 0) {
    throw new functions.https.HttpsError(
      'internal',
      '音声データを取得できませんでした。',
    );
  }

  await writeSafetyAuditLog({
    uid: caller.id,
    feature: 'tts',
    stage: 'response',
    allowed: true,
    prompt: text,
  });

  return {
    audioBase64: audioBase64.trim(),
    contentType: 'audio/mpeg',
  };
});

exports.verifyPurchase = withPurchaseSecrets.https.onCall(async (data, context) => {
  requireCallableAppCheck(context);
  const uid = requireParentAccount(context);

  const platform = readString(data.platform, 'platform');
  const packageName = readString(data.packageName, 'packageName');
  const productId = readString(data.productId, 'productId');
  const purchaseId = readString(data.purchaseId, 'purchaseId');
  const verificationData = readString(
    data.verificationData,
    'verificationData',
  );

  if (productId === 'consumable') {
    if (platform === 'android') {
      await verifyAndroidConsumable({
        packageName,
        productId,
        purchaseToken: verificationData,
      });
    } else if (platform === 'ios') {
      await verifyIosConsumable({
        productId,
        receiptData: verificationData,
      });
    } else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `未対応のプラットフォームです: ${platform}`,
      );
    }

    return grantConsumable({
      uid,
      purchaseId,
      productId,
      platform,
    });
  }

  if (productId === 'silver_subscription') {
    let subscription;
    if (platform === 'android') {
      subscription = await verifyAndroidSubscription({
        packageName,
        subscriptionId: productId,
        purchaseToken: verificationData,
      });
    } else if (platform === 'ios') {
      subscription = await verifyIosSubscription({
        productId,
        receiptData: verificationData,
      });
    } else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `未対応のプラットフォームです: ${platform}`,
      );
    }

    return grantSubscription({
      uid,
      purchaseId,
      productId,
      platform,
      expiresAtMs: subscription.expiresAtMs,
    });
  }

  throw new functions.https.HttpsError(
    'invalid-argument',
    `未対応の商品です: ${productId}`,
  );
});

exports.deleteAccount = withAppCheck.https.onCall(async (_, context) => {
  requireCallableAppCheck(context);
  const uid = requireParentAccount(context);
  const userRef = db.collection('users').doc(uid);

  await deleteUserStorage(uid);
  await db.recursiveDelete(userRef);
  await admin.auth().deleteUser(uid);

  return { deleted: true };
});

async function generateSafeStory({
  callerId,
  prompt,
  systemPrompt,
  jsonOutput,
  responseSchema,
}) {
  await enforceRateLimit(callerId, STORY_RATE_LIMIT);

  const blockedCategory = findUnsafeCategory([prompt, systemPrompt].join('\n\n'));
  if (blockedCategory) {
    await writeSafetyAuditLog({
      uid: callerId,
      feature: 'story',
      stage: 'prompt',
      allowed: false,
      reason: blockedCategory,
      prompt,
    });
    throw createChildSafeError();
  }

  const safeSystemPrompt = [CHILD_SAFE_STORY_PREFIX, systemPrompt]
    .filter(Boolean)
    .join('\n\n');

  for (let attempt = 1; attempt <= STORY_GENERATION_MAX_ATTEMPTS; attempt += 1) {
    const text = await callGeminiText({
      prompt,
      systemPrompt: safeSystemPrompt,
      apiKey: readEnv('GEMINI_API_KEY'),
      jsonOutput,
      responseSchema,
    });
    const responseCategory = findUnsafeCategory(text);
    if (!responseCategory) {
      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'story',
        stage: 'response',
        allowed: true,
        prompt,
        output: text,
        metadata: { attempt, jsonOutput },
      });
      return text;
    }

    await writeSafetyAuditLog({
      uid: callerId,
      feature: 'story',
      stage: 'response',
      allowed: false,
      reason: responseCategory,
      prompt,
      output: text,
      metadata: { attempt, jsonOutput },
    });
  }

  throw createChildSafeError();
}

async function generateSafeImage({ callerId, prompt, negativePrompt, seed }) {
  await enforceRateLimit(callerId, IMAGE_RATE_LIMIT);

  const blockedCategory = findUnsafeCategory(
    [prompt, negativePrompt].filter(Boolean).join('\n\n'),
  );
  if (blockedCategory) {
    await writeSafetyAuditLog({
      uid: callerId,
      feature: 'image',
      stage: 'prompt',
      allowed: false,
      reason: blockedCategory,
      prompt,
      metadata: { negativePrompt },
    });
    throw createChildSafeError();
  }

  const result = await callGeminiImage({
    prompt: [CHILD_SAFE_IMAGE_PREFIX, prompt].join('\n\n'),
    negativePrompt: [negativePrompt, UNSAFE_VISUAL_NEGATIVE_PROMPT]
      .filter(Boolean)
      .join(', '),
    apiKey: readEnv('GEMINI_API_KEY'),
    seed,
  });

  const response = {
    base64: result.imageBuffer.toString('base64'),
    seed: result.seed,
  };

  try {
    const uploadedImage = await storeGeneratedImage({
      callerId,
      imageBuffer: result.imageBuffer,
      seed: result.seed,
    });
    response.imageUrl = uploadedImage.downloadUrl;
    response.storagePath = uploadedImage.storagePath;
  } catch (error) {
    functions.logger.error('Failed to store generated image preview.', error);
  }

  await writeSafetyAuditLog({
    uid: callerId,
    feature: 'image',
    stage: 'response',
    allowed: true,
    prompt,
    metadata: {
      seed: result.seed,
      storedPreview: typeof response.storagePath === 'string',
      storagePath: response.storagePath ?? '',
    },
  });

  return response;
}

async function synthesizeJapaneseSpeech(text) {
  const accessToken = await getGoogleAccessToken([GOOGLE_CLOUD_TTS_SCOPE]);
  const payload = await postJson(
    'https://texttospeech.googleapis.com/v1/text:synthesize',
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
      body: {
        input: {
          text,
        },
        voice: {
          languageCode: GOOGLE_CLOUD_TTS_LANGUAGE_CODE,
          name: GOOGLE_CLOUD_TTS_VOICE_NAME,
        },
        audioConfig: {
          audioEncoding: 'MP3',
          speakingRate: 1.0,
        },
      },
    },
  );

  return payload.audioContent;
}

async function callGeminiText({
  prompt,
  systemPrompt,
  apiKey,
  jsonOutput,
  responseSchema,
}) {
  const model = jsonOutput ? 'gemini-2.5-flash' : 'gemini-2.5-flash-lite';
  const payload = await postJson(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      headers: {
        'x-goog-api-key': apiKey,
      },
      body: {
        contents: [
          {
            parts: [{ text: prompt }],
          },
        ],
        systemInstruction: {
          parts: [{ text: systemPrompt }],
        },
        generationConfig: {
          temperature: jsonOutput ? 0.7 : 0.4,
          maxOutputTokens: jsonOutput ? 4096 : 256,
          ...(jsonOutput ? { responseMimeType: 'application/json' } : {}),
          ...(jsonOutput && responseSchema
            ? { responseSchema }
            : {}),
        },
      },
    },
  );

  const candidates = Array.isArray(payload.candidates) ? payload.candidates : [];
  const parts = candidates[0]?.content?.parts;
  const text = Array.isArray(parts)
    ? parts
        .map((part) => (typeof part.text === 'string' ? part.text.trim() : ''))
        .filter(Boolean)
        .join('\n')
    : '';
  if (!text) {
    throw new functions.https.HttpsError(
      'internal',
      '文章生成の結果を取得できませんでした。',
    );
  }
  return text;
}

async function callGeminiImage({ prompt, negativePrompt, apiKey, seed }) {
  const mergedPrompt = [
    prompt.trim(),
    negativePrompt.trim()
      ? `Avoid the following elements: ${negativePrompt.trim()}`
      : '',
  ]
    .filter(Boolean)
    .join('\n\n');

  const payload = await postJson(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent',
    {
      headers: {
        'x-goog-api-key': apiKey,
      },
      body: {
        contents: [
          {
            parts: [{ text: mergedPrompt }],
          },
        ],
        generationConfig: {
          responseModalities: ['TEXT', 'IMAGE'],
          imageConfig: {
            aspectRatio: '9:16',
          },
        },
      },
    },
  );

  const candidates = Array.isArray(payload.candidates) ? payload.candidates : [];
  for (const candidate of candidates) {
    const parts = candidate?.content?.parts;
    if (!Array.isArray(parts)) {
      continue;
    }
    for (const part of parts) {
      const base64 = part?.inlineData?.data;
      if (typeof base64 === 'string' && base64.trim().length > 0) {
        const normalizedBuffer = await normalizeGeneratedImage(base64.trim());
        return {
          imageBuffer: normalizedBuffer,
          seed: seed || Date.now(),
        };
      }
    }
  }

  throw new functions.https.HttpsError(
    'internal',
    '画像生成の結果を取得できませんでした。',
  );
}

async function normalizeGeneratedImage(base64Data) {
  const inputBuffer = Buffer.from(base64Data, 'base64');
  const outputBuffer = await sharp(inputBuffer)
    .rotate()
    .resize({
      width: 1080,
      height: 1920,
      fit: 'contain',
      background: {
        r: 247,
        g: 240,
        b: 232,
        alpha: 1,
      },
    })
    .jpeg({
      quality: 74,
      mozjpeg: true,
      chromaSubsampling: '4:2:0',
    })
    .toBuffer();

  functions.logger.info('Normalized generated image.', {
    inputBytes: inputBuffer.length,
    outputBytes: outputBuffer.length,
  });

  return outputBuffer;
}

async function storeGeneratedImage({ callerId, imageBuffer, seed }) {
  const bucketName = resolveStorageBucket();
  if (!bucketName) {
    throw new functions.https.HttpsError(
      'internal',
      '画像保存先の Storage バケットを解決できませんでした。',
    );
  }

  const token = randomUUID();
  const fileName = `${Date.now()}-${seed || 'image'}-${token}.jpg`;
  const storagePath = `users/${callerId}/generated-previews/${fileName}`;
  const file = admin.storage().bucket(bucketName).file(storagePath);

  await file.save(imageBuffer, {
    resumable: false,
    metadata: {
      contentType: 'image/jpeg',
      cacheControl: 'public,max-age=31536000',
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  });

  const encodedPath = encodeURIComponent(storagePath);
  const downloadUrl = `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media&token=${token}`;

  functions.logger.info('Stored generated image preview.', {
    storagePath,
    outputBytes: imageBuffer.length,
  });

  return {
    storagePath,
    downloadUrl,
  };
}

function findUnsafeCategory(text) {
  const normalized = typeof text === 'string' ? text.trim() : '';
  if (!normalized) {
    return '';
  }

  for (const rule of UNSAFE_RULES) {
    if (rule.pattern.test(normalized)) {
      return rule.category;
    }
  }

  return '';
}

function createChildSafeError() {
  return new functions.https.HttpsError(
    'failed-precondition',
    CHILD_SAFE_REWRITE_MESSAGE,
  );
}

async function enforceRateLimit(uid, config) {
  const ref = db.collection(RATE_LIMIT_COLLECTION).doc(`${config.key}_${uid}`);
  const nowMs = Date.now();

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.data() || {};
    let count = Number(data.count ?? 0);
    let windowStartedAtMs = Number(data.windowStartedAtMs ?? 0);

    if (!windowStartedAtMs || nowMs - windowStartedAtMs >= config.windowMs) {
      count = 0;
      windowStartedAtMs = nowMs;
    }

    if (count >= config.maxCalls) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        '生成リクエストが多すぎます。少し待ってからもう一度お試しください。',
      );
    }

    transaction.set(
      ref,
      {
        uid,
        feature: config.key,
        count: count + 1,
        windowStartedAtMs,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function writeSafetyAuditLog({
  uid,
  feature,
  stage,
  allowed,
  reason = '',
  prompt = '',
  output = '',
  metadata = {},
}) {
  try {
    await db.collection(SAFETY_AUDIT_COLLECTION).add({
      uid,
      feature,
      stage,
      allowed,
      reason,
      promptPreview: truncateText(prompt, 500),
      outputPreview: truncateText(output, 500),
      metadata,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    functions.logger.error('Failed to write safety audit log.', error);
  }
}

function truncateText(value, maxLength) {
  if (typeof value !== 'string') {
    return '';
  }

  const normalized = value.trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }

  return `${normalized.slice(0, maxLength - 1)}…`;
}


async function verifyAndroidConsumable({ packageName, productId, purchaseToken }) {
  const publisher = buildAndroidPublisherClient();
  const response = await publisher.purchases.products.get({
    packageName,
    productId,
    token: purchaseToken,
  });
  if (response?.data?.purchaseState !== 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Android の購入状態を確認できませんでした。',
    );
  }
}

async function verifyAndroidSubscription({
  packageName,
  subscriptionId,
  purchaseToken,
}) {
  const publisher = buildAndroidPublisherClient();
  const response = await publisher.purchases.subscriptions.get({
    packageName,
    subscriptionId,
    token: purchaseToken,
  });
  const expiryTimeMillis = Number(response?.data?.expiryTimeMillis ?? 0);
  if (!expiryTimeMillis) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Android の定期購入の有効期限を確認できませんでした。',
    );
  }
  return {
    expiresAtMs: expiryTimeMillis,
  };
}

async function verifyIosConsumable({ productId, receiptData }) {
  const payload = await verifyIosReceipt(receiptData);
  const inApp = payload?.receipt?.in_app;
  const match = Array.isArray(inApp)
    ? inApp.find((entry) => entry.product_id === productId)
    : null;
  if (!match) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'iOS のレシートに購入済み商品が見つかりませんでした。',
    );
  }
}

async function verifyIosSubscription({ productId, receiptData }) {
  const payload = await verifyIosReceipt(receiptData);
  const latest = Array.isArray(payload.latest_receipt_info)
    ? payload.latest_receipt_info
        .filter((entry) => entry.product_id === productId)
        .sort((left, right) => {
          const leftMs = Number(left.expires_date_ms ?? 0);
          const rightMs = Number(right.expires_date_ms ?? 0);
          return rightMs - leftMs;
        })[0]
    : null;

  const expiresAtMs = Number(latest?.expires_date_ms ?? 0);
  if (!expiresAtMs) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'iOS の定期購入の有効期限を確認できませんでした。',
    );
  }

  return { expiresAtMs };
}

async function verifyIosReceipt(receiptData) {
  const sharedSecret = readEnv('APPLE_SHARED_SECRET');
  const productionPayload = await postJson(
    'https://buy.itunes.apple.com/verifyReceipt',
    {
      body: {
        'receipt-data': receiptData,
        password: sharedSecret,
      },
    },
  );

  if (productionPayload.status === 21007) {
    return postJson('https://sandbox.itunes.apple.com/verifyReceipt', {
      body: {
        'receipt-data': receiptData,
        password: sharedSecret,
      },
    });
  }

  if (productionPayload.status !== 0) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Apple のレシート確認に失敗しました。status=${productionPayload.status}`,
    );
  }

  return productionPayload;
}

async function grantConsumable({ uid, purchaseId, productId, platform }) {
  const userRef = db.collection('users').doc(uid);
  const consumableRef = userRef.collection('consumables').doc(purchaseId);

  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(consumableRef);
    if (existing.exists) {
      return;
    }

    transaction.set(consumableRef, {
      productId,
      platform,
      purchaseId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.set(
      userRef,
      {
        coins: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return readUserData(uid);
}

async function grantSubscription({
  uid,
  purchaseId,
  productId,
  platform,
  expiresAtMs,
}) {
  const userRef = db.collection('users').doc(uid);
  const subscriptionRef = userRef.collection('subscriptions').doc(purchaseId);
  const expiresAt = admin.firestore.Timestamp.fromMillis(expiresAtMs);

  await db.runTransaction(async (transaction) => {
    transaction.set(
      subscriptionRef,
      {
        productId,
        platform,
        purchaseId,
        endAt: expiresAt,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.set(
      userRef,
      {
        silverSubscription: {
          isActive: expiresAtMs > Date.now(),
          productId,
          platform,
          endAt: expiresAt,
          purchaseId,
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  return readUserData(uid);
}

async function readUserData(uid) {
  const snapshot = await db.collection('users').doc(uid).get();
  return snapshot.data() || {};
}

function buildAndroidPublisherClient() {
  const credentials = readJsonEnv('PLAY_SERVICE_ACCOUNT_JSON');
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return google.androidpublisher({
    version: 'v3',
    auth,
  });
}

async function deleteUserStorage(uid) {
  const bucketName = resolveStorageBucket();
  if (!bucketName) {
    return;
  }

  await admin
    .storage()
    .bucket(bucketName)
    .deleteFiles({ prefix: `users/${uid}/` });
}

function resolveStorageBucket() {
  const configuredBucket = admin.app().options.storageBucket;
  if (typeof configuredBucket === 'string' && configuredBucket.trim().length > 0) {
    return configuredBucket.trim();
  }

  const firebaseConfig = process.env.FIREBASE_CONFIG;
  if (typeof firebaseConfig === 'string' && firebaseConfig.trim().length > 0) {
    try {
      const parsedConfig = JSON.parse(firebaseConfig);
      if (
        typeof parsedConfig.storageBucket === 'string' &&
        parsedConfig.storageBucket.trim().length > 0
      ) {
        return parsedConfig.storageBucket.trim();
      }
    } catch (_) {
      return '';
    }
  }

  return '';
}

async function getGoogleAccessToken(scopes) {
  const auth = new google.auth.GoogleAuth({ scopes });
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();
  const token =
    typeof accessToken === 'string' ? accessToken : accessToken?.token;
  if (typeof token === 'string' && token.trim().length > 0) {
    return token.trim();
  }

  throw new functions.https.HttpsError(
    'failed-precondition',
    'Google Cloud のアクセストークンを取得できませんでした。',
  );
}

async function postJson(url, { headers = {}, body }) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify(body),
  });
  const payload = await parseJson(response);
  if (!response.ok) {
    throw new functions.https.HttpsError(
      'internal',
      extractApiError(payload),
    );
  }
  return payload;
}

async function parseJson(response) {
  const text = await response.text();
  if (!text) {
    return {};
  }
  try {
    return JSON.parse(text);
  } catch (_) {
    return { raw: text };
  }
}

function normalizeHttpBody(body) {
  if (body && typeof body === 'object' && !Array.isArray(body)) {
    if (body.data && typeof body.data === 'object' && !Array.isArray(body.data)) {
      return body.data;
    }
    return body;
  }

  if (typeof body === 'string' && body.trim().length > 0) {
    try {
      const parsedBody = JSON.parse(body);
      if (
        parsedBody &&
        typeof parsedBody === 'object' &&
        !Array.isArray(parsedBody)
      ) {
        if (
          parsedBody.data &&
          typeof parsedBody.data === 'object' &&
          !Array.isArray(parsedBody.data)
        ) {
          return parsedBody.data;
        }
        return parsedBody;
      }
    } catch (_) {
      return {};
    }
  }

  return {};
}

function sendHttpError(res, error) {
  if (error instanceof functions.https.HttpsError) {
    const statusByCode = {
      'invalid-argument': 400,
      'failed-precondition': 400,
      unauthenticated: 401,
      'permission-denied': 403,
      'resource-exhausted': 429,
    };
    const statusCode = statusByCode[error.code] ?? 500;
    res.status(statusCode).json({
      error: error.code,
      message: error.message,
    });
    return;
  }

  functions.logger.error('Unhandled HTTP function error.', error);
  res.status(500).json({
    error: 'internal',
    message: error instanceof Error ? error.message : String(error),
  });
}

function extractApiError(payload) {
  if (typeof payload === 'string' && payload.trim().length > 0) {
    return payload.trim();
  }
  if (payload && typeof payload === 'object') {
    if (typeof payload.error === 'string') {
      return payload.error;
    }
    if (payload.error && typeof payload.error.message === 'string') {
      return payload.error.message;
    }
    if (typeof payload.message === 'string') {
      return payload.message;
    }
    if (typeof payload.raw === 'string') {
      return payload.raw;
    }
  }
  return 'API エラーが発生しました。';
}

function requireAuth(context) {
  const uid = context?.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'ログインが必要です。',
    );
  }
  return uid;
}

function requireCallableAppCheck(context) {
  const appId =
    typeof context?.app?.appId === 'string' ? context.app.appId.trim() : '';
  if (!appId) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'App Check token is required.',
    );
  }
  return appId;
}

async function requireHttpAppCheck(req, appCheck = admin.appCheck()) {
  const token = readHeaderValue(req?.headers?.['x-firebase-appcheck']);
  if (!token) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'App Check token is required.',
    );
  }

  try {
    const verification = await appCheck.verifyToken(token);
    const appId =
      typeof verification?.appId === 'string' ? verification.appId.trim() : '';
    if (!appId) {
      throw new Error('App Check verification did not return appId.');
    }
    return verification;
  } catch (error) {
    functions.logger.warn('Failed to verify App Check token.', error);
    throw new functions.https.HttpsError(
      'unauthenticated',
      'App Check token is invalid.',
    );
  }
}

function resolveGeneratorCaller(context, data) {
  const authUid = context?.auth?.uid;
  if (typeof authUid === 'string' && authUid.trim().length > 0) {
    return {
      id: authUid.trim(),
      mode: 'auth',
    };
  }

  const guestSessionId =
    typeof data?.guestSessionId === 'string' ? data.guestSessionId.trim() : '';
  if (guestSessionId) {
    return {
      id: `guest_${hashGuestSessionId(guestSessionId)}`,
      mode: 'guest',
    };
  }

  throw new functions.https.HttpsError(
    'unauthenticated',
    'ゲストセッションを確認できませんでした。',
  );
}

function hashGuestSessionId(guestSessionId) {
  return createHash('sha256').update(guestSessionId).digest('hex').slice(0, 32);
}

function readHeaderValue(value) {
  if (Array.isArray(value)) {
    return value
      .map((item) => (typeof item === 'string' ? item.trim() : ''))
      .filter(Boolean)
      .join(',');
  }
  if (typeof value === 'string') {
    return value.trim();
  }
  return '';
}

function requireParentAccount(context) {
  const uid = requireAuth(context);
  if (context?.auth?.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'この操作には保護者アカウントが必要です。',
    );
  }
  return uid;
}

function readEnv(name, { required = true } = {}) {
  const value = process.env[name];
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  if (!required) {
    return '';
  }
  throw new functions.https.HttpsError(
    'failed-precondition',
    `サーバー設定が不足しています: ${name}`,
  );
}

function readJsonEnv(name) {
  const rawValue = readEnv(name);
  try {
    return JSON.parse(rawValue);
  } catch (_) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `サーバー設定の JSON が不正です: ${name}`,
    );
  }
}

function readString(value, fieldName) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `必須項目が不足しています: ${fieldName}`,
    );
  }
  return value.trim();
}

exports.__test__ = {
  CHILD_SAFE_REWRITE_MESSAGE,
  extractApiError,
  findUnsafeCategory,
  hashGuestSessionId,
  normalizeHttpBody,
  readHeaderValue,
  readString,
  requireCallableAppCheck,
  requireHttpAppCheck,
  resolveGeneratorCaller,
};
