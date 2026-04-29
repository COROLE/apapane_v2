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
      'Picture-book style: hand-painted gouache and watercolor, rounded shapes, soft pastel palette, cozy lighting, gentle expressions, vertical 9:16 illustration.',
      'Keep the same character designs, face shapes, body proportions, clothing, accessories, colors, and brush texture across every page.',
      'Protagonist: ${_promptClip(draft.characterSheet.protagonist)}.',
      if (draft.characterSheet.companion.isNotEmpty)
        'Companion: ${_promptClip(draft.characterSheet.companion)}.',
      if (draft.characterSheet.worldDetails.isNotEmpty)
        'World: ${_promptClip(draft.characterSheet.worldDetails)}.',
      if (draft.characterSheet.artDirection.isNotEmpty)
        'Art direction: ${_promptClip(draft.characterSheet.artDirection)}.',
    ];
    return parts.join('\n');
  }

  static String buildCharacterLock({required StoryGenerationDraft draft}) {
    return [
      'Fixed cast: the protagonist and companion are the only recurring main characters.',
      'Keep the protagonist identical: same species, face shape, body type, outfit, colors, accessories, and age impression.',
      if (draft.characterSheet.companion.isNotEmpty)
        'Keep the companion identical: same species, face shape, body type, outfit, colors, accessories, and age impression.',
      'Do not introduce unrelated main characters, replacement animals, or redesigned substitutes.',
    ].join('\n');
  }

  static String buildPageCastRules({required StoryGenerationPage page}) {
    final visibleCast = page.visibleCast.toSet();
    final visibleCharacters = <String>[
      if (visibleCast.isEmpty || visibleCast.contains(_protagonistCastRole))
        'protagonist',
      if (visibleCast.isEmpty || visibleCast.contains(_companionCastRole))
        'companion',
    ];
    if (visibleCharacters.isEmpty) {
      return 'Visible characters: focus on the setting and story props; do not invent a replacement main character.';
    }
    return [
      'Visible characters for this image: ${visibleCharacters.join(', ')}.',
      'If a recurring character is not listed, keep them off-screen instead of replacing them.',
    ].join('\n');
  }

  static String buildCoverImagePrompt({
    required StoryGenerationDraft draft,
  }) {
    return [
      'Create exactly one front cover illustration for the story title "${_promptClip(draft.title, maxLength: 120)}".',
      if (draft.coverScene.isNotEmpty)
        'MUST depict this cover scene: ${_promptClip(draft.coverScene, maxLength: 520)}.',
      buildStyleGuide(draft: draft),
      buildCharacterLock(draft: draft),
      'Visible characters for this image: protagonist, companion.',
      'Composition: one clear focal action, characters large and recognizable, background supports the exact story world.',
      'No readable text, captions, speech bubbles, signs, logos, watermarks, letters, or numbers.',
    ].join('\n');
  }

  static String buildPageImagePrompt({
    required StoryGenerationDraft draft,
    required int pageIndex,
  }) {
    final page = draft.pages[pageIndex];
    final exactScene = _firstNonEmpty(page.visualFocus, page.story);
    return [
      'Create exactly one illustration for body page ${pageIndex + 1} of ${draft.pages.length}.',
      'MUST depict this exact scene: ${_promptClip(exactScene, maxLength: 560)}.',
      buildStyleGuide(draft: draft),
      buildCharacterLock(draft: draft),
      buildPageCastRules(page: page),
      if (page.story.isNotEmpty)
        'Story context only: ${_promptClip(page.story, maxLength: 260)}.',
      if (page.mood.isNotEmpty)
        'Mood: ${_promptClip(page.mood, maxLength: 120)}.',
      if (page.dialogue.isNotEmpty)
        'Show the emotion of the spoken line without drawing any words.',
      'Composition: one clear focal action, characters large and recognizable, background supports the exact scene.',
      'No readable text, captions, speech bubbles, signs, logos, watermarks, letters, or numbers.',
    ].join('\n');
  }

  static String buildRetryImagePrompt({
    required StoryGenerationDraft draft,
    required int pageIndex,
  }) {
    final page = draft.pages[pageIndex];
    final exactScene = _firstNonEmpty(page.visualFocus, page.story);
    return [
      'Regenerate a story-matching image. Ignore any previous unrelated composition.',
      'MUST match this exact scene: ${_promptClip(exactScene, maxLength: 560)}.',
      buildStyleGuide(draft: draft),
      buildCharacterLock(draft: draft),
      buildPageCastRules(page: page),
      if (page.story.isNotEmpty)
        'Story context only: ${_promptClip(page.story, maxLength: 260)}.',
      'Use a clean picture-book composition with a strong silhouette and simple layered depth.',
      'Keep every visible character design identical to the rest of the story.',
      'Absolutely no readable text, letters, numbers, subtitles, captions, speech bubbles, street signs, logos, watermarks, or book pages with writing.',
    ].join('\n');
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

String _promptClip(String value, {int maxLength = 420}) {
  final normalized = _normalizeText(value);
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return normalized.substring(0, maxLength);
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
