const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { google } = require('googleapis');
const { createHash, randomUUID } = require('node:crypto');
const sharp = require('sharp');
const withAppCheck = functions.runWith({ enforceAppCheck: true });
const withGeminiSecret = functions.runWith({
  secrets: ['GEMINI_API_KEY'],
  timeoutSeconds: 120,
});
const withOpenAiSecret = functions.runWith({
  secrets: ['OPENAI_API_KEY'],
  timeoutSeconds: 180,
  memory: '1GB',
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
const STORY_PREVIEW_MAX_ATTEMPTS = 3;
const DEFAULT_STORY_MODE_KEY = 'mini';
const DEFAULT_NEW_STORY_MODE_KEY = 'standard';
const SILVER_MONTHLY_STORY_CREDITS = 6;
const STORY_MODES = Object.freeze({
  mini: Object.freeze({
    key: 'mini',
    displayName: 'みじかい',
    pageCount: 4,
    coinCost: 1,
    usage: 'おためし、短いおはなし',
    beats: Object.freeze([
      '主人公紹介',
      '事件やお願い',
      '解決',
      '余韻・オチ',
    ]),
  }),
  standard: Object.freeze({
    key: 'standard',
    displayName: 'ふつう',
    pageCount: 8,
    coinCost: 2,
    usage: 'メイン商品。ちゃんと冒険できる',
    beats: Object.freeze([
      '主人公と願い',
      'ふしぎな出来事・招待・お願い',
      '冒険の始まり',
      '最初の失敗',
      '子どもが選んだ性格・道具・仲間が活きる',
      '大きなピンチ',
      '解決・クライマックス',
      'ごほうび・オチ・余韻',
    ]),
  }),
  premium: Object.freeze({
    key: 'premium',
    displayName: 'たっぷり',
    pageCount: 12,
    coinCost: 3,
    usage: '特別な1冊、長めの冒険',
    beats: Object.freeze([
      '主人公と日常',
      '願い・悩み・好きなもの',
      'ふしぎなきっかけ',
      '冒険開始',
      '仲間または道具の登場',
      '最初の挑戦',
      '小さな成功',
      'より大きな問題',
      '主人公の選択',
      'クライマックス',
      '解決',
      '余韻・眠る前にも読める締め',
    ]),
  }),
});
const STORY_OPTION_VALUES = Object.freeze({
  tone: Object.freeze(['funny', 'heartwarming', 'bedtime', 'adventure']),
  endingStyle: Object.freeze(['happy', 'gentle', 'funnyTwist']),
  worldType: Object.freeze(['forest', 'ocean', 'space', 'sweets', 'dinosaur', 'custom']),
});
const STORY_OPTION_LABELS = Object.freeze({
  tone: Object.freeze({
    funny: 'おもしろい',
    heartwarming: 'あたたかい',
    bedtime: '寝る前向け',
    adventure: 'ぼうけん',
  }),
  endingStyle: Object.freeze({
    happy: 'ハッピーエンド',
    gentle: 'ほっとする終わり',
    funnyTwist: 'ちょっと笑える終わり',
  }),
  worldType: Object.freeze({
    forest: '森',
    ocean: '海',
    space: '宇宙',
    sweets: 'おかしの国',
    dinosaur: '恐竜の島',
    custom: '子どもの入力を優先',
  }),
});
const STORY_OPTION_DEFAULTS = Object.freeze({
  tone: 'adventure',
  endingStyle: 'funnyTwist',
  worldType: 'custom',
});
const GENERIC_PREVIEW_PLAN_FRAGMENTS = Object.freeze([
  'ふしぎな出来事が広がり',
  '一歩ずつ進む',
  '力を合わせて解決',
  '余韻で終わる',
  '楽しく過ごしました',
  '小さな願いを見つける',
]);
const STORY_BODY_PAGE_COUNT = STORY_MODES.mini.pageCount;
const STORY_REQUIRED_PAGE_FIELDS = [
  'story',
  'visualFocus',
  'mood',
  'dialogue',
  'visibleCast',
];
const STORY_REQUIRED_CHARACTER_FIELDS = [
  'protagonist',
  'companion',
  'worldDetails',
  'artDirection',
];
const OPENAI_IMAGE_MODEL = 'gpt-image-2';
const OPENAI_IMAGE_SIZE = '1024x1536';
const OPENAI_IMAGE_QUALITY = 'high';
const OPENAI_IMAGE_OUTPUT_FORMAT = 'jpeg';
const OPENAI_IMAGE_OUTPUT_COMPRESSION = 90;
const IMAGE_OUTPUT_JPEG_QUALITY = 86;
const BANNED_STORY_ENDINGS = [
  'みんなで楽しく過ごしました',
  'みんなでたのしくすごしました',
  'みんな幸せに暮らしました',
  'みんなしあわせにくらしました',
  '楽しい一日でした',
  'たのしい一日でした',
  '大切なことを学びました',
  'たいせつなことを学びました',
  '友だちってすばらしいですね',
  '勇気を出せば何でもできます',
];
const STORY_RATE_LIMIT = {
  key: 'story',
  maxCalls: 12,
  windowMs: 60 * 1000,
};
const STORY_PREVIEW_RATE_LIMIT = {
  key: 'storyPreview',
  maxCalls: 8,
  windowMs: 60 * 1000,
};
const IMAGE_RATE_LIMIT = {
  key: 'image',
  maxCalls: 40,
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
Create a wholesome family picture-book illustration.
- Keep every character gentle, friendly, fully family-safe, and non-romantic.
- Prefer bright colors, friendly expressions, soft lighting, and cozy, non-threatening scenes.
- Do not include readable text, captions, logos, or watermarks in the image.
`.trim();
const UNSAFE_VISUAL_NEGATIVE_PROMPT = [
  'low quality',
  'blurry',
  'distorted anatomy',
  'extra limbs',
  'readable text',
  'caption',
  'logo',
  'watermark',
  'scary close-up',
  'unfriendly theme',
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
  rejectClientStoryPricing(data);

  const prompt = readString(data.prompt, 'prompt');
  const systemPrompt = readString(data.systemPrompt, 'systemPrompt');
  const jsonOutput = data.jsonOutput === true;
  const responseSchema =
    data.responseSchema && typeof data.responseSchema === 'object'
      ? data.responseSchema
      : data.responseJsonSchema && typeof data.responseJsonSchema === 'object'
          ? data.responseJsonSchema
          : null;
  const requestedStoryJson = isStoryJsonRequest({ jsonOutput, responseSchema });
  const mode = requestedStoryJson
    ? resolveStoryMode(data.mode, DEFAULT_STORY_MODE_KEY)
    : null;
  const storyOptions = requestedStoryJson
    ? normalizeStoryOptions(data.storyOptions)
    : STORY_OPTION_DEFAULTS;
  const effectiveResponseSchema = requestedStoryJson
    ? buildStoryResponseSchema(mode)
    : responseSchema;
  const preview =
    data.preview && typeof data.preview === 'object'
      ? normalizeStoryPreviewInput(data.preview, mode)
      : null;

  const text = await generateSafeStory({
    callerId: caller.id,
    prompt,
    systemPrompt,
    jsonOutput,
    responseSchema: effectiveResponseSchema,
    mode,
    storyOptions,
    preview,
  });

  return { text };
});

exports.generateStoryPreview = withGeminiSecret.https.onCall(
  async (data, context) => {
    const caller = resolveGeneratorCaller(context, data);
    rejectClientStoryPricing(data);
    const mode = resolveStoryMode(data.mode, DEFAULT_NEW_STORY_MODE_KEY);
    const storyOptions = normalizeStoryOptions(data.storyOptions);
    const chatLogs = readString(data.chatLogs, 'chatLogs');
    const summaryMainSettings =
      typeof data.summaryMainSettings === 'string'
        ? data.summaryMainSettings.trim()
        : '';

    const preview = await generateSafeStoryPreview({
      callerId: caller.id,
      chatLogs,
      summaryMainSettings,
      mode,
      storyOptions,
    });

    return {
      ...preview,
      mode: mode.key,
      pageCount: mode.pageCount,
      coinCost: mode.coinCost,
      storyOptions,
    };
  },
);

exports.getStoryCreationStatus = functions.https.onCall(
  async (_, context) => {
    const uid = requireParentAccount(context);
    return getStoryCreationStatusForUid(uid);
  },
);

exports.reserveStoryGeneration = functions.https.onCall(
  async (data, context) => {
    const uid = requireParentAccount(context);
    rejectClientStoryPricing(data);
    const mode = resolveStoryMode(data.mode, DEFAULT_NEW_STORY_MODE_KEY);
    const requestId = readRequestId(data.requestId);
    return reserveStoryGenerationForUid({ uid, mode, requestId });
  },
);

exports.completeStoryGeneration = functions.https.onCall(
  async (data, context) => {
    const uid = requireParentAccount(context);
    const requestId = readRequestId(data.requestId);
    return completeStoryGenerationForUid({ uid, requestId });
  },
);

exports.cancelStoryGeneration = functions.https.onCall(
  async (data, context) => {
    const uid = requireParentAccount(context);
    const requestId = readRequestId(data.requestId);
    const reason =
      typeof data.reason === 'string' ? data.reason.trim().slice(0, 120) : '';
    return cancelStoryGenerationForUid({ uid, requestId, reason });
  },
);

exports.generateImage = withOpenAiSecret.https.onCall(async (data, context) => {
  const caller = resolveGeneratorCaller(context, data);

  try {
    const prompt = readString(data.prompt, 'prompt');
    const negativePrompt =
      typeof data.negativePrompt === 'string' ? data.negativePrompt : '';
    const seed = Number.isInteger(data.seed) ? data.seed : 0;

    return await generateSafeImage({
      callerId: caller.id,
      prompt,
      negativePrompt,
      seed,
    });
  } catch (error) {
    logImageGenerationFailure('generateImage', caller.id, error);
    throw error;
  }
});

exports.generateImageHttp = withOpenAiSecret.https.onRequest(async (req, res) => {
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

  let callerId = 'http';
  try {
    const body = normalizeHttpBody(req.body);
    const caller = resolveGeneratorCaller({ rawRequest: req }, body);
    callerId = caller.id;
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
    logImageGenerationFailure('generateImageHttp', callerId, error);
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
  mode = null,
  storyOptions = STORY_OPTION_DEFAULTS,
  preview = null,
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
  const storyJsonRequest = isStoryJsonRequest({ jsonOutput, responseSchema });
  const modeInfo = storyJsonRequest
    ? mode || STORY_MODES[DEFAULT_STORY_MODE_KEY]
    : null;
  const basePrompt = storyJsonRequest
    ? buildStoryPrompt({
        prompt,
        mode: modeInfo,
        storyOptions,
        preview,
      })
    : prompt;
  let currentPrompt = basePrompt;
  let qualityRepairUsed = false;

  for (let attempt = 1; attempt <= STORY_GENERATION_MAX_ATTEMPTS; attempt += 1) {
    let text;
    try {
      text = await callGeminiText({
        prompt: currentPrompt,
        systemPrompt: safeSystemPrompt,
        apiKey: readEnv('GEMINI_API_KEY'),
        jsonOutput,
        responseSchema,
        normalizeStoryJson: storyJsonRequest,
        storyPageCount: modeInfo?.pageCount,
        maxOutputTokens: storyJsonRequest
          ? maxStoryOutputTokens(modeInfo.pageCount)
          : undefined,
      });
    } catch (error) {
      if (!storyJsonRequest || attempt >= STORY_GENERATION_MAX_ATTEMPTS) {
        throw error;
      }
      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'story',
        stage: 'response',
        allowed: false,
        reason: 'invalid_story_json',
        prompt: currentPrompt,
        output: error instanceof Error ? error.message : String(error),
        metadata: { attempt, jsonOutput },
      });
      continue;
    }

    const responseCategory = findUnsafeCategory(text);
    if (!responseCategory) {
      if (storyJsonRequest) {
        const story = parseGeneratedStoryJson(text, {
          pageCount: modeInfo.pageCount,
        });
        const qualityIssues = validateGeneratedStoryQuality(story, {
          pageCount: modeInfo.pageCount,
        });
        if (qualityIssues.length > 0) {
          await writeSafetyAuditLog({
            uid: callerId,
            feature: 'story',
            stage: 'response',
            allowed: false,
            reason: 'story_quality',
            prompt: currentPrompt,
            output: text,
            metadata: {
              attempt,
              jsonOutput,
              qualityIssues: qualityIssues.map((issue) => issue.code),
            },
          });

          if (!qualityRepairUsed) {
            qualityRepairUsed = true;
            currentPrompt = buildStoryRepairPrompt({
              prompt: basePrompt,
              story,
              issues: qualityIssues,
              mode: modeInfo,
            });
            continue;
          }

          throw createStoryQualityError(qualityIssues);
        }
      }

      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'story',
        stage: 'response',
        allowed: true,
        prompt: currentPrompt,
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
      prompt: currentPrompt,
      output: text,
      metadata: { attempt, jsonOutput },
    });
  }

  throw createChildSafeError();
}

async function generateSafeStoryPreview({
  callerId,
  chatLogs,
  summaryMainSettings,
  mode,
  storyOptions,
}) {
  await enforceRateLimit(callerId, STORY_PREVIEW_RATE_LIMIT);
  const basePrompt = buildStoryPreviewPrompt({
    chatLogs,
    summaryMainSettings,
    mode,
    storyOptions,
  });
  const blockedCategory = findUnsafeCategory(basePrompt);
  if (blockedCategory) {
    await writeSafetyAuditLog({
      uid: callerId,
      feature: 'storyPreview',
      stage: 'prompt',
      allowed: false,
      reason: blockedCategory,
      prompt: basePrompt,
    });
    throw createChildSafeError();
  }

  const safeSystemPrompt = [
    CHILD_SAFE_STORY_PREFIX,
    'Return only valid JSON for a Japanese children story preview.',
  ].join('\n\n');

  let currentPrompt = basePrompt;
  for (let attempt = 1; attempt <= STORY_PREVIEW_MAX_ATTEMPTS; attempt += 1) {
    let text;
    try {
      text = await callGeminiText({
        prompt: currentPrompt,
        systemPrompt: safeSystemPrompt,
        apiKey: readEnv('GEMINI_API_KEY'),
        jsonOutput: true,
        responseSchema: buildStoryPreviewResponseSchema(mode),
        maxOutputTokens: 2048,
      });
    } catch (error) {
      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'storyPreview',
        stage: 'response',
        allowed: false,
        reason: 'invalid_story_preview_json',
        prompt: currentPrompt,
        output: error instanceof Error ? error.message : String(error),
        metadata: { attempt },
      });
      if (attempt >= STORY_PREVIEW_MAX_ATTEMPTS) {
        throw error;
      }
      currentPrompt = buildStoryPreviewRepairPrompt({
        prompt: basePrompt,
        mode,
        issues: [{
          message: 'JSON形式または必須項目が不正です。',
        }],
        previousOutput: error instanceof Error ? error.message : String(error),
      });
      continue;
    }

    let preview;
    try {
      preview = parseGeneratedStoryPreviewJson(text, {
        pageCount: mode.pageCount,
      });
    } catch (error) {
      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'storyPreview',
        stage: 'response',
        allowed: false,
        reason: 'invalid_story_preview_json',
        prompt: currentPrompt,
        output: text,
        metadata: { attempt },
      });
      if (attempt >= STORY_PREVIEW_MAX_ATTEMPTS) {
        throw error;
      }
      currentPrompt = buildStoryPreviewRepairPrompt({
        prompt: basePrompt,
        mode,
        issues: [{
          message: error instanceof Error ? error.message : String(error),
        }],
        previousOutput: text,
      });
      continue;
    }

    const responseCategory = findUnsafeCategory(JSON.stringify(preview));
    if (responseCategory) {
      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'storyPreview',
        stage: 'response',
        allowed: false,
        reason: responseCategory,
        prompt: currentPrompt,
        output: text,
        metadata: { attempt },
      });
      throw createChildSafeError();
    }

    const qualityIssues = validateStoryPreviewQuality(preview, {
      pageCount: mode.pageCount,
    });
    if (qualityIssues.length > 0) {
      await writeSafetyAuditLog({
        uid: callerId,
        feature: 'storyPreview',
        stage: 'response',
        allowed: false,
        reason: 'story_preview_quality',
        prompt: currentPrompt,
        output: text,
        metadata: {
          attempt,
          qualityIssues: qualityIssues.map((issue) => issue.code),
        },
      });

      if (attempt >= STORY_PREVIEW_MAX_ATTEMPTS) {
        const fallbackPreview = buildFallbackStoryPreview({
          preview,
          chatLogs,
          summaryMainSettings,
          mode,
          storyOptions,
        });
        await writeSafetyAuditLog({
          uid: callerId,
          feature: 'storyPreview',
          stage: 'response',
          allowed: true,
          prompt: currentPrompt,
          output: JSON.stringify(fallbackPreview),
          metadata: {
            attempt,
            fallback: true,
            qualityIssues: qualityIssues.map((issue) => issue.code),
          },
        });
        return fallbackPreview;
      }
      currentPrompt = buildStoryPreviewRepairPrompt({
        prompt: basePrompt,
        mode,
        issues: qualityIssues,
        previousOutput: text,
      });
      continue;
    }

    await writeSafetyAuditLog({
      uid: callerId,
      feature: 'storyPreview',
      stage: 'response',
      allowed: true,
      prompt: currentPrompt,
      output: text,
      metadata: { attempt },
    });
    return preview;
  }

  throw createChildSafeError();
}

function isStoryJsonRequest({ jsonOutput, responseSchema }) {
  if (jsonOutput !== true || !responseSchema || typeof responseSchema !== 'object') {
    return false;
  }

  const properties = responseSchema.properties;
  return Boolean(
    properties &&
    typeof properties === 'object' &&
    properties.pages &&
    typeof properties.pages === 'object',
  );
}

function rejectClientStoryPricing(data) {
  if (!data || typeof data !== 'object') {
    return;
  }
  if (Object.prototype.hasOwnProperty.call(data, 'pageCount')) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'pageCount はサーバー側で mode から決定します。',
    );
  }
  if (Object.prototype.hasOwnProperty.call(data, 'coinCost')) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'coinCost はサーバー側で mode から決定します。',
    );
  }
}

function resolveStoryMode(value, fallbackKey = DEFAULT_STORY_MODE_KEY) {
  const key = typeof value === 'string' && value.trim()
    ? value.trim()
    : fallbackKey;
  const mode = STORY_MODES[key];
  if (!mode) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `未対応のおはなしモードです: ${key}`,
    );
  }
  return mode;
}

function normalizeStoryOptions(value) {
  const source = value && typeof value === 'object' && !Array.isArray(value)
    ? value
    : {};
  const normalized = { ...STORY_OPTION_DEFAULTS };
  for (const [key, allowedValues] of Object.entries(STORY_OPTION_VALUES)) {
    const rawValue = typeof source[key] === 'string' ? source[key].trim() : '';
    if (!rawValue) {
      continue;
    }
    if (!allowedValues.includes(rawValue)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `storyOptions.${key} が不正です: ${rawValue}`,
      );
    }
    normalized[key] = rawValue;
  }
  return normalized;
}

function formatStoryOptionsForPrompt(storyOptions) {
  return [
    `- 雰囲気: ${STORY_OPTION_LABELS.tone[storyOptions.tone]}`,
    `- 終わり方: ${STORY_OPTION_LABELS.endingStyle[storyOptions.endingStyle]}`,
    `- 世界: ${STORY_OPTION_LABELS.worldType[storyOptions.worldType]}`,
  ].join('\n');
}

function normalizeStoryPreviewInput(preview, mode) {
  const title = typeof preview.title === 'string' ? preview.title.trim() : '';
  const summary =
    typeof preview.summary === 'string' ? preview.summary.trim() : '';
  const pagePlan = Array.isArray(preview.pagePlan)
    ? preview.pagePlan
        .map((entry) => (typeof entry === 'string' ? entry.trim() : ''))
        .filter(Boolean)
    : [];
  if (!title || !summary || pagePlan.length !== mode.pageCount) {
    return null;
  }
  const normalized = { title, summary, pagePlan };
  const qualityIssues = validateStoryPreviewQuality(normalized, {
    pageCount: mode.pageCount,
  });
  if (qualityIssues.length > 0) {
    return null;
  }
  return normalized;
}

function buildStoryResponseSchema(mode) {
  return {
    type: 'object',
    properties: {
      title: { type: 'string' },
      coverScene: { type: 'string' },
      characterSheet: {
        type: 'object',
        properties: {
          protagonist: { type: 'string' },
          companion: { type: 'string' },
          worldDetails: { type: 'string' },
          artDirection: { type: 'string' },
        },
        required: [
          'protagonist',
          'companion',
          'worldDetails',
          'artDirection',
        ],
      },
      pages: {
        type: 'array',
        minItems: mode.pageCount,
        maxItems: mode.pageCount,
        items: {
          type: 'object',
          properties: {
            story: { type: 'string' },
            visualFocus: { type: 'string' },
            mood: { type: 'string' },
            dialogue: { type: 'string' },
            visibleCast: {
              type: 'array',
              minItems: 1,
              maxItems: 2,
              items: {
                type: 'string',
                enum: ['protagonist', 'companion'],
              },
            },
          },
          required: [
            'story',
            'visualFocus',
            'mood',
            'dialogue',
            'visibleCast',
          ],
        },
      },
    },
    required: [
      'title',
      'coverScene',
      'characterSheet',
      'pages',
    ],
  };
}

function buildStoryPreviewResponseSchema(mode) {
  return {
    type: 'object',
    properties: {
      title: {
        type: 'string',
        description: '短い日本語の絵本タイトル案。',
      },
      summary: {
        type: 'string',
        description: '物語全体のあらすじ。1〜2文で具体的に書く。',
      },
      pagePlan: {
        type: 'array',
        description:
          'ページごとの展開案。同じ文型や同じ出来事を繰り返さず、各ページで違う行動・失敗・選択・発見を書く。',
        minItems: mode.pageCount,
        maxItems: mode.pageCount,
        items: {
          type: 'string',
          description:
            '1ページ分の具体的な展開。前後のページと重複しない1文。',
        },
      },
    },
    required: ['title', 'summary', 'pagePlan'],
  };
}

function maxStoryOutputTokens(pageCount) {
  if (pageCount >= 12) {
    return 8192;
  }
  if (pageCount >= 8) {
    return 6144;
  }
  return 4096;
}

function buildStoryPrompt({
  prompt,
  mode = STORY_MODES[DEFAULT_STORY_MODE_KEY],
  storyOptions = STORY_OPTION_DEFAULTS,
  preview = null,
}) {
  const pageBeats = mode.beats
    .map((beat, index) => `${index + 1}. ${beat}`)
    .join('\n');
  const optionText = formatStoryOptionsForPrompt(storyOptions);
  const previewText = preview
    ? [
        `タイトル案: ${preview.title}`,
        `あらすじ: ${preview.summary}`,
        'ページごとの展開案:',
        ...preview.pagePlan.map((beat, index) => `${index + 1}. ${beat}`),
      ].join('\n')
    : 'なし。入力内容から最もよい構成を作る。';

  return `
あなたは3〜8歳向けの日本語絵本作家です。
子どもが「次のページを見たい」と思う、短くてわかりやすく、少し不思議で、最後に小さなオチがある絵本を作ってください。

おはなしモード:
- mode: ${mode.key}
- 表示名: ${mode.displayName}
- ページ数: ${mode.pageCount}ページ
- 必要コイン: ${mode.coinCost}
- 用途: ${mode.usage}

選択された雰囲気:
${optionText}

ユーザーが確認したあらすじプレビュー:
${previewText}

既存アプリから渡された入力と出力スキーマ:
${prompt}

まず内部で3つの Story Plan を作ってください。
Story Plan には次を含めてください。
- 主人公の小さな願い
- 今日だけ起きる変なルール
- 困った事件
- 失敗する作戦
- 意外な気づき
- 解決方法
- 最後の小さな笑えるオチ

次に、3つの Story Plan を以下の観点で内部評価してください。
- 子どもが次を読みたくなるか
- 主人公の願いが明確か
- 2ページ目に失敗や困りごとがあるか
- 3ページ目に意外性があるか
- 4ページ目に小さなオチがあるか
- 怖すぎないか
- 説教くさくないか
- 絵にしやすいか

最も良い Story Plan を1つだけ選び、それをもとに${mode.pageCount}ページの絵本を作ってください。
Story Plan と評価内容は出力しないでください。

各ページの条件:
- ${mode.pageCount}ページ構成にする
${pageBeats}
- 少なくとも1ページに短い会話を入れる
- 各ページに、行動・変化・次を読みたくなる要素を入れる
- 抽象的な説明ではなく、見える・聞こえる・触れる場面を書く
- 1ページあたり60〜120字程度を目安にし、音読しやすくする
- 子どもの入力内容を最低3箇所以上で意味のある形で反映する
- 主人公の性格、好きなもの、仲間、場所が話の解決に関係するようにする
- 「やさしいけど薄い話」にならないよう、失敗・選択・ピンチ・解決を入れる

画像用の場面情報:
- visualFocus には、場所、主人公、仲間、そのページ固有の事件や変化、主人公の表情、絵本らしい安全で明るい雰囲気、9:16縦長に向いた構図を入れる
- coverScene は表紙向けの強い1場面にする
- characterSheet は全ページで同じ人物・動物・服装・色・顔立ちを保てる具体的な設定にする

禁止:
- ただ仲良く遊ぶだけ
- ただ散歩するだけ
- すぐ解決する
- 事件がない
- 失敗がない
- 夢オチ
- 怖すぎる展開
- 悪者を罰するだけの結末
- 教訓を直接説明する
- 「みんなで楽しく過ごしました」で終わる
- 「みんな幸せに暮らしました」で終わる
- 「大切なことを学びました」で終わる
- 「勇気」「友情」「思いやり」などの言葉で説教する

出力:
既存コードが期待しているJSON形式だけを返してください。
Markdown、説明文、前置き、コードブロックは出力しないでください。
JSON以外の文字を含めないでください。
`.trim();
}

function buildStoryRepairPrompt({
  prompt,
  story,
  issues,
  mode = STORY_MODES[DEFAULT_STORY_MODE_KEY],
}) {
  const issueText = issues
    .map((issue) => `- ${issue.message}`)
    .join('\n');

  return `
${prompt}

前回のJSONは内部品質チェックを通過しませんでした。
検出された問題:
${issueText}

前回のJSON:
${JSON.stringify(story)}

同じ既存JSON形式だけで、${mode.pageCount}ページの本文と visualFocus を修正してください。
Story Plan、評価内容、説明文、Markdown、コードブロックは出力しないでください。
`.trim();
}

function buildStoryPreviewPrompt({
  chatLogs,
  summaryMainSettings,
  mode,
  storyOptions,
}) {
  const pageBeats = mode.beats
    .map((beat, index) => `${index + 1}. ${beat}`)
    .join('\n');

  return `
あなたは3〜8歳向けの日本語絵本編集者です。
画像は作らず、保護者と子どもが確認できる「あらすじプレビュー」だけを作ってください。

おはなしモード:
- mode: ${mode.key}
- 表示名: ${mode.displayName}
- ページ数: ${mode.pageCount}ページ
- 必要コイン: ${mode.coinCost}
- 用途: ${mode.usage}

選択された雰囲気:
${formatStoryOptionsForPrompt(storyOptions)}

会話ログ:
${chatLogs}

収集済みの設定メモ:
${summaryMainSettings || 'なし'}

ページ構成:
${pageBeats}

要件:
- 日本語で出力する
- title は短く、絵本の題名らしくする
- summary は1〜2文で、何が起きるおはなしなのか分かるようにする
- pagePlan は必ず${mode.pageCount}件にする
- 各 pagePlan は1文で、そのページの展開を具体的に書く
- ページ構成の各番号を必ず反映し、同じ出来事・同じ文型・同じ言い回しを2ページ以上で繰り返さない
- 「ふしぎな出来事が広がり、一歩ずつ進む」のような抽象文を埋め草にしない
- 各ページでは、場所、行動、失敗、発見、選択、結果のいずれかが前ページから明確に変わるようにする
- standard/premium では、失敗、ピンチ、主人公の選択、クライマックスが別ページとして分かるようにする
- 子どもの入力内容を最低3箇所以上で意味のある形で反映する
- 主人公の性格、好きなもの、仲間、場所が解決に関係するようにする
- 説教臭い教訓や「みんなで楽しく過ごしました」のような薄い結末にしない
- 怖すぎる展開、危険、個人情報、外部連絡、夢オチは使わない

出力:
JSONだけを返してください。Markdown、説明、コードブロックは出力しないでください。
`.trim();
}

function buildStoryPreviewRepairPrompt({
  prompt,
  mode,
  issues,
  previousOutput,
}) {
  const issueText = issues
    .map((issue) => `- ${issue.message}`)
    .join('\n');

  return `
${prompt}

前回のあらすじプレビューは内部品質チェックを通過しませんでした。
検出された問題:
${issueText}

前回の出力:
${previousOutput}

同じJSON形式だけで作り直してください。
特に pagePlan は${mode.pageCount}件すべてを、ページ構成に沿った別々の出来事として書いてください。
2ページ以上で同じ文、同じ文型、同じ抽象表現を繰り返さないでください。
Markdown、説明、コードブロックは出力しないでください。
`.trim();
}

function buildFallbackStoryPreview({
  preview,
  chatLogs,
  summaryMainSettings,
  mode,
  storyOptions,
}) {
  const seeds = extractStoryPreviewSeeds({
    chatLogs,
    summaryMainSettings,
    storyOptions,
  });
  const pagePlan = buildFallbackPreviewPagePlan({ mode, seeds });
  const title = preview.title || `${seeds.protagonist}と${seeds.place}`;
  const summary =
    preview.summary ||
    `${seeds.protagonist}が${seeds.place}で${seeds.companion}と出会い、` +
      `${seeds.strength}を使って小さな問題を解決するおはなしです。`;

  return {
    title,
    summary,
    pagePlan,
  };
}

function extractStoryPreviewSeeds({
  chatLogs,
  summaryMainSettings,
  storyOptions,
}) {
  const source = [summaryMainSettings, chatLogs].filter(Boolean).join('\n');
  const worldLabel = STORY_OPTION_LABELS.worldType[storyOptions.worldType];
  const toneLabel = STORY_OPTION_LABELS.tone[storyOptions.tone];
  return {
    protagonist:
      readPreviewSetting(source, 'このおはなしの主人公') ||
      readPreviewSetting(source, '主人公') ||
      '主人公',
    place:
      readPreviewSetting(source, 'このおはなしの場所') ||
      readPreviewSetting(source, '場所') ||
      (storyOptions.worldType === 'custom' ? 'ふしぎな場所' : worldLabel),
    companion:
      readPreviewSetting(source, 'このおはなしの仲間') ||
      readPreviewSetting(source, '仲間') ||
      'なかま',
    strength:
      readPreviewSetting(source, '仲間のせつめい') ||
      `${toneLabel}気持ち`,
    wish:
      readPreviewSetting(source, 'どんなおはなし') ||
      readPreviewSetting(source, '願い') ||
      '小さな願い',
  };
}

function readPreviewSetting(source, label) {
  const escapedLabel = label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const match = String(source ?? '').match(
    new RegExp(`${escapedLabel}\\s*[:：]\\s*([^\\n\\r]+)`),
  );
  if (!match) {
    return '';
  }
  return sanitizePreviewSeed(match[1]);
}

function sanitizePreviewSeed(value) {
  return String(value ?? '')
    .replace(/[。.!！?？]+$/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 30);
}

function buildFallbackPreviewPagePlan({ mode, seeds }) {
  const plans = {
    mini: [
      `${seeds.protagonist}が${seeds.place}で${seeds.wish}を見つける。`,
      `${seeds.companion}が現れ、ふたりで最初の手がかりを試す。`,
      `${seeds.strength}を活かして困りごとの原因に気づく。`,
      `解決したあと、${seeds.protagonist}が小さなごほうびを持って帰る。`,
    ],
    standard: [
      `${seeds.protagonist}が${seeds.place}で${seeds.wish}に気づく。`,
      `${seeds.companion}が助けを求め、ふしぎな道がひらく。`,
      `ふたりは光る目印を追って、いつもと違う場所へ進む。`,
      `${seeds.protagonist}が急ぎすぎて手がかりを見失う。`,
      `${seeds.strength}を思い出し、別のやり方で手がかりを探す。`,
      `大きな障害が道をふさぎ、ふたりは進むか戻るかを選ぶ。`,
      `${seeds.protagonist}と${seeds.companion}が力を合わせ、問題の中心を解く。`,
      `${seeds.place}に静けさが戻り、ふたりは笑える小さなごほうびを受け取る。`,
    ],
    premium: [
      `${seeds.protagonist}が${seeds.place}でいつもの時間を過ごしている。`,
      `${seeds.wish}がかなわず、少しだけ困った気持ちになる。`,
      `足もとにふしぎな印が現れ、遠くから小さな音が聞こえる。`,
      `${seeds.protagonist}は音を追って、知らない道へ一歩ふみ出す。`,
      `${seeds.companion}が現れ、道具や合図の使い方を教える。`,
      `最初の門で失敗し、ふたりは別の入り口を探す。`,
      `${seeds.strength}が役に立ち、小さな通り道を見つける。`,
      `奥でさらに大きな問題が起き、${seeds.place}全体がざわつく。`,
      `${seeds.protagonist}は自分だけ進むか、${seeds.companion}を待つかを選ぶ。`,
      `選んだ行動が道を変え、いちばん大きなピンチに向き合う。`,
      `ふたりの工夫で問題がほどけ、なくしたものが戻ってくる。`,
      `${seeds.protagonist}は安心して帰り、眠る前に今日の冒険を思い出す。`,
    ],
  };
  return plans[mode.key].slice(0, mode.pageCount);
}

function stringifyGeneratedStoryJson(
  rawText,
  { pageCount = STORY_BODY_PAGE_COUNT } = {},
) {
  return JSON.stringify(parseGeneratedStoryJson(rawText, { pageCount }));
}

function parseGeneratedStoryPreviewJson(
  rawText,
  { pageCount } = {},
) {
  const parsed = parseJsonObjectText(rawText);
  const title = requirePreviewStringField(parsed, 'title');
  const summary = requirePreviewStringField(parsed, 'summary');
  const pagePlan = parsed.pagePlan;
  if (!Array.isArray(pagePlan) || pagePlan.length !== pageCount) {
    throw createStoryJsonError(
      `Story preview must contain exactly ${pageCount} pagePlan items.`,
    );
  }
  return {
    title,
    summary,
    pagePlan: pagePlan.map((entry, index) => {
      if (typeof entry !== 'string' || entry.trim().length === 0) {
        throw createStoryJsonError(
          `Story preview pagePlan ${index + 1} must be a string.`,
        );
      }
      return entry.replace(/\s+/g, ' ').trim();
    }),
  };
}

function validateStoryPreviewQuality(
  preview,
  { pageCount } = {},
) {
  const issues = [];
  const pagePlan = Array.isArray(preview?.pagePlan) ? preview.pagePlan : [];
  if (pagePlan.length !== pageCount) {
    issues.push({
      code: 'page_plan_count',
      message: `pagePlan は${pageCount}件である必要があります。`,
    });
    return issues;
  }

  const normalizedPlans = pagePlan.map(normalizeForComparison);
  const seen = new Map();
  for (let index = 0; index < normalizedPlans.length; index += 1) {
    const normalized = normalizedPlans[index];
    if (!normalized) {
      issues.push({
        code: 'empty_page_plan',
        message: `${index + 1}ページ目の展開案が空です。`,
      });
      continue;
    }
    if (seen.has(normalized)) {
      issues.push({
        code: 'duplicate_page_plan',
        message:
          `${seen.get(normalized) + 1}ページ目と${index + 1}ページ目の展開案が同じです。`,
      });
      break;
    }
    seen.set(normalized, index);
  }

  const repeatedSimilarPairs = [];
  for (let first = 0; first < normalizedPlans.length; first += 1) {
    for (let second = first + 1; second < normalizedPlans.length; second += 1) {
      if (
        normalizedPlans[first] &&
        normalizedPlans[second] &&
        similarityScore(normalizedPlans[first], normalizedPlans[second]) >= 0.88
      ) {
        repeatedSimilarPairs.push([first, second]);
      }
    }
  }
  if (repeatedSimilarPairs.length >= Math.max(2, Math.floor(pageCount / 3))) {
    issues.push({
      code: 'repetitive_page_plan',
      message: '複数ページの展開案が似すぎています。',
    });
  }

  const repeatedGenericFragment = GENERIC_PREVIEW_PLAN_FRAGMENTS.find(
    (fragment) =>
      pagePlan.filter((entry) => entry.includes(fragment)).length >= 2,
  );
  if (repeatedGenericFragment) {
    issues.push({
      code: 'generic_page_plan',
      message:
        `「${repeatedGenericFragment}」のような抽象表現を複数ページで繰り返しています。`,
    });
  }

  const uniqueCount = new Set(normalizedPlans.filter(Boolean)).size;
  if (uniqueCount < Math.ceil(pageCount * 0.75)) {
    issues.push({
      code: 'low_page_plan_variety',
      message: 'ページごとの出来事の種類が少なすぎます。',
    });
  }

  return issues;
}

function requirePreviewStringField(source, fieldName) {
  const value = source?.[fieldName];
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw createStoryJsonError(`Story preview is missing ${fieldName}.`);
  }
  return value.replace(/\s+/g, ' ').trim();
}

function parseGeneratedStoryJson(
  rawText,
  { pageCount = STORY_BODY_PAGE_COUNT } = {},
) {
  const parsed = parseJsonObjectText(rawText);
  return normalizeGeneratedStory(parsed, { pageCount });
}

function parseJsonObjectText(rawText) {
  const source = typeof rawText === 'string' ? rawText.trim() : '';
  const withoutFence = source
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();
  const start = withoutFence.indexOf('{');
  const end = withoutFence.lastIndexOf('}');
  if (start < 0 || end < start) {
    throw createStoryJsonError('Story generation returned no JSON object.');
  }

  const jsonText = withoutFence.slice(start, end + 1);
  try {
    const parsed = JSON.parse(jsonText);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error('Root JSON value must be an object.');
    }
    return parsed;
  } catch (error) {
    throw createStoryJsonError(
      error instanceof Error ? error.message : String(error),
    );
  }
}

function normalizeGeneratedStory(
  story,
  { pageCount = STORY_BODY_PAGE_COUNT } = {},
) {
  const title = requireStoryStringField(story, 'title');
  const coverScene = requireStoryStringField(story, 'coverScene');
  const characterSheet = story.characterSheet;
  if (
    !characterSheet ||
    typeof characterSheet !== 'object' ||
    Array.isArray(characterSheet)
  ) {
    throw createStoryJsonError('Story JSON is missing characterSheet.');
  }

  const pages = story.pages;
  if (!Array.isArray(pages) || pages.length !== pageCount) {
    throw createStoryJsonError(
      `Story JSON must contain exactly ${pageCount} pages.`,
    );
  }

  return {
    title,
    coverScene,
    characterSheet: Object.fromEntries(
      STORY_REQUIRED_CHARACTER_FIELDS.map((field) => [
        field,
        requireStoryStringField(characterSheet, `characterSheet.${field}`),
      ]),
    ),
    pages: pages.map((page, index) => normalizeGeneratedStoryPage(page, index)),
  };
}

function normalizeGeneratedStoryPage(page, index) {
  if (!page || typeof page !== 'object' || Array.isArray(page)) {
    throw createStoryJsonError(`Story page ${index + 1} must be an object.`);
  }

  const normalizedPage = Object.fromEntries(
    STORY_REQUIRED_PAGE_FIELDS.filter((field) => field !== 'visibleCast').map(
      (field) => [
        field,
        requireStoryStringField(page, `pages.${index}.${field}`, {
          allowEmpty: field !== 'story',
        }),
      ],
    ),
  );
  if (!Array.isArray(page.visibleCast) || page.visibleCast.length === 0) {
    throw createStoryJsonError(`Story page ${index + 1} is missing visibleCast.`);
  }
  normalizedPage.visibleCast = page.visibleCast
    .filter((entry) => typeof entry === 'string')
    .map((entry) => entry.trim())
    .filter(Boolean);
  if (normalizedPage.visibleCast.length === 0) {
    throw createStoryJsonError(`Story page ${index + 1} has invalid visibleCast.`);
  }
  return normalizedPage;
}

function requireStoryStringField(source, fieldName, { allowEmpty = false } = {}) {
  const fieldKey = fieldName.split('.').pop();
  const value = source?.[fieldKey];
  if (typeof value !== 'string' || (!allowEmpty && value.trim().length === 0)) {
    throw createStoryJsonError(`Story JSON is missing ${fieldName}.`);
  }
  return value.replace(/\s+/g, ' ').trim();
}

function validateGeneratedStoryQuality(
  story,
  { pageCount = STORY_BODY_PAGE_COUNT } = {},
) {
  const issues = [];
  const pages = Array.isArray(story?.pages) ? story.pages : [];
  if (pages.length !== pageCount) {
    issues.push({
      code: 'page_count',
      message: `pages は${pageCount}ページである必要があります。`,
    });
  }

  const emptyPage = pages.findIndex(
    (page) => typeof page?.story !== 'string' || page.story.trim().length === 0,
  );
  if (emptyPage >= 0) {
    issues.push({
      code: 'empty_story',
      message: `${emptyPage + 1}ページ目の本文が空です。`,
    });
  }

  const finalStory = pages[pageCount - 1]?.story ?? '';
  if (hasBannedStoryEnding(finalStory)) {
    issues.push({
      code: 'banned_ending',
      message: '最終ページが平板な禁止エンディングで終わっています。',
    });
  }

  if (!hasAnyDialogue(pages)) {
    issues.push({
      code: 'missing_dialogue',
      message: '少なくとも1ページに短い会話を入れてください。',
    });
  }

  if (
    hasHighlySimilarStrings(pages.map((page) => page?.story ?? ''), {
      minCount: pageCount,
    })
  ) {
    issues.push({
      code: 'repetitive_story',
      message: '全ページの本文が似すぎています。',
    });
  }

  const visualFocusValues = pages
    .map((page) => (typeof page?.visualFocus === 'string' ? page.visualFocus : ''))
    .filter((value) => value.trim().length > 0);
  if (
    visualFocusValues.length === pageCount &&
    hasHighlySimilarStrings(visualFocusValues, { minCount: pageCount })
  ) {
    issues.push({
      code: 'repetitive_visual_focus',
      message: '各ページの画像説明が単調です。',
    });
  }

  return issues;
}

function hasAnyDialogue(pages) {
  return pages.some((page) => {
    const dialogue = typeof page?.dialogue === 'string' ? page.dialogue.trim() : '';
    const story = typeof page?.story === 'string' ? page.story.trim() : '';
    return (
      dialogue.length > 0 ||
      /[「『][^」』]{1,40}[」』]/.test(story) ||
      /"[^"]{1,40}"/.test(story)
    );
  });
}

function hasBannedStoryEnding(story) {
  const normalizedStory = normalizeForComparison(story);
  return BANNED_STORY_ENDINGS.some((ending) =>
    normalizedStory.endsWith(normalizeForComparison(ending)),
  );
}

function hasHighlySimilarStrings(
  values,
  { minCount = STORY_BODY_PAGE_COUNT } = {},
) {
  const normalizedValues = values
    .map(normalizeForComparison)
    .filter((value) => value.length > 0);
  if (normalizedValues.length < minCount) {
    return false;
  }

  if (new Set(normalizedValues).size <= 1) {
    return true;
  }

  for (let i = 0; i < normalizedValues.length; i += 1) {
    for (let j = i + 1; j < normalizedValues.length; j += 1) {
      if (similarityScore(normalizedValues[i], normalizedValues[j]) < 0.9) {
        return false;
      }
    }
  }
  return true;
}

function similarityScore(first, second) {
  const firstShingles = toShingles(first);
  const secondShingles = toShingles(second);
  if (firstShingles.size === 0 || secondShingles.size === 0) {
    return 0;
  }

  let intersection = 0;
  for (const shingle of firstShingles) {
    if (secondShingles.has(shingle)) {
      intersection += 1;
    }
  }

  return intersection / new Set([...firstShingles, ...secondShingles]).size;
}

function toShingles(value) {
  const size = 3;
  if (value.length <= size) {
    return new Set(value ? [value] : []);
  }

  const shingles = new Set();
  for (let index = 0; index <= value.length - size; index += 1) {
    shingles.add(value.slice(index, index + size));
  }
  return shingles;
}

function normalizeForComparison(value) {
  return String(value ?? '')
    .toLowerCase()
    .replace(/[\s。、，,.!?！？「」『』"'｀・ー〜~…]/g, '')
    .trim();
}

function createStoryJsonError(message) {
  return new functions.https.HttpsError(
    'internal',
    `Generated story JSON is invalid: ${message}`,
  );
}

function createStoryQualityError(issues) {
  return new functions.https.HttpsError(
    'internal',
    `Generated story did not pass quality checks: ${issues
      .map((issue) => issue.code)
      .join(', ')}`,
  );
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

  const result = await callOpenAiImage({
    prompt: [CHILD_SAFE_IMAGE_PREFIX, prompt].join('\n\n'),
    negativePrompt: [negativePrompt, UNSAFE_VISUAL_NEGATIVE_PROMPT]
      .filter(Boolean)
      .join(', '),
    apiKey: readEnv('OPENAI_API_KEY'),
    seed,
  });

  const response = {
    seed: result.seed,
    model: result.model,
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
    response.base64 = result.imageBuffer.toString('base64');
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
      model: result.model,
    },
  });

  return response;
}

function logImageGenerationFailure(functionName, callerId, error) {
  const code =
    error instanceof functions.https.HttpsError ? error.code : 'internal';
  const message = error instanceof Error ? error.message : String(error);
  functions.logger.warn('Image generation failed.', {
    functionName,
    callerId,
    code,
    message,
  });
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
  normalizeStoryJson = false,
  storyPageCount = STORY_BODY_PAGE_COUNT,
  maxOutputTokens,
}) {
  const model = jsonOutput ? 'gemini-2.5-flash' : 'gemini-2.5-flash-lite';
  const outputTokenLimit =
    Number.isInteger(maxOutputTokens) && maxOutputTokens > 0
      ? maxOutputTokens
      : jsonOutput
          ? 4096
          : 256;
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
          maxOutputTokens: outputTokenLimit,
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
  if (normalizeStoryJson) {
    return stringifyGeneratedStoryJson(text, { pageCount: storyPageCount });
  }
  return text;
}

async function callOpenAiImage({ prompt, negativePrompt, apiKey, seed }) {
  const safePrompt = sanitizeOpenAiImagePrompt(prompt);
  const safeNegativePrompt = sanitizeOpenAiImagePrompt(negativePrompt);
  const mergedPrompt = [
    safePrompt.trim(),
    safeNegativePrompt.trim()
      ? `Avoid the following elements: ${safeNegativePrompt.trim()}`
      : '',
  ]
    .filter(Boolean)
    .join('\n\n');

  const payload = await postJson('https://api.openai.com/v1/images/generations', {
    headers: {
      Authorization: `Bearer ${apiKey}`,
    },
    body: buildOpenAiImageRequest(mergedPrompt),
  });

  const images = Array.isArray(payload.data) ? payload.data : [];
  const base64 = images.find(
    (image) => typeof image?.b64_json === 'string' && image.b64_json.trim(),
  )?.b64_json;
  if (typeof base64 === 'string' && base64.trim().length > 0) {
    const normalizedBuffer = await normalizeGeneratedImage(base64.trim());
    return {
      imageBuffer: normalizedBuffer,
      seed: seed || Date.now(),
      model: OPENAI_IMAGE_MODEL,
    };
  }

  throw new functions.https.HttpsError(
    'internal',
    '画像生成の結果を取得できませんでした。',
  );
}

function sanitizeOpenAiImagePrompt(value) {
  if (typeof value !== 'string') {
    return '';
  }
  return value
    .replace(/\bchildren'?s?\s+picture-book\b/gi, 'family picture-book')
    .replace(/\bchildren'?s?\s+story\b/gi, 'family picture-book story')
    .replace(/\byoung audience\b/gi, 'family audience')
    .replace(/\bdifferent age,?\s*/gi, '')
    .replace(/\badult themes?\b/gi, 'unfriendly themes')
    .replace(/\s+/g, ' ')
    .trim();
}

function buildOpenAiImageRequest(prompt) {
  return {
    model: OPENAI_IMAGE_MODEL,
    prompt,
    size: OPENAI_IMAGE_SIZE,
    quality: OPENAI_IMAGE_QUALITY,
    output_format: OPENAI_IMAGE_OUTPUT_FORMAT,
    output_compression: OPENAI_IMAGE_OUTPUT_COMPRESSION,
    background: 'opaque',
  };
}

async function normalizeGeneratedImage(base64Data) {
  const inputBuffer = Buffer.from(base64Data, 'base64');
  const outputBuffer = await sharp(inputBuffer)
    .rotate()
    .resize({
      width: 1080,
      height: 1920,
      fit: 'cover',
      position: 'center',
      background: {
        r: 247,
        g: 240,
        b: 232,
        alpha: 1,
      },
    })
    .jpeg({
      quality: IMAGE_OUTPUT_JPEG_QUALITY,
      mozjpeg: true,
      chromaSubsampling: '4:4:4',
    })
    .toBuffer();

  functions.logger.info('Normalized generated image.', {
    inputBytes: inputBuffer.length,
    outputBytes: outputBuffer.length,
    jpegQuality: IMAGE_OUTPUT_JPEG_QUALITY,
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

async function getStoryCreationStatusForUid(uid, now = new Date()) {
  const userRef = db.collection('users').doc(uid);
  const usageMonthKey = storyUsageMonthKey(now);
  const [userSnapshot, usageSnapshot] = await Promise.all([
    userRef.get(),
    userRef.collection('subscriptionUsage').doc(usageMonthKey).get(),
  ]);
  const userData = userSnapshot.data() || {};
  const usageData = usageSnapshot.data() || {};
  const isSubscriptionActive = isSilverSubscriptionActive(userData, now);
  const storyCreditsUsed = Math.max(
    0,
    Number(usageData.storyCreditsUsed ?? 0),
  );
  const storyCreditsRemaining = isSubscriptionActive
    ? Math.max(0, SILVER_MONTHLY_STORY_CREDITS - storyCreditsUsed)
    : 0;
  return {
    coins: Math.max(0, Number(userData.coins ?? 0)),
    isSubscriptionActive,
    subscriptionEndAt: normalizeTimestampMillis(
      userData.silverSubscription?.endAt,
    ),
    usageMonthKey,
    monthlyStoryCredits: SILVER_MONTHLY_STORY_CREDITS,
    storyCreditsUsed,
    storyCreditsRemaining,
  };
}

async function reserveStoryGenerationForUid({ uid, mode, requestId }) {
  const userRef = db.collection('users').doc(uid);
  const requestRef = userRef.collection('generationRequests').doc(requestId);
  const now = new Date();
  const usageMonthKey = storyUsageMonthKey(now);
  const usageRef = userRef.collection('subscriptionUsage').doc(usageMonthKey);

  return db.runTransaction(async (transaction) => {
    const existingRequest = await transaction.get(requestRef);
    if (existingRequest.exists) {
      const data = existingRequest.data() || {};
      if (data.uid !== uid || data.mode !== mode.key) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          '同じ requestId が別の生成内容で使われています。',
        );
      }
      if (data.status === 'canceled') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'キャンセル済みの生成 requestId です。',
        );
      }
      return storyReservationResponse({
        requestId,
        request: data,
        idempotent: true,
      });
    }

    const [userSnapshot, usageSnapshot] = await Promise.all([
      transaction.get(userRef),
      transaction.get(usageRef),
    ]);
    const userData = userSnapshot.data() || {};
    const usageData = usageSnapshot.data() || {};
    const decision = evaluateStoryGenerationReservation({
      userData,
      usageData,
      mode,
      now,
    });
    if (!decision.canReserve) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'このおはなしを作るためのSilver枠またはコインが足りません。',
      );
    }

    const requestData = {
      uid,
      requestId,
      mode: mode.key,
      pageCount: mode.pageCount,
      coinCost: mode.coinCost,
      paymentSource: decision.paymentSource,
      usageMonthKey,
      status: 'reserved',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (decision.paymentSource === 'silver') {
      transaction.set(
        usageRef,
        {
          storyCreditsUsed: decision.storyCreditsUsedAfter,
          storiesCreated: decision.storiesCreatedAfter,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else if (decision.paymentSource === 'coins') {
      transaction.set(
        userRef,
        {
          coins: decision.coinsAfter,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    transaction.set(requestRef, requestData);
    return storyReservationResponse({
      requestId,
      request: requestData,
      idempotent: false,
      decision,
    });
  });
}

async function completeStoryGenerationForUid({ uid, requestId }) {
  const requestRef = db
    .collection('users')
    .doc(uid)
    .collection('generationRequests')
    .doc(requestId);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(requestRef);
    if (!snapshot.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        '生成予約が見つかりません。',
      );
    }
    const data = snapshot.data() || {};
    if (data.uid !== uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        '生成予約の所有者が一致しません。',
      );
    }
    if (data.status === 'completed') {
      return storyReservationResponse({ requestId, request: data, idempotent: true });
    }
    if (data.status === 'canceled') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'キャンセル済みの生成予約です。',
      );
    }
    transaction.update(requestRef, {
      status: 'completed',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return storyReservationResponse({
      requestId,
      request: { ...data, status: 'completed' },
      idempotent: false,
    });
  });
}

async function cancelStoryGenerationForUid({ uid, requestId, reason }) {
  const userRef = db.collection('users').doc(uid);
  const requestRef = userRef.collection('generationRequests').doc(requestId);
  return db.runTransaction(async (transaction) => {
    const requestSnapshot = await transaction.get(requestRef);
    if (!requestSnapshot.exists) {
      return { requestId, status: 'missing', refunded: false };
    }
    const request = requestSnapshot.data() || {};
    if (request.uid !== uid) {
      throw new functions.https.HttpsError(
        'permission-denied',
        '生成予約の所有者が一致しません。',
      );
    }
    if (request.status === 'canceled') {
      return storyReservationResponse({ requestId, request, idempotent: true });
    }
    if (request.status === 'completed') {
      return storyReservationResponse({
        requestId,
        request,
        idempotent: true,
        refunded: false,
      });
    }

    const userSnapshot = await transaction.get(userRef);
    const userData = userSnapshot.data() || {};
    let usageRef = null;
    let usageData = {};
    if (request.paymentSource === 'silver') {
      usageRef = userRef
        .collection('subscriptionUsage')
        .doc(request.usageMonthKey);
      const usageSnapshot = await transaction.get(usageRef);
      usageData = usageSnapshot.data() || {};
    }

    const refund = evaluateStoryGenerationRefund({
      request,
      userData,
      usageData,
    });
    if (refund.paymentSource === 'silver' && usageRef) {
      transaction.set(
        usageRef,
        {
          storyCreditsUsed: refund.storyCreditsUsedAfter,
          storiesCreated: refund.storiesCreatedAfter,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else if (refund.paymentSource === 'coins') {
      transaction.set(
        userRef,
        {
          coins: refund.coinsAfter,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

    transaction.update(requestRef, {
      status: 'canceled',
      cancelReason: reason,
      canceledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return storyReservationResponse({
      requestId,
      request: { ...request, status: 'canceled' },
      idempotent: false,
      refunded: refund.refunded,
    });
  });
}

function evaluateStoryGenerationReservation({
  userData,
  usageData,
  mode,
  now = new Date(),
}) {
  const coins = Math.max(0, Number(userData?.coins ?? 0));
  const storyCreditsUsed = Math.max(
    0,
    Number(usageData?.storyCreditsUsed ?? 0),
  );
  const storiesCreated = Math.max(0, Number(usageData?.storiesCreated ?? 0));
  if (
    isSilverSubscriptionActive(userData, now) &&
    storyCreditsUsed + mode.coinCost <= SILVER_MONTHLY_STORY_CREDITS
  ) {
    return {
      canReserve: true,
      paymentSource: 'silver',
      coinCost: mode.coinCost,
      coinsAfter: coins,
      storyCreditsUsedAfter: storyCreditsUsed + mode.coinCost,
      storiesCreatedAfter: storiesCreated + 1,
      storyCreditsRemainingAfter:
        SILVER_MONTHLY_STORY_CREDITS - storyCreditsUsed - mode.coinCost,
    };
  }
  if (coins >= mode.coinCost) {
    return {
      canReserve: true,
      paymentSource: 'coins',
      coinCost: mode.coinCost,
      coinsAfter: coins - mode.coinCost,
      storyCreditsUsedAfter: storyCreditsUsed,
      storiesCreatedAfter: storiesCreated,
      storyCreditsRemainingAfter: Math.max(
        0,
        SILVER_MONTHLY_STORY_CREDITS - storyCreditsUsed,
      ),
    };
  }
  return {
    canReserve: false,
    paymentSource: 'none',
    coinCost: mode.coinCost,
    coinsAfter: coins,
    storyCreditsUsedAfter: storyCreditsUsed,
    storiesCreatedAfter: storiesCreated,
    storyCreditsRemainingAfter: Math.max(
      0,
      SILVER_MONTHLY_STORY_CREDITS - storyCreditsUsed,
    ),
  };
}

function evaluateStoryGenerationRefund({ request, userData, usageData }) {
  const coinCost = Math.max(0, Number(request?.coinCost ?? 0));
  if (request?.paymentSource === 'silver') {
    const storyCreditsUsed = Math.max(
      0,
      Number(usageData?.storyCreditsUsed ?? 0),
    );
    const storiesCreated = Math.max(0, Number(usageData?.storiesCreated ?? 0));
    return {
      refunded: coinCost > 0,
      paymentSource: 'silver',
      storyCreditsUsedAfter: Math.max(0, storyCreditsUsed - coinCost),
      storiesCreatedAfter: Math.max(0, storiesCreated - 1),
    };
  }
  if (request?.paymentSource === 'coins') {
    const coins = Math.max(0, Number(userData?.coins ?? 0));
    return {
      refunded: coinCost > 0,
      paymentSource: 'coins',
      coinsAfter: coins + coinCost,
    };
  }
  return { refunded: false, paymentSource: 'none' };
}

function storyReservationResponse({
  requestId,
  request,
  idempotent = false,
  decision = null,
  refunded,
}) {
  return {
    requestId,
    status: request.status,
    mode: request.mode,
    pageCount: Number(request.pageCount ?? 0),
    coinCost: Number(request.coinCost ?? 0),
    paymentSource: request.paymentSource,
    usageMonthKey: request.usageMonthKey,
    idempotent,
    ...(decision
      ? {
          coinsAfter: decision.coinsAfter,
          storyCreditsUsedAfter: decision.storyCreditsUsedAfter,
          storyCreditsRemainingAfter: decision.storyCreditsRemainingAfter,
        }
      : {}),
    ...(typeof refunded === 'boolean' ? { refunded } : {}),
  };
}

function isSilverSubscriptionActive(userData, now = new Date()) {
  const subscription = userData?.silverSubscription || {};
  if (subscription.isActive !== true) {
    return false;
  }
  const endAtMs = normalizeTimestampMillis(subscription.endAt);
  return !endAtMs || endAtMs > now.getTime();
}

function normalizeTimestampMillis(value) {
  if (!value) {
    return null;
  }
  if (typeof value.toMillis === 'function') {
    return value.toMillis();
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string' && value.trim()) {
    const parsed = Date.parse(value.trim());
    return Number.isNaN(parsed) ? null : parsed;
  }
  if (typeof value === 'object') {
    const seconds = value.seconds ?? value._seconds;
    const nanoseconds = value.nanoseconds ?? value._nanoseconds ?? 0;
    if (Number.isFinite(seconds)) {
      return seconds * 1000 + Math.round(nanoseconds / 1000000);
    }
  }
  return null;
}

function storyUsageMonthKey(now = new Date()) {
  const jst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  const year = jst.getUTCFullYear();
  const month = String(jst.getUTCMonth() + 1).padStart(2, '0');
  return `${year}${month}`;
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

function readRequestId(value) {
  const requestId = readString(value, 'requestId');
  if (!/^[A-Za-z0-9_-]{8,80}$/.test(requestId)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'requestId の形式が不正です。',
    );
  }
  return requestId;
}

exports.__test__ = {
  CHILD_SAFE_REWRITE_MESSAGE,
  IMAGE_OUTPUT_JPEG_QUALITY,
  OPENAI_IMAGE_MODEL,
  OPENAI_IMAGE_OUTPUT_COMPRESSION,
  OPENAI_IMAGE_OUTPUT_FORMAT,
  OPENAI_IMAGE_QUALITY,
  OPENAI_IMAGE_SIZE,
  SILVER_MONTHLY_STORY_CREDITS,
  STORY_MODES,
  buildFallbackStoryPreview,
  buildOpenAiImageRequest,
  buildStoryPreviewPrompt,
  buildStoryPreviewRepairPrompt,
  buildStoryPreviewResponseSchema,
  buildStoryPrompt,
  buildStoryRepairPrompt,
  buildStoryResponseSchema,
  evaluateStoryGenerationRefund,
  evaluateStoryGenerationReservation,
  extractApiError,
  extractStoryPreviewSeeds,
  findUnsafeCategory,
  formatStoryOptionsForPrompt,
  hashGuestSessionId,
  isStoryJsonRequest,
  isSilverSubscriptionActive,
  maxStoryOutputTokens,
  normalizeHttpBody,
  normalizeStoryOptions,
  parseGeneratedStoryPreviewJson,
  parseGeneratedStoryJson,
  readHeaderValue,
  readRequestId,
  readString,
  rejectClientStoryPricing,
  requireCallableAppCheck,
  requireHttpAppCheck,
  resolveStoryMode,
  resolveGeneratorCaller,
  sanitizeOpenAiImagePrompt,
  stringifyGeneratedStoryJson,
  storyUsageMonthKey,
  validateGeneratedStoryQuality,
  validateStoryPreviewQuality,
};
