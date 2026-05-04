const assert = require('node:assert/strict');
const test = require('node:test');
const functions = require('firebase-functions/v1');

const { __test__ } = require('../index');

test('resolveGeneratorCaller returns auth caller when auth is present', () => {
  const caller = __test__.resolveGeneratorCaller(
    {
      auth: { uid: ' parent-uid ' },
    },
    {},
  );

  assert.deepEqual(caller, {
    id: 'parent-uid',
    mode: 'auth',
  });
});

test('resolveGeneratorCaller hashes guest session ids', () => {
  const caller = __test__.resolveGeneratorCaller(
    {},
    {
      guestSessionId: ' guest-session ',
    },
  );

  assert.equal(caller.mode, 'guest');
  assert.match(caller.id, /^guest_[a-f0-9]{32}$/);
});

test('resolveGeneratorCaller rejects requests without auth or guest session', () => {
  assert.throws(
    () => __test__.resolveGeneratorCaller({}, {}),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'unauthenticated',
  );
});

test('resolveHttpGeneratorCaller verifies bearer auth when present', async () => {
  const caller = await __test__.resolveHttpGeneratorCaller(
    {
      headers: {
        authorization: 'Bearer firebase-id-token',
      },
    },
    {},
    {
      verifyIdToken: async (token) => {
        assert.equal(token, 'firebase-id-token');
        return { uid: ' parent-uid ' };
      },
    },
  );

  assert.deepEqual(caller, {
    id: 'parent-uid',
    mode: 'auth',
  });
});

test('resolveHttpGeneratorCaller rejects invalid bearer auth', async () => {
  await assert.rejects(
    () =>
      __test__.resolveHttpGeneratorCaller(
        {
          headers: {
            authorization: 'Bearer broken-token',
          },
        },
        { guestSessionId: 'guest-session' },
        {
          verifyIdToken: async () => {
            throw new Error('invalid token');
          },
        },
      ),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'unauthenticated',
  );
});

test('requireCallableAppCheck returns the verified app id', () => {
  const appId = __test__.requireCallableAppCheck({
    app: { appId: ' app-id ' },
  });

  assert.equal(appId, 'app-id');
});

test('requireCallableAppCheck rejects when app check is missing', () => {
  assert.throws(
    () => __test__.requireCallableAppCheck({}),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'unauthenticated',
  );
});

test('requireHttpAppCheck verifies the provided app check token', async () => {
  const verification = await __test__.requireHttpAppCheck(
    {
      headers: {
        'x-firebase-appcheck': 'token-value',
      },
    },
    {
      verifyToken: async (token) => {
        assert.equal(token, 'token-value');
        return { appId: 'verified-app' };
      },
    },
  );

  assert.deepEqual(verification, { appId: 'verified-app' });
});

test('requireHttpAppCheck rejects requests without the header', async () => {
  await assert.rejects(
    () =>
      __test__.requireHttpAppCheck(
        {
          headers: {},
        },
        {
          verifyToken: async () => ({ appId: 'unused' }),
        },
      ),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'unauthenticated',
  );
});

test('normalizeHttpBody unwraps callable-style payloads', () => {
  assert.deepEqual(__test__.normalizeHttpBody({ data: { prompt: 'hello' } }), {
    prompt: 'hello',
  });
});

test('findUnsafeCategory detects unsafe prompts', () => {
  assert.equal(
    __test__.findUnsafeCategory('please show blood and gore'),
    'graphic_violence',
  );
});

test('extractApiError prefers nested error messages', () => {
  assert.equal(
    __test__.extractApiError({
      error: { message: 'backend failure' },
    }),
    'backend failure',
  );
});

test('apiErrorCodeForResponse maps billing limits to resource exhaustion', () => {
  assert.equal(
    __test__.apiErrorCodeForResponse(
      500,
      'Billing hard limit has been reached.',
    ),
    'resource-exhausted',
  );
  assert.equal(
    __test__.apiErrorCodeForResponse(429, 'rate limited'),
    'resource-exhausted',
  );
});

test('image generation uses Imagen 4 with vertical output settings', () => {
  const request = __test__.buildImagenImageRequest('draw a friendly scene');

  assert.equal(__test__.IMAGEN_IMAGE_MODEL, 'imagen-4.0-generate-001');
  assert.equal(__test__.IMAGEN_IMAGE_ASPECT_RATIO, '9:16');
  assert.equal(__test__.IMAGEN_IMAGE_SAMPLE_COUNT, 1);
  assert.equal(__test__.IMAGEN_PERSON_GENERATION, 'allow_all');
  assert.equal(__test__.IMAGE_OUTPUT_WIDTH, 900);
  assert.equal(__test__.IMAGE_OUTPUT_HEIGHT, 1600);
  assert.ok(__test__.IMAGE_OUTPUT_JPEG_QUALITY >= 80);
  assert.deepEqual(request, {
    instances: [{ prompt: 'draw a friendly scene' }],
    parameters: {
      sampleCount: 1,
      aspectRatio: '9:16',
      personGeneration: 'allow_all',
    },
  });
});

