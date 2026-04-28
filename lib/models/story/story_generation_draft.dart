import 'package:apapane/typedefs/firestore_typedef.dart';
import 'package:apapane/models/story/story_generation_config.dart';

const String _protagonistCastRole = 'protagonist';
const String _companionCastRole = 'companion';
const List<String> _allVisibleCast = [
  _protagonistCastRole,
  _companionCastRole,
];

class StoryGenerationCharacterSheet {
  const StoryGenerationCharacterSheet({
    required this.protagonist,
    required this.companion,
    required this.worldDetails,
    required this.artDirection,
  });

  final String protagonist;
  final String companion;
  final String worldDetails;
  final String artDirection;

  factory StoryGenerationCharacterSheet.fromJson(Object? json) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};
    return StoryGenerationCharacterSheet(
      protagonist: _normalizeText(map['protagonist']),
      companion: _normalizeText(map['companion']),
      worldDetails: _normalizeText(map['worldDetails']),
      artDirection: _normalizeText(map['artDirection']),
    );
  }

  StoryGenerationCharacterSheet merge(StoryGenerationCharacterSheet fallback) {
    return StoryGenerationCharacterSheet(
      protagonist: _firstNonEmpty(protagonist, fallback.protagonist),
      companion: _firstNonEmpty(companion, fallback.companion),
      worldDetails: _firstNonEmpty(worldDetails, fallback.worldDetails),
      artDirection: _firstNonEmpty(artDirection, fallback.artDirection),
    );
  }
}

class StoryGenerationPage {
  const StoryGenerationPage({
    required this.story,
    required this.visualFocus,
    required this.mood,
    required this.dialogue,
    required this.visibleCast,
  });

  final String story;
  final String visualFocus;
  final String mood;
  final String dialogue;
  final List<String> visibleCast;

  factory StoryGenerationPage.fromJson(Object? json) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};
    return StoryGenerationPage(
      story: _normalizeText(map['story']),
      visualFocus: _normalizeText(map['visualFocus']),
      mood: _normalizeText(map['mood']),
      dialogue: _normalizeText(map['dialogue']),
      visibleCast: _normalizeVisibleCast(map['visibleCast']),
    );
  }

  StoryGenerationPage merge(StoryGenerationPage fallback) {
    return StoryGenerationPage(
      story: _firstNonEmpty(story, fallback.story),
      visualFocus: _firstNonEmpty(visualFocus, fallback.visualFocus),
      mood: _firstNonEmpty(mood, fallback.mood),
      dialogue: _firstNonEmpty(dialogue, fallback.dialogue),
      visibleCast: visibleCast.isNotEmpty ? visibleCast : fallback.visibleCast,
    );
  }
}

class StoryGenerationDraft {
  static const int legacyBodyPageCount = 4;

  const StoryGenerationDraft({
    required this.title,
    required this.coverScene,
    required this.characterSheet,
    required this.pages,
  });

  final String title;
  final String coverScene;
  final StoryGenerationCharacterSheet characterSheet;
  final List<StoryGenerationPage> pages;

  factory StoryGenerationDraft.fromResponse(
    SDMap response, {
    List<String> fallbackAnswers = const [],
    StoryMode mode = StoryMode.mini,
    int? pageCount,
  }) {
    final parsedMode = storyModeFromKey(response['mode']?.toString());
    final resolvedMode = response['mode'] == null ? mode : parsedMode;
    final fallbackDraft = StoryGenerationComposer.fallbackDraft(
      answers: fallbackAnswers,
      mode: resolvedMode,
      pageCount: pageCount,
    );

    final parsedPages = response['pages'] is List
        ? (response['pages'] as List<dynamic>)
            .map(StoryGenerationPage.fromJson)
            .where((page) => page.story.isNotEmpty)
            .toList(growable: false)
        : _legacyPagesFromResponse(response);

    final resolvedPageCount = pageCount ??
        (parsedPages.length > resolvedMode.pageCount
            ? parsedPages.length
            : resolvedMode.pageCount);
    final pages = List<StoryGenerationPage>.generate(
      resolvedPageCount,
      (index) {
        final fallbackPage = fallbackDraft.pages[
            index < fallbackDraft.pages.length
                ? index
                : fallbackDraft.pages.length - 1];
        if (index >= parsedPages.length) {
          return fallbackPage;
        }
        return parsedPages[index].merge(fallbackPage);
      },
      growable: false,
    );

    return StoryGenerationDraft(
      title: _firstNonEmpty(
        _normalizeText(response['title']),
        fallbackDraft.title,
      ),
      coverScene: _firstNonEmpty(
        _normalizeText(response['coverScene']),
        fallbackDraft.coverScene,
      ),
      characterSheet:
          StoryGenerationCharacterSheet.fromJson(response['characterSheet'])
              .merge(fallbackDraft.characterSheet),
      pages: pages,
    );
  }
}

