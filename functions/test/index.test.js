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

test('image generation uses GPT Image 2 with vertical output settings', () => {
  const request = __test__.buildOpenAiImageRequest('draw a friendly scene');

  assert.equal(__test__.OPENAI_IMAGE_MODEL, 'gpt-image-2');
  assert.equal(__test__.OPENAI_IMAGE_SIZE, '1024x1536');
  assert.equal(__test__.OPENAI_IMAGE_QUALITY, 'high');
  assert.equal(__test__.OPENAI_IMAGE_OUTPUT_FORMAT, 'jpeg');
  assert.equal(__test__.OPENAI_IMAGE_OUTPUT_COMPRESSION, 90);
  assert.ok(__test__.IMAGE_OUTPUT_JPEG_QUALITY >= 85);
  assert.deepEqual(request, {
    model: 'gpt-image-2',
    prompt: 'draw a friendly scene',
    size: '1024x1536',
    quality: 'high',
    output_format: 'jpeg',
    output_compression: 90,
    background: 'opaque',
  });
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

test('buildStoryPrompt includes story quality requirements', () => {
  const prompt = __test__.buildStoryPrompt({ prompt: 'Return JSON only.' });

  assert.match(prompt, /失敗/);
  assert.match(prompt, /意外な気づき/);
  assert.match(prompt, /小さな笑えるオチ/);
  assert.match(prompt, /4ページ/);
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

test('stringifyGeneratedStoryJson preserves the existing response shape', () => {
  const story = buildValidStory();
  const text = __test__.stringifyGeneratedStoryJson(JSON.stringify(story));
  const parsed = JSON.parse(text);

  assert.equal(typeof parsed.title, 'string');
  assert.equal(typeof parsed.coverScene, 'string');
  assert.equal(typeof parsed.characterSheet.protagonist, 'string');
  assert.equal(parsed.pages.length, 4);
  assert.deepEqual(Object.keys(parsed.pages[0]), [
    'story',
    'visualFocus',
    'mood',
    'dialogue',
    'visibleCast',
  ]);
});
