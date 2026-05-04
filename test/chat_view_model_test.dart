import 'dart:async';

import 'package:apapane/models/auth/local_session_user.dart';
import 'package:apapane/models/purchase/purchase_entitlements.dart';
import 'package:apapane/models/story/story_generation_config.dart';
import 'package:apapane/models/story/story_generation_draft.dart';
import 'package:apapane/view_models/chat_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fallbackAnswers = [
    'あかいマフラーの うさぎ',
    'にじのもり',
    'ちいさなくま',
    'やさしいけど まけずぎらい',
  ];

  final structuredStory = <String, dynamic>{
    'title': '月のランタン',
    'coverScene': 'あかいマフラーの うさぎ が ちいさなくま と 光るランタンを かかげる',
    'characterSheet': {
      'protagonist':
          'small rabbit child, red scarf, cream fur, round face, bright curious eyes',
      'companion':
          'tiny bear friend, moss-green satchel, soft brown fur, calm smile',
      'worldDetails':
          'glowing night forest, moonlit mist, child-safe picture-book world',
      'artDirection':
          'gentle gouache picture book, warm pastel palette, soft paper texture',
    },
    'pages': [
      {
        'story': 'うさぎの ミオは にじのもりで 月のランタンを さがしに でかけた。',
        'visualFocus': 'ミオが 森の入口で ランタンを みあげる',
        'mood': 'あたたかく わくわく',
        'dialogue': 'きっと みつかるよ',
        'visibleCast': ['protagonist'],
      },
      {
        'story': 'でも まよいみちが あらわれ、くまの ポノも 足を とめた。',
        'visualFocus': '光る分かれ道の前で 考える ふたり',
        'mood': 'どきどき しずか',
        'dialogue': 'どっち かな',
        'visibleCast': ['protagonist', 'companion'],
      },
      {
        'story': 'そのとき 足元の しずくが 星の地図に かわり、かくしみちを てらした。',
        'visualFocus': '星の地図が 足元に ひらく 瞬間',
        'mood': 'ふしぎで きらきら',
        'dialogue': 'ここだ',
        'visibleCast': ['protagonist'],
      },
      {
        'story': 'ミオは ポノと いっしょに ランタンへ 手を のばし、帰り道まで 明るく てらした。',
        'visualFocus': 'ランタンを もち よろこぶ ふたり',
        'mood': 'ほっとして うれしい',
        'dialogue': 'できたね',
        'visibleCast': ['protagonist', 'companion'],
      },
    ],
  };

  test('structured story keeps the title out of body pages', () {
    final draft = ChatViewModel.storyDraftForTesting(
      structuredStory,
      fallbackAnswers: fallbackAnswers,
    );
    final pages = ChatViewModel.storyPagesForTesting(
      structuredStory,
      fallbackAnswers: fallbackAnswers,
    );

    expect(draft.title, '月のランタン');
    expect(pages, hasLength(4));
    expect(
      pages.map((page) => page['story']).contains('月のランタン'),
      isFalse,
    );
  });

  test('story modes expose page counts, costs, and standard recommendation',
      () {
    expect(StoryMode.mini.pageCount, 4);
    expect(StoryMode.mini.coinCost, 1);
    expect(StoryMode.standard.pageCount, 8);
    expect(StoryMode.standard.coinCost, 2);
    expect(StoryMode.standard.isRecommended, isTrue);
    expect(StoryMode.premium.pageCount, 12);
    expect(StoryMode.premium.coinCost, 3);
  });

  test('local preview fallback uses distinct beats for standard stories', () {
    final preview = ChatViewModel.localStoryPreviewForTesting(
      answers: const [
        'くま',
        'ふわふわぐものくに',
        'おしゃべりなどんぐり',
        'あきらめない',
      ],
      mode: StoryMode.standard,
      storyOptions: const StoryOptions(),
    );

    expect(preview.pagePlan, hasLength(8));
    expect(preview.pagePlan.toSet(), hasLength(8));
    expect(
      preview.pagePlan.where((entry) => entry.contains('ふしぎな出来事が広がり')).length,
      0,
    );
    expect(
      preview.pagePlan.where((entry) => entry.contains('一歩ずつ進む')).length,
      0,
    );
  });

  test('local story fallback uses distinct body text for long modes', () {
    for (final mode in [StoryMode.standard, StoryMode.premium]) {
      final draft = StoryGenerationComposer.fallbackDraft(
        answers: fallbackAnswers,
        mode: mode,
      );
      final stories = draft.pages.map((page) => page.story).toList();

      expect(stories, hasLength(mode.pageCount));
      expect(stories.toSet(), hasLength(mode.pageCount));
      expect(
        stories.where((story) => story.contains('ふたりの まえに ちいさな トラブル')).length,
        lessThanOrEqualTo(1),
      );
      expect(
        stories.where((story) => story.contains('ひみつの 手がかりを見つける')).length,
        0,
      );
    }
  });

  test('structured drafts keep 8 and 12 page responses', () {
    final standardStory = <String, dynamic>{
      ...structuredStory,
      'mode': 'standard',
      'pages': [
        for (var index = 0; index < 8; index += 1)
          {
            ...((structuredStory['pages'] as List)[index % 4]
                as Map<String, dynamic>),
            'story': '8ページ版 ${index + 1}',
          },
      ],
    };
    final premiumStory = <String, dynamic>{
      ...structuredStory,
      'mode': 'premium',
      'pages': [
        for (var index = 0; index < 12; index += 1)
          {
            ...((structuredStory['pages'] as List)[index % 4]
                as Map<String, dynamic>),
            'story': '12ページ版 ${index + 1}',
          },
      ],
    };

    expect(
      ChatViewModel.storyPagesForTesting(
        standardStory,
        fallbackAnswers: fallbackAnswers,
      ),
      hasLength(8),
    );
    expect(
      ChatViewModel.storyPagesForTesting(
        premiumStory,
        fallbackAnswers: fallbackAnswers,
      ),
      hasLength(12),
    );
  });

  test('visibleCast is parsed and missing values fall back safely', () {
    final draft = ChatViewModel.storyDraftForTesting(
      structuredStory,
      fallbackAnswers: fallbackAnswers,
    );

    final missingVisibleCastStory = <String, dynamic>{
      ...structuredStory,
      'pages': [
        {
          ...((structuredStory['pages'] as List).first as Map<String, dynamic>),
        }..remove('visibleCast'),
        ...((structuredStory['pages'] as List).skip(1)),
      ],
    };
    final fallbackDraft = ChatViewModel.storyDraftForTesting(
      missingVisibleCastStory,
      fallbackAnswers: fallbackAnswers,
    );

    expect(draft.pages.first.visibleCast, ['protagonist']);
    expect(
      fallbackDraft.pages.first.visibleCast,
      ['protagonist', 'companion'],
    );
  });

  test('image prompt front-loads the exact scene and no-text rules', () {
    final prompt = ChatViewModel.storyImagePromptForTesting(
      structuredStory,
      pageIndex: 0,
      fallbackAnswers: fallbackAnswers,
    );

    expect(prompt, contains('red scarf'));
    expect(prompt, contains('tiny bear friend'));
    expect(prompt, contains('MUST depict this exact scene:'));
    expect(
      prompt,
      contains('Visible characters for this image: protagonist.'),
    );
    expect(prompt, contains('No readable text'));
    expect(prompt, contains('speech bubbles'));
  });

  test('single-character pages keep absent cast off-screen', () {
    final prompt = ChatViewModel.storyImagePromptForTesting(
      structuredStory,
      pageIndex: 2,
      fallbackAnswers: fallbackAnswers,
    );

    expect(
      prompt,
      contains(
        'If a recurring character is not listed, keep them off-screen instead of replacing them.',
      ),
    );
    expect(prompt, contains('Companion: tiny bear friend'));
    expect(prompt, contains('Do not introduce unrelated main characters'));
  });

  test('story and page seeds are deterministic and page-specific', () {
    final storySeed = ChatViewModel.storySeedForTesting(
      structuredStory,
      fallbackAnswers: fallbackAnswers,
    );

    final firstPageSeed = ChatViewModel.pageSeedForTesting(storySeed, 0);
    final secondPageSeed = ChatViewModel.pageSeedForTesting(storySeed, 1);

    expect(
      ChatViewModel.storySeedForTesting(
        structuredStory,
        fallbackAnswers: fallbackAnswers,
      ),
      storySeed,
    );
    expect(ChatViewModel.pageSeedForTesting(storySeed, 0), firstPageSeed);
    expect(firstPageSeed, isNot(secondPageSeed));
  });

  test('story image validation finds pages without generated images', () {
    final missing = ChatViewModel.missingStoryImagePageIndexesForTesting(
      const [
        {'story': 'page 1', 'image': 'https://example.com/1.jpg'},
        {'story': 'page 2', 'image': ''},
        {'story': 'page 3', 'image': null},
        {'story': 'page 4', 'image': 'base64-data'},
      ],
    );

    expect(missing, [1, 2]);
  });

  test('legacy stored stories drop a duplicated title page', () {
    final normalizedPages = StoryGenerationComposer.normalizeStoredPages(
      rawPages: const [
        {'story': '月のランタン', 'image': null},
        {'story': '1ページめ', 'image': null},
        {'story': '2ページめ', 'image': null},
        {'story': '3ページめ', 'image': null},
        {'story': '4ページめ', 'image': null},
      ],
      titleText: '月のランタン',
    );

    expect(normalizedPages, hasLength(4));
    expect(normalizedPages.first['story'], '1ページめ');
  });

  test('story generation retry errors use app-facing copy', () {
    expect(
      ChatViewModel.errorMessageForTesting(
        Exception('読み込み回数の上限をこえました。'),
      ),
      'おはなしをうまく作れませんでした。コインは消費されません。もう一度お試しください。',
    );
    expect(
      ChatViewModel.errorMessageForTesting(
        StateError(
            'Generated story did not pass quality checks: story_quality'),
      ),
      'おはなしをうまく作れませんでした。コインは消費されません。もう一度お試しください。',
    );
    expect(
      ChatViewModel.errorMessageForTesting(
        TimeoutException('generateStory timed out.'),
      ),
      'おはなしをうまく作れませんでした。コインは消費されません。もう一度お試しください。',
    );
    expect(
      ChatViewModel.errorMessageForTesting(
        Exception('[firebase_functions/internal] invalid_story_json'),
      ),
      'おはなしをうまく作れませんでした。コインは消費されません。もう一度お試しください。',
    );
    expect(
      ChatViewModel.errorMessageForTesting(
        StateError(
          'generateStoryHttp failed (400): failed-precondition: '
          'The specified schema produces a constraint that has too many states for serving.',
        ),
      ),
      'おはなしをうまく作れませんでした。コインは消費されません。もう一度お試しください。',
    );
  });

  test('story resource exhausted errors use rate limit copy', () {
    expect(
      ChatViewModel.errorMessageForTesting(
        Exception(
          '[firebase_functions/resource-exhausted] '
          '生成リクエストが多すぎます。少し待ってからもう一度お試しください。',
        ),
      ),
      '生成リクエストが多すぎます。少し待ってからもう一度お試しください。',
    );
  });

  test('story fetch retry skips non-retryable callable errors', () {
    expect(
      ChatViewModel.shouldRetryStoryFetchErrorForTesting(
        TimeoutException('generateStory timed out.'),
      ),
      isTrue,
    );
    expect(
      ChatViewModel.shouldRetryStoryFetchErrorForTesting(
        const FormatException('invalid json'),
      ),
      isTrue,
    );
    expect(
      ChatViewModel.shouldRetryStoryFetchErrorForTesting(
        Exception('[firebase_functions/resource-exhausted] too many requests'),
      ),
      isFalse,
    );
    expect(
      ChatViewModel.shouldRetryStoryFetchErrorForTesting(
        Exception('[firebase_functions/unauthenticated] App Check required'),
      ),
      isFalse,
    );
  });

  test('story creation requires parent login for guests', () {
    final state = ChatViewModel.storyCreationAccessForTesting(
      currentUser: const LocalSessionUser(
        id: 'guest-1',
        email: '',
        displayName: 'ゲスト',
        photoUrl: '',
        isAnonymous: true,
      ),
      entitlements: PurchaseEntitlements.initial(),
    );

    expect(state, StoryCreationAccessState.loginRequired);
  });

  test('story creation requires purchase when signed-in user has no coins', () {
    final state = ChatViewModel.storyCreationAccessForTesting(
      currentUser: const LocalSessionUser(
        id: 'user-1',
        email: 'parent@example.com',
        displayName: 'Parent',
        photoUrl: '',
        isAnonymous: false,
      ),
      entitlements: PurchaseEntitlements.initial(),
    );

    expect(state, StoryCreationAccessState.purchaseRequired);
  });

  test('story creation is allowed for coin holders and subscribers', () {
    final coinState = ChatViewModel.storyCreationAccessForTesting(
      currentUser: const LocalSessionUser(
        id: 'user-1',
        email: 'parent@example.com',
        displayName: 'Parent',
        photoUrl: '',
        isAnonymous: false,
      ),
      entitlements: const PurchaseEntitlements(
        coins: 2,
        isSubscriptionActive: false,
        subscriptionEndAt: null,
      ),
    );
    final subscriptionState = ChatViewModel.storyCreationAccessForTesting(
      currentUser: const LocalSessionUser(
        id: 'user-2',
        email: 'subscriber@example.com',
        displayName: 'Subscriber',
        photoUrl: '',
        isAnonymous: false,
      ),
      entitlements: PurchaseEntitlements(
        coins: 0,
        isSubscriptionActive: true,
        subscriptionEndAt: DateTime(2030),
      ),
    );

    expect(coinState, StoryCreationAccessState.allowed);
    expect(subscriptionState, StoryCreationAccessState.allowed);
  });
}