class StoryGenerationComposer {
  static StoryGenerationDraft fallbackDraft({
    required List<String> answers,
    StoryMode mode = StoryMode.mini,
    int? pageCount,
  }) {
    final protagonist = _answerAt(
      answers,
      0,
      fallback: 'やさしい ぼうけんか',
    );
    final place = _answerAt(
      answers,
      1,
      fallback: 'ひみつの もり',
    );
    final companion = _answerAt(
      answers,
      2,
      fallback: 'たよりに なる なかま',
    );
    final specialDetail = _answerAt(
      answers,
      3,
      fallback: 'まっすぐで ゆうきが ある',
    );

    final resolvedPageCount = pageCount ?? mode.pageCount;
    return StoryGenerationDraft(
      title: '$protagonistの ぼうけん',
      coverScene: '$protagonist が $place で $companion と たびの いっぽを ふみだす しゅんかん',
      characterSheet: StoryGenerationCharacterSheet(
        protagonist: '$protagonist。丸いシルエット、わかりやすい服、見てすぐ覚えられる色づかい。',
        companion: '$companion。主人公と並んだときに見分けやすい形と色。',
        worldDetails: '$place。子ども向け絵本らしい、やわらかい色と安心できる景色。',
        artDirection: '$specialDetail。やさしい絵本タッチ、手描き感、あたたかい空気。',
      ),
      pages: List<StoryGenerationPage>.generate(
        resolvedPageCount,
        (index) => _fallbackPage(
          index: index,
          pageCount: resolvedPageCount,
          protagonist: protagonist,
          place: place,
          companion: companion,
          specialDetail: specialDetail,
        ),
        growable: false,
      ),
    );
  }

  static List<SDMap> storyPagesFromDraft(StoryGenerationDraft draft) {
    return draft.pages
        .map(
          (page) => <String, dynamic>{
            'story': page.story,
            'image': null,
          },
        )
        .toList(growable: false);
  }

  static String buildStyleGuide({required StoryGenerationDraft draft}) {
    final parts = <String>[
      'Series art bible: Japanese children picture-book illustration, hand-painted gouache watercolor texture, rounded shapes, soft pastel palette, cozy lighting, gentle expressions, vertical 9:16 layout.',
      'Keep the same illustration genre, brush texture, face design, body proportions, costume details, and palette on every page of the same story.',
      'Protagonist design: ${draft.characterSheet.protagonist}.',
      if (draft.characterSheet.companion.isNotEmpty)
        'Companion design: ${draft.characterSheet.companion}.',
      if (draft.characterSheet.worldDetails.isNotEmpty)
        'World details: ${draft.characterSheet.worldDetails}.',
      if (draft.characterSheet.artDirection.isNotEmpty)
        'Extra art direction: ${draft.characterSheet.artDirection}.',
      if (draft.coverScene.isNotEmpty) 'Cover motif: ${draft.coverScene}.',
    ];
    return parts.join(' ');
  }

  static String buildCharacterLock({required StoryGenerationDraft draft}) {
    return [
      'Fixed cast bible: the recurring cast contains only the protagonist and the companion.',
      'Keep the protagonist identical across the whole story: same species, face shape, body type, outfit, colors, accessories, and age impression.',
      if (draft.characterSheet.companion.isNotEmpty)
        'Keep the companion identical across the whole story: same species, face shape, body type, outfit, colors, accessories, and age impression.',
      'Never replace either main character with a new animal, new child, new helper, or a redesigned substitute.',
      'If a main character is off-screen for one page, keep them absent instead of inventing a stand-in.',
      'When a main character returns, restore the exact same design as earlier pages.',
    ].join(' ');
  }

