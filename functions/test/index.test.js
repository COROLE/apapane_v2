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