test('buildImagenPrompt uses positive full-frame visual instructions', () => {
  const prompt = __test__.buildImagenPrompt({
    page: 1,
    sceneGoal:
      'A fox child finds a secret clue on a paper card with a question mark.',
    mainCharacterDescription: 'small orange fox child, blue scarf',
    supportingCharacters: 'gentle bear friend with red backpack',
    sceneDescription: 'The fox and bear read a note beside a map and a sign.',
    composition: 'Vertical 9:16, fox large in the lower foreground.',
    emotion: 'Warm surprise and friendly curiosity.',
    backgroundDescription: 'Simple candy trees and soft pastel path.',
    environmentDescription:
      'A storybook page with a blank title area and a bottom 28% caption area.',
    foregroundElements: ['fox child', 'secret clue card'],
    midgroundElements: ['soft candy path'],
    backgroundElements: ['candy trees', 'pastel hills'],
    backgroundMustFillCanvas: true,
    wordlessMode: true,
    forbiddenTextSurfaces: ['signs', 'labels', 'logos'],
    style: __test__.DEFAULT_IMAGE_STYLE,
    avoid: ['text', 'letters'],
  });

  for (const section of [
    "Create a vertical full-frame children's illustration.",
    'Create only a wordless visual scene.',
    'whole canvas from edge to edge',
    'Scene:',
    'Characters:',
    'Setting:',
    'Composition:',
    'Main story object:',
    'Style:',
    'Surface rule:',
    'Output:',
    'central area',
    'lower foreground',
  ]) {
    assert.match(prompt, new RegExp(section));
  }
  assert.match(prompt, /small orange fox child/);
  assert.match(prompt, /small glowing star charm|small glowing charm/);
  assert.match(prompt, /Warm surprise/);
  for (const removedPhrase of [
    'text',
    'letter',
    'number',
    'symbol',
    '%',
    '28%',
    'bottom 28%',
    'Japanese narration',
    'speech bubble',
    'thought bubble',
    'caption',
    'title',
    'book',
    'page',
    'book page',
    'cover',
    'poster',
    'layout',
    'card',
    'note',
    'map',
    'blackboard',
    'screen',
    'newspaper',
    'question mark',
    'Scene goal:',
    'Do not include:',
  ]) {
    assert.doesNotMatch(prompt, new RegExp(removedPhrase, 'i'));
  }
  assert.match(prompt, /A single full-scene wordless illustration/);
});

test('parseImageSpecJson strips extra fields and normalizes specs', () => {
  const fallbackProfile = __test__.fallbackCharacterProfile({
    title: 'きつねのぼうけん',
    characterSheet: {
      protagonist: 'small fox child, orange fur, blue scarf',
      worldDetails: 'candy castle garden',
    },
  });
  const fallbackSpecs = [
    __test__.fallbackImagePageSpec({
      page: 1,
      pageSummary: 'fox finds lantern',
      characterProfile: fallbackProfile,
    }),
  ];
  const parsed = __test__.parseImageSpecJson(
    JSON.stringify({
      characterProfile: {
        ...fallbackProfile,
        name: 'Kitsune',
        extra: 'drop me',
      },
      imagePageSpecs: [
        {
          page: 1,
          sceneGoal: 'Fox finds the lantern.',
          mainCharacterDescription: 'orange fox child with blue scarf',
          supportingCharacters: '',
          sceneDescription: 'A fox kneels near a glowing lantern.',
          composition: 'Clear vertical 9:16 foreground character.',
          emotion: 'Gentle wonder.',
          backgroundDescription: 'Simple candy garden.',
          environmentDescription: '',
          foregroundElements: [],
          midgroundElements: [],
          backgroundElements: [],
          backgroundMustFillCanvas: true,
          wordlessMode: true,
          forbiddenTextSurfaces: [],
          style: '',
          avoid: [],
          visualFocus: 'Fox kneels near a glowing lantern.',
          mood: 'Gentle wonder.',
          visibleCast: ['protagonist'],
          scene: {
            location: 'candy garden',
            time: 'morning',
            action: 'Fox kneels near a glowing lantern.',
            composition: 'central fox',
            camera: 'medium shot',
            lighting: 'warm light',
            characterDetails: ['orange fox child with blue scarf'],
            allowedObjects: ['small glowing gem'],
            forbiddenObjects: ['readable text'],
          },
          extra: 'drop me',
        },
      ],
    }),
    {
      pageCount: 1,
      fallbackProfile,
      fallbackSpecs,
    },
  );

  assert.deepEqual(Object.keys(parsed.characterProfile), [
    'name',
    'appearance',
    'clothing',
    'colors',
    'expressionStyle',
    'personalityTone',
    'worldStyle',
  ]);
  assert.deepEqual(Object.keys(parsed.imagePageSpecs[0]), [
    'page',
    'sceneGoal',
    'mainCharacterDescription',
    'supportingCharacters',
    'sceneDescription',
    'composition',
    'emotion',
    'backgroundDescription',
    'environmentDescription',
    'foregroundElements',
    'midgroundElements',
    'backgroundElements',
    'backgroundMustFillCanvas',
    'wordlessMode',
    'forbiddenTextSurfaces',
    'style',
    'avoid',
    'visualFocus',
    'mood',
    'visibleCast',
    'scene',
  ]);
  assert.equal(parsed.imagePageSpecs[0].supportingCharacters, 'None.');
  assert.equal(parsed.imagePageSpecs[0].style, __test__.DEFAULT_IMAGE_STYLE);
  assert.equal(parsed.imagePageSpecs[0].backgroundMustFillCanvas, true);
  assert.equal(parsed.imagePageSpecs[0].wordlessMode, true);
  assert.ok(parsed.imagePageSpecs[0].foregroundElements.length > 0);
  assert.ok(parsed.imagePageSpecs[0].backgroundElements.length > 0);
  assert.ok(parsed.imagePageSpecs[0].forbiddenTextSurfaces.includes('signs'));
  assert.ok(parsed.imagePageSpecs[0].avoid.includes('distorted hands'));
  assert.equal(parsed.imagePageSpecs[0].scene.location, 'candy garden');
  assert.ok(
    parsed.imagePageSpecs[0].scene.allowedObjects.includes('small glowing gem'),
  );
});

