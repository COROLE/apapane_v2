import 'package:apapane/models/story/story_generation_draft.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    'storyCanon': {
      'title': 'Moon Lantern',
      'visualStyle': 'soft mobile story artwork',
      'worldRules': {
        'noReadableText': true,
        'noLetters': true,
        'noSigns': true,
        'noBooks': true,
        'noMaps': true,
        'noPaper': true,
        'magicIsShownAs': 'glowing petals and lantern light',
      },
      'cast': [
        {
          'id': 'protagonist',
          'name': 'Miko',
          'role': 'protagonist',
          'appearance': 'small rabbit child',
          'outfit': 'red scarf',
          'colors': ['cream', 'red'],
          'personalityVisualCues': 'curious eyes',
        },
      ],
      'setting': {
        'mainLocation': 'moonlit forest',
        'timeOfDay': 'night',
        'season': 'spring',
        'recurringVisualMotifs': ['glowing petals', 'soft mist'],
      },
      'pagePlans': [
        {
          'page': 1,
          'storyBeat': 'finds glow',
          'userTextIntent': 'short Japanese text',
          'visualBeat': 'rabbit follows glowing petals',
          'visibleCast': ['protagonist'],
          'characterPositions': 'rabbit in central area',
          'camera': 'medium shot',
          'lighting': 'soft moon light',
          'emotion': 'curious',
          'allowedObjects': ['glowing petals'],
          'forbiddenObjects': ['readable text'],
        },
      ],
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

  test('new-story recovery prompt prefers the transient draft prompt', () {
    final draft = StoryGenerationDraft.fromResponse(structuredStory);

    final recoveryPrompt = StoryViewModel.recoveryPromptForTesting(
      titleText: '月のランタン',
      sentence: 'うさぎだけが みえる ばめん',
      pageIndex: 0,
      newStoryDraft: draft,
    );
    final fallbackPrompt = StoryViewModel.recoveryPromptForTesting(
      titleText: '月のランタン',
      sentence: 'うさぎだけが みえる ばめん',
      pageIndex: 0,
    );

    expect(
      recoveryPrompt,
      contains(
        'Regenerate a story-matching image. Ignore any previous unrelated composition.',
      ),
    );
    expect(recoveryPrompt, contains('Companion: tiny bear friend'));
    expect(
      recoveryPrompt,
      contains(
        'If a recurring character is not listed, keep them off-screen instead of replacing them.',
      ),
    );
    expect(
      fallbackPrompt,
      contains('MUST depict this exact story scene: うさぎだけが みえる ばめん.'),
    );
    expect(
      fallbackPrompt,
      isNot(
        contains(
          'If a recurring character is not listed, keep them off-screen instead of replacing them.',
        ),
      ),
    );
  });

  test('StoryGenerationDraft parses optional StoryCanon metadata', () {
    final draft = StoryGenerationDraft.fromResponse(structuredStory);
    final legacyDraft = StoryGenerationDraft.fromResponse({
      ...structuredStory,
      'storyCanon': null,
    });

    expect(draft.storyCanon, isNotNull);
    expect(draft.storyCanon!.pagePlans, hasLength(1));
    expect(draft.storyCanon!.pagePlans.first.visualBeat, contains('petals'));
    expect(draft.storyCanon!.toJson(), contains('pagePlans'));
    expect(legacyDraft.storyCanon, isNull);
  });
}