  static String buildPageCastRules({required StoryGenerationPage page}) {
    final visibleCast = page.visibleCast.toSet();
    return [
      if (visibleCast.contains(_protagonistCastRole))
        'Draw the protagonist on-screen in this page.'
      else
        'The protagonist stays off-screen in this page. Do not replace the protagonist with another visible character.',
      if (visibleCast.contains(_companionCastRole))
        'Draw the companion on-screen in this page.'
      else
        'The companion stays off-screen in this page. Do not replace the companion with another visible character.',
      'Do not add a new recurring sidekick or extra hero to fill a missing cast role.',
    ].join(' ');
  }

  static String buildCoverImagePrompt({
    required StoryGenerationDraft draft,
  }) {
    return [
      buildStyleGuide(draft: draft),
      buildCharacterLock(draft: draft),
      'Front cover illustration for the story title "${draft.title}".',
      'Scene: ${draft.coverScene}.',
      'Draw both the protagonist and the companion on-screen for the cover.',
      'Single clear focal point, readable silhouette, warm child-safe composition.',
      'No readable text anywhere in the image. No letters, subtitles, captions, speech bubbles, signs, logos, or watermarks.',
    ].join(' ');
  }

  static String buildPageImagePrompt({
    required StoryGenerationDraft draft,
    required int pageIndex,
  }) {
    final page = draft.pages[pageIndex];
    return [
      buildStyleGuide(draft: draft),
      buildCharacterLock(draft: draft),
      buildPageCastRules(page: page),
      'Illustrate body page ${pageIndex + 1} of ${draft.pages.length}.',
      'Story beat: ${page.story}.',
      if (page.visualFocus.isNotEmpty) 'Visual focus: ${page.visualFocus}.',
      if (page.mood.isNotEmpty) 'Mood: ${page.mood}.',
      if (page.dialogue.isNotEmpty)
        'The feeling of the spoken line "${page.dialogue}" should be visible in expression and pose, but do not draw the words.',
      'Single illustration, child-safe, simple background shapes when needed, one coherent moment.',
      'No readable text anywhere in the image. No letters, subtitles, captions, speech bubbles, signs, logos, or watermarks.',
    ].join(' ');
  }

  static String buildRetryImagePrompt({
    required StoryGenerationDraft draft,
    required int pageIndex,
  }) {
    final page = draft.pages[pageIndex];
    return [
      buildStyleGuide(draft: draft),
      buildCharacterLock(draft: draft),
      buildPageCastRules(page: page),
      'Retry the same story illustration with extra consistency and clarity.',
      'Story beat: ${page.story}.',
      if (page.visualFocus.isNotEmpty) 'Visual focus: ${page.visualFocus}.',
      'Use a clean picture-book composition with a strong silhouette and simple layered depth.',
      'Keep every visible character design identical to the rest of the story.',
      'Absolutely no readable text, letters, numbers, subtitles, captions, speech bubbles, street signs, logos, watermarks, or book pages with writing.',
    ].join(' ');
  }

  static int buildStorySeed({
    required StoryGenerationDraft draft,
    List<String> fallbackAnswers = const [],
  }) {
    final seedSource = [
      draft.title,
      draft.coverScene,
      draft.characterSheet.protagonist,
      draft.characterSheet.companion,
      draft.characterSheet.worldDetails,
      draft.characterSheet.artDirection,
      ...draft.pages.map(
        (page) => '${page.story}|${page.visibleCast.join(",")}',
      ),
      ...fallbackAnswers,
    ].join('|');

    var hash = 17;
    for (final codeUnit in seedSource.codeUnits) {
      hash = 37 * hash + codeUnit;
    }

    final normalized = hash & 0x7fffffff;
    return normalized == 0 ? 1 : normalized;
  }

  static int buildPageSeed({
    required int storySeed,
    required int pageIndex,
  }) {
    final normalized = (storySeed + ((pageIndex + 1) * 7919)) & 0x7fffffff;
    return normalized == 0 ? pageIndex + 1 : normalized;
  }