test('fallbackImagePageSpec fills missing values', () => {
  const spec = __test__.fallbackImagePageSpec({
    page: 2,
    pageSummary: 'A fox looks at a small door.',
  });

  assert.equal(spec.page, 2);
  assert.equal(spec.sceneGoal, 'A fox looks at a small door.');
  assert.equal(spec.supportingCharacters, 'None.');
  assert.equal(spec.style, __test__.DEFAULT_IMAGE_STYLE);
  assert.equal(spec.backgroundMustFillCanvas, true);
  assert.equal(spec.wordlessMode, true);
  assert.ok(spec.environmentDescription.includes('environment'));
  assert.ok(spec.foregroundElements.includes('main character clearly visible'));
  assert.ok(spec.midgroundElements.includes('plain props without writing'));
  assert.ok(
    spec.backgroundElements.some((entry) => entry.includes('wordless')),
  );
  assert.ok(spec.forbiddenTextSurfaces.includes('blackboards'));
  assert.ok(spec.avoid.includes('text'));
  assert.ok(spec.avoid.includes('signs'));
  assert.ok(spec.avoid.includes('extra fingers'));
  assert.equal(spec.scene.action, 'A fox looks at a small door.');
  assert.ok(spec.scene.forbiddenObjects.includes('readable text'));
});

test('generateImageSpecsFromCanon builds safe specs from StoryCanon', () => {
  const canon = buildValidStoryCanon(4, {
    pagePlans: buildValidStoryCanon(4).pagePlans.map((plan, index) => ({
      ...plan,
      visualBeat:
        index === 0
          ? 'Mimi discovers a secret clue, a message, a book, and a map.'
          : plan.visualBeat,
      allowedObjects:
        index === 0
          ? ['secret clue', 'message', 'book', 'map', 'paper note']
          : plan.allowedObjects,
    })),
  });

  const parsed = __test__.generateImageSpecsFromCanon({ storyCanon: canon });
  const spec = parsed.imagePageSpecs[0];
  const prompt = __test__.buildImagenPrompt(spec);

  assert.equal(parsed.imagePageSpecs.length, 4);
  assert.equal(parsed.characterProfile.name, 'Mimi');
  assert.match(spec.scene.action, /small glowing star charm/);
  assert.ok(spec.scene.forbiddenObjects.includes('readable text'));
  assert.ok(spec.scene.forbiddenObjects.includes('paper'));
  assert.doesNotMatch(prompt, /paper note/i);
  assert.doesNotMatch(prompt, /book as object/i);
  assert.doesNotMatch(prompt, /readable sign/i);
  assert.doesNotMatch(prompt, /\bSECRET\b/);
  assert.doesNotMatch(prompt, /\bMAP\b/);
  assert.doesNotMatch(prompt, /\bBOOK\b/);
});

test('normalizeStoryCanon pads pagePlans for long modes', () => {
  const canon = __test__.normalizeStoryCanon(
    buildValidStoryCanon(4, {
      pagePlans: buildValidStoryCanon(4).pagePlans.slice(0, 2),
    }),
    { pageCount: 12 },
  );

  assert.equal(canon.pagePlans.length, 12);
  assert.ok(canon.pagePlans[11].forbiddenObjects.includes('readable text'));
});

test('image quality retry helpers regenerate at most once', () => {
  const failedAssessment = __test__.normalizeImageQualityAssessment({
    hasCompleteBackground: false,
    hasVisibleWriting: false,
    hasPaperLikeObjectWithMarks: false,
    isAcceptable: true,
    reason: 'Blank background.',
  });

  assert.equal(failedAssessment.isAcceptable, false);
  assert.equal(
    __test__.shouldRegenerateFromImageAssessment(failedAssessment, 0),
    true,
  );
  assert.equal(
    __test__.shouldRegenerateFromImageAssessment(failedAssessment, 1),
    false,
  );

  const corrected = __test__.buildCorrectedImagenPrompt('base prompt');
  assert.match(corrected, /Correction emphasis:/);
  assert.match(corrected, /Create a cleaner wordless version/);
  assert.match(corrected, /plain decorative objects/);
  assert.match(corrected, /whole canvas/);
  assert.match(corrected, /lower foreground/);
  for (const removedPhrase of [
    'speech bubble',
    'thought bubble',
    'No text',
    'letters',
    'numbers',
    'symbols',
    'caption',
  ]) {
    assert.doesNotMatch(corrected, new RegExp(removedPhrase, 'i'));
  }
});

test('sanitizeVisualPromptForImagen removes text-trigger story objects', () => {
  const prompt = __test__.sanitizeVisualPromptForImagen(
    'A rabbit finds a secret clue, written clue, secret, answer, message, problem, question mark, wondering, letter, note, paper, card, map, book, sign, label, speech bubble, and thought bubble.',
  );

  assert.match(prompt, /small glowing star charm/);
  assert.match(prompt, /small glowing charm/);
  assert.match(prompt, /soft magical glow/);
  assert.match(prompt, /warm discovery moment/);
  assert.match(prompt, /friendly gesture/);
  assert.match(prompt, /small obstacle on the path/);
  assert.match(prompt, /curious facial expression/);
  assert.match(prompt, /tiny flower/);
  assert.match(prompt, /small gem/);
  assert.match(prompt, /winding path/);
  assert.match(prompt, /tree stump/);
  assert.match(prompt, /plain decoration/);
  assert.match(prompt, /open sky/);
  assert.match(prompt, /soft cloud in the sky/);
  assert.doesNotMatch(prompt, /secret clue/i);
  assert.doesNotMatch(prompt, /question mark/i);
  assert.doesNotMatch(prompt, /\bnote\b/i);
  assert.doesNotMatch(prompt, /\bmap\b/i);
  assert.doesNotMatch(prompt, /\bbook\b/i);
  assert.doesNotMatch(prompt, /\bspeech bubble\b/i);
  assert.doesNotMatch(prompt, /\bthought bubble\b/i);
  assert.doesNotMatch(prompt, /\bsign\b/i);
});

test('normalizeImageQualityAssessment rejects generated text and caption overlap', () => {
  const assessment = __test__.normalizeImageQualityAssessment({
    hasVisibleWriting: true,
    hasFakeWriting: true,
    hasQuestionMark: true,
    hasBubbleShapeForDialogue: true,
    hasPaperLikeObjectWithMarks: true,
    hasBlankPageLayout: true,
    hasCompleteBackground: true,
    importantSubjectTooLow: true,
    isAcceptable: true,
    reason: 'Writing-like marks and low subject.',
  });

  assert.equal(assessment.isAcceptable, false);
  assert.equal(assessment.hasVisibleWriting, true);
  assert.equal(assessment.hasFakeWriting, true);
  assert.equal(assessment.hasQuestionMark, true);
  assert.equal(assessment.hasBubbleShapeForDialogue, true);
  assert.equal(assessment.hasPaperLikeObjectWithMarks, true);
  assert.equal(assessment.hasBlankPageLayout, true);
  assert.equal(assessment.importantSubjectTooLow, true);
});

test('structured image prompts do not merge negative prompt terms', () => {
  const { positivePrompt, negativePromptText } =
    __test__.buildImageGenerationPromptsForImagen({
      prompt: 'Create only a wordless visual scene.',
      negativePrompt: 'text, speech bubbles, title, map',
      imageDebug: { imagePageSpec: { page: 1 } },
    });

  assert.equal(negativePromptText, '');
  const merged = __test__.buildImagenMergedPrompt({
    prompt: positivePrompt,
    negativePrompt: negativePromptText,
  });
  assert.doesNotMatch(merged, /Avoid the following elements/i);
  assert.doesNotMatch(merged, /speech bubbles/i);
  assert.doesNotMatch(merged, /title/i);
  assert.doesNotMatch(merged, /\bmap\b/i);
});

test('sanitizeImagePrompt avoids provider safety trigger wording', () => {
  const prompt = __test__.sanitizeImagePrompt(
    'Children picture-book illustration for a young audience, different age, adult themes',
  );

  assert.equal(
    prompt,
    'family picture-book illustration for a family audience, unfriendly themes',
  );
});