  static List<SDMap> normalizeStoredPages({
    required List<dynamic> rawPages,
    required String titleText,
  }) {
    final normalizedTitle = _comparisonKey(titleText);
    final pages = rawPages
        .whereType<Map>()
        .map((page) => Map<String, dynamic>.from(page))
        .toList(growable: true);

    if (pages.length > 1 && normalizedTitle.isNotEmpty) {
      final firstStory = _comparisonKey(pages.first['story']);
      if (firstStory == normalizedTitle) {
        pages.removeAt(0);
      }
    }

    return pages;
  }
}

StoryGenerationPage _fallbackPage({
  required int index,
  required int pageCount,
  required String protagonist,
  required String place,
  required String companion,
  required String specialDetail,
}) {
  if (index == 0) {
    return StoryGenerationPage(
      story: '$protagonist は $place に つくと、$companion と いっしょに '
          'きょうの ぼうけんを はじめた。「いってみよう」と えがおで すすんだ。',
      visualFocus: '$protagonist と $companion が $place の入口に立つ場面',
      mood: 'わくわくして あたたかい',
      dialogue: 'いってみよう',
      visibleCast: _allVisibleCast,
    );
  }
  if (index == pageCount - 1) {
    return StoryGenerationPage(
      story: '$protagonist は $companion と 力をあわせて、さいごまで やりとげた。'
          '帰るころには、はじめよりも もっと じしんにみちた 顔に なっていた。',
      visualFocus: 'ぼうけんをやりとげて よろこぶ ふたり',
      mood: '達成感があって やさしい',
      dialogue: 'できたね',
      visibleCast: _allVisibleCast,
    );
  }
  if (index < pageCount / 2) {
    return StoryGenerationPage(
      story: 'ふたりの まえに ちいさな トラブルが あらわれた。'
          'でも $protagonist は $specialDetail ところを 思いだし、あわてずに まわりを見た。',
      visualFocus: '$protagonist が 困りごとを見つめて 考える場面',
      mood: 'どきどきするが 前向き',
      dialogue: 'だいじょうぶ、きっと みつかるよ',
      visibleCast: _allVisibleCast,
    );
  }
  return StoryGenerationPage(
    story: '$companion が ひみつの 手がかりを見つけると、景色の見え方が くるりと変わった。'
        '思っていたよりも やさしい 答えが その先に かくれていた。',
    visualFocus: 'ひみつの手がかりを見つけて 景色がひらく場面',
    mood: 'ふしぎで きらきら',
    dialogue: 'こんな ところに あったんだ',
    visibleCast: _allVisibleCast,
  );
}

List<StoryGenerationPage> _legacyPagesFromResponse(SDMap response) {
  const orderedKeys = [
    'introduction',
    'development',
    'turn',
    'conclusion',
  ];

  return orderedKeys
      .map(
        (key) => StoryGenerationPage(
          story: _normalizeText(response[key]),
          visualFocus: _normalizeText(response[key]),
          mood: '',
          dialogue: '',
          visibleCast: _allVisibleCast,
        ),
      )
      .where((page) => page.story.isNotEmpty)
      .toList(growable: false);
}

String _answerAt(List<String> answers, int index, {required String fallback}) {
  if (index >= 0 && index < answers.length) {
    final answer = _normalizeText(answers[index]);
    if (answer.isNotEmpty) {
      return answer;
    }
  }
  return fallback;
}

String _firstNonEmpty(String primary, String fallback) {
  return primary.isNotEmpty ? primary : fallback;
}

String _normalizeText(Object? value) {
  return value is String ? value.replaceAll(RegExp(r'\s+'), ' ').trim() : '';
}

List<String> _normalizeVisibleCast(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  final normalized = <String>[];
  for (final entry in value) {
    if (entry is! String) {
      continue;
    }

    final castRole = _normalizeText(entry).toLowerCase();
    if ((castRole == _protagonistCastRole || castRole == _companionCastRole) &&
        !normalized.contains(castRole)) {
      normalized.add(castRole);
    }
  }

  return List<String>.unmodifiable(normalized);
}

String _comparisonKey(Object? value) {
  return _normalizeText(value).toLowerCase();
}