function buildValidStory(overrides = {}) {
  return {
    title: 'くしゃみパンやさん',
    coverScene: '朝の森のパン屋で、粉袋がぽふんとはねる場面',
    characterSheet: {
      protagonist: 'うさぎのミミ。白い耳、赤いエプロン、丸い目。',
      companion: 'くまのポポ。黄色い帽子、小さなかばん、やさしい顔。',
      worldDetails: '朝の光が入る小さな森のパン屋。',
      artDirection: '明るい水彩の絵本風、やわらかい色。',
    },
    pages: [
      {
        story:
          'ミミは朝いちばんの丸パンをふくらませたくて、粉をそっとふるいました。すると粉袋が「へくちっ」とくしゃみをして、棚のパンがぽんぽん跳ねました。',
        visualFocus:
          '森の小さなパン屋。うさぎのミミが粉袋のくしゃみに驚く。朝の光、明るい絵本風、9:16縦長。',
        mood: 'わくわくして少しびっくり',
        dialogue: 'へくちっ',
        visibleCast: ['protagonist'],
      },
      {
        story:
          'ミミは袋にリボンを巻けば止まると思いました。でもぎゅっと結ぶほど粉袋はむずむずして、白い粉が雲みたいに広がりました。',
        visualFocus:
          'パン屋の棚の前。ミミがリボンを結び、粉の雲に目を丸くする。明るい安全な絵本風、9:16縦長。',
        mood: 'こまってあたふた',
        dialogue: '',
        visibleCast: ['protagonist'],
      },
      {
        story:
          '入口からポポが鼻をひくひくさせました。「こしょうじゃなくて、花のにおいみたい」ミミは窓辺の花びんを見て、くしゃみのわけに気づきました。',
        visualFocus:
          'パン屋の入口。くまのポポが花びんを指し、ミミがはっとする。明るい絵本風、9:16縦長。',
        mood: 'ふしぎでひらめく',
        dialogue: '花のにおいみたい',
        visibleCast: ['protagonist', 'companion'],
      },
      {
        story:
          'ミミは花びんを外に出し、粉袋に小さなマスクをつけました。パンはふっくら焼けましたが、今度はポポの帽子が「へくちっ」と跳ねました。',
        visualFocus:
          'パン屋の窓辺。ミミとポポが焼けたパンを見て笑い、帽子が跳ねる。明るい絵本風、9:16縦長。',
        mood: 'ほっとしてくすっとする',
        dialogue: 'へくちっ',
        visibleCast: ['protagonist', 'companion'],
      },
    ],
    ...overrides,
  };
}

function buildValidStoryCanon(pageCount = 4, overrides = {}) {
  return {
    title: 'Mimi and the soft glow',
    visualStyle: "Soft children's illustration with warm pastel colors.",
    worldRules: {
      noReadableText: true,
      noLetters: true,
      noSigns: true,
      noBooks: true,
      noMaps: true,
      noPaper: true,
      magicIsShownAs: 'glowing petals and small star charms',
    },
    cast: [
      {
        id: 'protagonist',
        name: 'Mimi',
        role: 'protagonist',
        appearance: 'small cream rabbit with round eyes',
        outfit: 'red scarf and tiny backpack',
        colors: ['cream', 'red', 'warm brown'],
        personalityVisualCues: 'curious face and gentle smile',
      },
      {
        id: 'companion',
        name: 'Poro',
        role: 'companion',
        appearance: 'small yellow bird with round body',
        outfit: 'tiny green satchel',
        colors: ['yellow', 'green'],
        personalityVisualCues: 'helpful bright expression',
      },
    ],
    setting: {
      mainLocation: 'sunlit forest path',
      timeOfDay: 'warm morning',
      season: 'spring',
      recurringVisualMotifs: [
        'soft glowing petals',
        'tiny footprints',
        'winding path',
      ],
    },
    pagePlans: Array.from({ length: pageCount }, (_, index) => ({
      page: index + 1,
      storyBeat: `Beat ${index + 1}`,
      userTextIntent:
        'Display text may mention a secret clue, a message, a book, or a map.',
      visualBeat:
        'Mimi and Poro follow soft glowing petals beside a winding path.',
      visibleCast: ['protagonist', 'companion'],
      characterPositions: 'Mimi and Poro stand together in the central area.',
      camera: 'medium shot',
      lighting: 'warm morning light',
      emotion: 'curious and hopeful',
      allowedObjects: ['soft glowing petals', 'winding path'],
      forbiddenObjects: ['readable text'],
    })),
    ...overrides,
  };
}

function buildDistinctStoryPages(pageCount) {
  const basePages = buildValidStory().pages;
  const storyTexts = [
    'ミミは朝の森で 光るどんぐりを見つけ、ポポに「見て」と小さな声で知らせました。',
    'ポポは川べりの丸い石をならべ、飛びこえられる道をゆっくり作りました。',
    '風が青いリボンを運んできて、ふたりは木の枝に結びつけて目印にしました。',
    '雲のすきまから星形の光が落ち、ミミはなくした鈴の音を聞き分けました。',
    '小さな橋がゆれても、ポポは花のかげにある安全な足場を見つけました。',
    'ふたりは丘の上で金色の羽を拾い、夕方までに返す相手を探しました。',
    '森の門の前で甘いにおいがして、ミミはパン屋の煙突を思い出しました。',
    'さいごに帽子がくしゃみをして、ふたりは顔を見合わせてくすっと笑いました。',
  ];

  return Array.from({ length: pageCount }, (_, index) => ({
    ...basePages[index % basePages.length],
    story: storyTexts[index % storyTexts.length],
    visualFocus: `場面${index + 1}: ${storyTexts[index % storyTexts.length]}`,
    mood: `気持ち${index + 1}`,
    dialogue: index === 0 ? '見て' : '',
    visibleCast: ['protagonist', 'companion'],
  }));
}

test('buildStoryPrompt includes story quality requirements', () => {
  const prompt = __test__.buildStoryPrompt({ prompt: 'Return JSON only.' });

  assert.match(prompt, /失敗/);
  assert.match(prompt, /意外な気づき/);
  assert.match(prompt, /小さな笑えるオチ/);
  assert.match(prompt, /4ページ/);
  assert.match(prompt, /Image prompt field language overrides/);
  assert.match(prompt, /Write "coverScene".*simple concrete English/);
  assert.match(prompt, /Do not write generic visual fields/);
  assert.match(prompt, /StoryCanon \/ VisualBible requirements/);
  assert.match(prompt, /storyCanon\.pagePlans must contain exactly 4 items/);
});

test('story modes define server-owned page counts and costs', () => {
  assert.equal(__test__.resolveStoryMode('mini').pageCount, 4);
  assert.equal(__test__.resolveStoryMode('mini').coinCost, 1);
  assert.equal(__test__.resolveStoryMode('standard').pageCount, 8);
  assert.equal(__test__.resolveStoryMode('standard').coinCost, 2);
  assert.equal(__test__.resolveStoryMode('premium').pageCount, 12);
  assert.equal(__test__.resolveStoryMode('premium').coinCost, 3);
});

test('invalid story mode and client-owned pricing are rejected', () => {
  assert.throws(
    () => __test__.resolveStoryMode('long'),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'invalid-argument',
  );
  assert.throws(
    () => __test__.rejectClientStoryPricing({ pageCount: 99 }),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'invalid-argument',
  );
  assert.throws(
    () => __test__.rejectClientStoryPricing({ coinCost: 0 }),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'invalid-argument',
  );
});

test('story response schema follows the selected mode only', () => {
  const schema = __test__.buildStoryResponseSchema(
    __test__.resolveStoryMode('premium'),
  );

  assert.equal(schema.properties.pages.minItems, 12);
  assert.equal(schema.properties.pages.maxItems, 12);
});

test('story response schema omits StoryCanon to stay small for Gemini', () => {
  const schema = __test__.buildStoryResponseSchema(
    __test__.resolveStoryMode('standard'),
  );

  assert.equal(schema.properties.storyCanon, undefined);
});

test('parseGeneratedStoryPreviewJson enforces preview page plan length', () => {
  const validPreview = {
    title: 'にじのもり',
    summary: 'ふしぎな森で小さな冒険をします。',
    pagePlan: Array.from({ length: 8 }, (_, index) => `${index + 1}ページ`),
  };

  const parsed = __test__.parseGeneratedStoryPreviewJson(
    JSON.stringify(validPreview),
    { pageCount: 8 },
  );

  assert.equal(parsed.pagePlan.length, 8);
  assert.throws(
    () =>
      __test__.parseGeneratedStoryPreviewJson(JSON.stringify(validPreview), {
        pageCount: 12,
      }),
    (error) =>
      error instanceof functions.https.HttpsError && error.code === 'internal',
  );
});

test('validateStoryPreviewQuality rejects repeated page plans', () => {
  const preview = {
    title: 'Penguin Test',
    summary: 'A penguin tries a small adventure.',
    pagePlan: [
      'Penguin finds a small wish under a cedar tree.',
      'The same foggy event spreads while Penguin walks ahead.',
      'The same foggy event spreads while Penguin walks ahead.',
      'The same foggy event spreads while Penguin walks ahead.',
      'The same foggy event spreads while Penguin walks ahead.',
      'The same foggy event spreads while Penguin walks ahead.',
      'The same foggy event spreads while Penguin walks ahead.',
      'Penguin and the bird solve the problem and rest.',
    ],
  };

  const issues = __test__.validateStoryPreviewQuality(preview, {
    pageCount: 8,
  });

  assert.ok(issues.some((issue) => issue.code === 'duplicate_page_plan'));
});

test('validateStoryPreviewQuality rejects repeated generic preview fragments', () => {
  const preview = {
    title: 'にじのもり',
    summary: 'ペンギンがにじの森で願いを見つけます。',
    pagePlan: [
      'ペンギンがにじの森で小さな願いを見つける。',
      'にじの森でふしぎな出来事が広がり、ペンギンが一歩ずつ進む。',
      '赤い葉っぱの道でふしぎな出来事が広がり、ペンギンが一歩ずつ進む。',
      'ペンギンが橋でころび、別の道を選ぶ。',
      'ことりが光る種を見つけ、ペンギンが歌を思い出す。',
      '黒い雲が広場をかくし、ふたりが急いで種を植える。',
      '歌と種の光で雲がほどけ、森に道が戻る。',
      'ペンギンが願いをそっとしまい、ことりと家へ帰る。',
    ],
  };

  const issues = __test__.validateStoryPreviewQuality(preview, {
    pageCount: 8,
  });

  assert.ok(issues.some((issue) => issue.code === 'generic_page_plan'));
});

test('validateStoryPreviewQuality accepts varied page plans', () => {
  const preview = {
    title: 'Penguin Test',
    summary: 'A penguin and a bird cross a forest to fix a tiny problem.',
    pagePlan: [
      'Penguin finds a blue bell beside the cedar gate.',
      'A letter asks Penguin to bring the bell to the sleeping pond.',
      'Penguin and Bird enter the moss path and follow a soft sound.',
      'Penguin drops the bell in mud and has to clean it carefully.',
      'Bird uses a feather map while Penguin remembers a favorite song.',
      'A tall vine blocks the pond just as the bell starts to glow.',
      'Penguin sings, Bird lifts the vine, and the pond wakes up.',
      'The pond gives them a tiny rainbow stone for the walk home.',
    ],
  };

  const issues = __test__.validateStoryPreviewQuality(preview, {
    pageCount: 8,
  });

  assert.deepEqual(issues, []);
});

test('buildFallbackStoryPreview creates distinct standard page plans from seeds', () => {
  const preview = __test__.buildFallbackStoryPreview({
    preview: {
      title: 'にじのもり',
      summary: 'ペンギンがことりとにじのもりを進みます。',
      pagePlan: [],
    },
    chatLogs: '',
    summaryMainSettings: [
      'このおはなしの主人公: ペンギン',
      'このおはなしの場所: にじのもり',
      'このおはなしの仲間: ことり',
      '仲間のせつめい: げんきなことり',
    ].join('\n'),
    mode: __test__.resolveStoryMode('standard'),
    storyOptions: __test__.normalizeStoryOptions({}),
  });

  assert.equal(preview.pagePlan.length, 8);
  assert.deepEqual(
    __test__.validateStoryPreviewQuality(preview, { pageCount: 8 }),
    [],
  );
  assert.ok(preview.pagePlan.some((entry) => entry.includes('ペンギン')));
  assert.ok(preview.pagePlan.some((entry) => entry.includes('ことり')));
});

test('parseGeneratedStoryJson accepts fenced JSON and strips extra fields', () => {
  const rawStory = {
    ...buildValidStory(),
    storyPlan: 'internal only',
    pages: buildValidStory().pages.map((page) => ({
      ...page,
      internalScore: 10,
    })),
  };

  const parsed = __test__.parseGeneratedStoryJson(
    `\`\`\`json\n${JSON.stringify(rawStory)}\n\`\`\``,
  );

  assert.deepEqual(Object.keys(parsed), [
    'title',
    'coverScene',
    'characterSheet',
    'pages',
    'storyCanon',
  ]);
  assert.deepEqual(Object.keys(parsed.pages[0]), [
    'story',
    'visualFocus',
    'mood',
    'dialogue',
    'visibleCast',
  ]);
  assert.equal(parsed.storyPlan, undefined);
  assert.equal(parsed.pages[0].internalScore, undefined);
  assert.equal(parsed.storyCanon.pagePlans.length, 4);
  assert.ok(
    parsed.storyCanon.pagePlans[0].forbiddenObjects.includes('readable text'),
  );
});

test('parseGeneratedStoryJson rejects responses without 4 pages', () => {
  const invalidStory = buildValidStory({
    pages: buildValidStory().pages.slice(0, 3),
  });

  assert.throws(
    () => __test__.parseGeneratedStoryJson(JSON.stringify(invalidStory)),
    (error) =>
      error instanceof functions.https.HttpsError &&
      error.code === 'internal' &&
      error.message.includes('exactly 4 pages'),
  );
});

test('parseGeneratedStoryJson accepts mode-specific page counts', () => {
  const pages = Array.from({ length: 8 }, (_, index) => ({
    ...buildValidStory().pages[index % 4],
    story: `ページ${index + 1}の本文です。`,
  }));
  const parsed = __test__.parseGeneratedStoryJson(
    JSON.stringify(buildValidStory({ pages })),
    { pageCount: 8 },
  );

  assert.equal(parsed.pages.length, 8);
  assert.equal(parsed.storyCanon.pagePlans.length, 8);
});

test('parseGeneratedStoryJson normalizes provided StoryCanon', () => {
  const baseCanon = buildValidStoryCanon(4);
  const story = buildValidStory({
    storyCanon: buildValidStoryCanon(4, {
      pagePlans: [
        ...baseCanon.pagePlans.slice(0, 3),
        {
          ...baseCanon.pagePlans[3],
          visualBeat:
            'Mimi finds a secret clue in a book beside a map and a sign.',
          allowedObjects: ['secret clue', 'book', 'map', 'sign'],
          forbiddenObjects: [],
        },
      ],
    }),
  });

  const parsed = __test__.parseGeneratedStoryJson(JSON.stringify(story));
  const plan = parsed.storyCanon.pagePlans[3];

  assert.equal(parsed.storyCanon.title, 'Mimi and the soft glow');
  assert.equal(parsed.storyCanon.pagePlans.length, 4);
  assert.match(plan.visualBeat, /small glowing star charm/);
  assert.doesNotMatch(plan.visualBeat, /\bbook\b/i);
  assert.doesNotMatch(plan.visualBeat, /\bmap\b/i);
  assert.doesNotMatch(plan.visualBeat, /\bsign\b/i);
  assert.ok(plan.allowedObjects.includes('small glowing star charm'));
  assert.ok(plan.forbiddenObjects.includes('readable text'));
  assert.ok(plan.forbiddenObjects.includes('Japanese characters'));
});

test('validateGeneratedStoryQuality detects banned endings', () => {
  const story = buildValidStory({
    pages: [
      ...buildValidStory().pages.slice(0, 3),
      {
        ...buildValidStory().pages[3],
        story: 'パンは焼けて、みんなで楽しく過ごしました',
      },
    ],
  });

  const issues = __test__.validateGeneratedStoryQuality(story);

  assert.ok(issues.some((issue) => issue.code === 'banned_ending'));
});

test('validateGeneratedStoryQuality detects duplicate story pages', () => {
  const pages = buildDistinctStoryPages(8);
  const repeatedStory =
    'やさしいこぐまが ひみつの 手がかりを 見つけると、景色の見え方が くるりと変わった。思っていたよりも やさしい答えが その先に かくれていた。';
  pages[1] = { ...pages[1], story: repeatedStory };
  pages[2] = { ...pages[2], story: repeatedStory };
  pages[3] = { ...pages[3], story: repeatedStory };

  const issues = __test__.validateGeneratedStoryQuality(
    buildValidStory({ pages }),
    { pageCount: 8 },
  );

  assert.ok(issues.some((issue) => issue.code === 'duplicate_story_page'));
});

test('validateGeneratedStoryQuality detects similar story pages', () => {
  const pages = buildDistinctStoryPages(8);
  pages[4] = {
    ...pages[4],
    story:
      'ふたりの まえに 小さなトラブルが あらわれた。でも きつねは まっすぐで ゆうきがあるところを 思いだし、あわてずに まわりを 見た。',
  };
  pages[5] = {
    ...pages[5],
    story:
      'ふたりの まえに 小さなトラブルが あらわれた。でも きつねは まっすぐで ゆうきがあるところを 思いだし、あわてずに まわりを 見ていた。',
  };
  pages[6] = {
    ...pages[6],
    story:
      'ふたりの まえに 小さなトラブルが あらわれた。でも きつねは まっすぐで ゆうきがあるところを 思いだし、あわてずに まわりを 見てみた。',
  };

  const issues = __test__.validateGeneratedStoryQuality(
    buildValidStory({ pages }),
    { pageCount: 8 },
  );

  assert.ok(issues.some((issue) => issue.code === 'similar_story_page'));
});

test('validateGeneratedStoryQuality accepts distinct story pages', () => {
  const issues = __test__.validateGeneratedStoryQuality(buildValidStory());

  assert.deepEqual(issues, []);
});

test('stringifyGeneratedStoryJson preserves the existing response shape', () => {
  const story = buildValidStory();
  const text = __test__.stringifyGeneratedStoryJson(JSON.stringify(story));
  const parsed = JSON.parse(text);

  assert.equal(typeof parsed.title, 'string');
  assert.equal(typeof parsed.coverScene, 'string');
  assert.equal(typeof parsed.characterSheet.protagonist, 'string');
  assert.equal(parsed.pages.length, 4);
  assert.equal(parsed.storyCanon.pagePlans.length, 4);
  assert.deepEqual(Object.keys(parsed.pages[0]), [
    'story',
    'visualFocus',
    'mood',
    'dialogue',
    'visibleCast',
  ]);
});

test('reservation uses Silver credits before coins when enough remain', () => {
  const decision = __test__.evaluateStoryGenerationReservation({
    userData: {
      coins: 10,
      silverSubscription: {
        isActive: true,
        endAt: new Date('2030-01-01T00:00:00Z').toISOString(),
      },
    },
    usageData: { storyCreditsUsed: 3, storiesCreated: 1 },
    mode: __test__.resolveStoryMode('standard'),
    now: new Date('2026-04-10T00:00:00Z'),
  });

  assert.equal(decision.canReserve, true);
  assert.equal(decision.paymentSource, 'silver');
  assert.equal(decision.storyCreditsUsedAfter, 5);
  assert.equal(decision.coinsAfter, 10);
});

test('reservation falls back to coins when Silver credits are short', () => {
  const decision = __test__.evaluateStoryGenerationReservation({
    userData: {
      coins: 3,
      silverSubscription: {
        isActive: true,
        endAt: new Date('2030-01-01T00:00:00Z').toISOString(),
      },
    },
    usageData: { storyCreditsUsed: 5, storiesCreated: 2 },
    mode: __test__.resolveStoryMode('standard'),
    now: new Date('2026-04-10T00:00:00Z'),
  });

  assert.equal(decision.canReserve, true);
  assert.equal(decision.paymentSource, 'coins');
  assert.equal(decision.coinsAfter, 1);
});

test('reservation is denied when both Silver credits and coins are short', () => {
  const decision = __test__.evaluateStoryGenerationReservation({
    userData: {
      coins: 1,
      silverSubscription: {
        isActive: true,
        endAt: new Date('2030-01-01T00:00:00Z').toISOString(),
      },
    },
    usageData: { storyCreditsUsed: 5, storiesCreated: 2 },
    mode: __test__.resolveStoryMode('standard'),
    now: new Date('2026-04-10T00:00:00Z'),
  });

  assert.equal(decision.canReserve, false);
  assert.equal(decision.paymentSource, 'none');
});

test('refund returns reserved Silver credits or coins', () => {
  const silverRefund = __test__.evaluateStoryGenerationRefund({
    request: { paymentSource: 'silver', coinCost: 3 },
    userData: { coins: 0 },
    usageData: { storyCreditsUsed: 6, storiesCreated: 2 },
  });
  const coinRefund = __test__.evaluateStoryGenerationRefund({
    request: { paymentSource: 'coins', coinCost: 2 },
    userData: { coins: 1 },
    usageData: {},
  });

  assert.equal(silverRefund.storyCreditsUsedAfter, 3);
  assert.equal(silverRefund.storiesCreatedAfter, 1);
  assert.equal(coinRefund.coinsAfter, 3);
});
