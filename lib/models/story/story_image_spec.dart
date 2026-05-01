import 'package:apapane/models/story/story_generation_draft.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';

const String defaultStoryImageStyle =
    "Soft children's illustration, warm pastel color palette, gentle lighting, "
    'clean composition, simple clear shapes, cute and friendly characters, '
    'polished and cohesive, high-quality mobile artwork.';

const List<String> defaultStoryImageForbiddenTextSurfaces = [
  'text',
  'letters',
  'numbers',
  'symbols',
  'typography',
  'fake text',
  'pseudo-English',
  'pseudo-Chinese',
  'handwriting',
  'title',
  'subtitle',
  'caption',
  'captions',
  'dialogue',
  'narration',
  'speech bubble',
  'speech bubbles',
  'thought bubble',
  'thought bubbles',
  'text box',
  'scroll',
  'note',
  'letter',
  'card with writing',
  'book with writing',
  'title text',
  'labels',
  'label',
  'logos',
  'logo',
  'signs',
  'sign',
  'signboard',
  'posters',
  'poster',
  'banners',
  'banner',
  'book covers with writing',
  'newspapers',
  'newspaper',
  'maps',
  'map',
  'blackboards',
  'blackboard',
  'screens',
  'screen',
  'product packages',
  'product package',
  'name tags',
  'name tag',
  'title cards',
  'title card',
  'watermark-like marks',
  'watermark',
];

const List<String> defaultStoryImageAvoidTerms = [
  ...defaultStoryImageForbiddenTextSurfaces,
  'scary expression',
  'horror mood',
  'dark atmosphere',
  'cluttered background',
  'blank background',
  'plain white background',
  'empty background',
  'transparent background',
  'studio background',
  'gradient background',
  'distorted hands',
  'distorted limbs',
  'extra fingers',
  'malformed body parts',
  'blurry face',
  'overly realistic texture',
];

class StoryImageCharacterProfile {
  const StoryImageCharacterProfile({
    required this.name,
    required this.appearance,
    required this.clothing,
    required this.colors,
    required this.expressionStyle,
    required this.personalityTone,
    required this.worldStyle,
  });

  final String name;
  final String appearance;
  final String clothing;
  final String colors;
  final String expressionStyle;
  final String personalityTone;
  final String worldStyle;

  factory StoryImageCharacterProfile.fromJson(
    Object? json, {
    StoryImageCharacterProfile? fallback,
  }) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};
    final base = fallback ?? StoryImageCharacterProfile.fallback();
    return StoryImageCharacterProfile(
      name: _firstText([map['name'], base.name, 'Main character']),
      appearance: _firstText([
        map['appearance'],
        base.appearance,
        'A cute, friendly main character with rounded shapes.',
      ]),
      clothing: _firstText([
        map['clothing'],
        base.clothing,
        'Simple consistent clothing.',
      ]),
      colors: _firstText([map['colors'], base.colors, 'Warm pastel colors.']),
      expressionStyle: _firstText([
        map['expressionStyle'],
        base.expressionStyle,
        'Gentle, clear expressions.',
      ]),
      personalityTone: _firstText([
        map['personalityTone'],
        base.personalityTone,
        'Kind, curious, and friendly.',
      ]),
      worldStyle: _firstText([
        map['worldStyle'],
        base.worldStyle,
        "A safe, warm children's colorful world.",
      ]),
    );
  }

  factory StoryImageCharacterProfile.fallback({
    StoryGenerationDraft? draft,
  }) {
    return StoryImageCharacterProfile(
      name: _firstText([draft?.title, 'Main character']),
      appearance: _firstText([
        draft?.characterSheet.protagonist,
        'A cute, friendly main character with a rounded soft design.',
      ]),
      clothing:
          'Simple child-friendly clothing or accessories that stay consistent on every page.',
      colors: _firstText([
        draft?.characterSheet.artDirection,
        'Warm pastel colors with clear character colors.',
      ]),
      expressionStyle:
          'Gentle, clear facial expressions with bright curious eyes.',
      personalityTone:
          'Kind, curious, brave in a gentle way, friendly for young children.',
      worldStyle: _firstText([
        draft?.characterSheet.worldDetails,
        "A safe, warm, simple children's colorful world.",
      ]),
    );
  }

  SDMap toJson() => {
        'name': name,
        'appearance': appearance,
        'clothing': clothing,
        'colors': colors,
        'expressionStyle': expressionStyle,
        'personalityTone': personalityTone,
        'worldStyle': worldStyle,
      };
}

class StoryImagePageSpec {
  const StoryImagePageSpec({
    required this.page,
    required this.sceneGoal,
    required this.mainCharacterDescription,
    required this.supportingCharacters,
    required this.sceneDescription,
    required this.composition,
    required this.emotion,
    required this.backgroundDescription,
    required this.environmentDescription,
    required this.foregroundElements,
    required this.midgroundElements,
    required this.backgroundElements,
    required this.backgroundMustFillCanvas,
    required this.wordlessMode,
    required this.forbiddenTextSurfaces,
    required this.style,
    required this.avoid,
  });

  final int page;
  final String sceneGoal;
  final String mainCharacterDescription;
  final String supportingCharacters;
  final String sceneDescription;
  final String composition;
  final String emotion;
  final String backgroundDescription;
  final String environmentDescription;
  final List<String> foregroundElements;
  final List<String> midgroundElements;
  final List<String> backgroundElements;
  final bool backgroundMustFillCanvas;
  final bool wordlessMode;
  final List<String> forbiddenTextSurfaces;
  final String style;
  final List<String> avoid;

  factory StoryImagePageSpec.fromJson(
    Object? json, {
    required int page,
    StoryImageCharacterProfile? characterProfile,
    StoryImagePageSpec? fallback,
  }) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};
    final profile = characterProfile ?? StoryImageCharacterProfile.fallback();
    final base = fallback ??
        StoryImagePageSpec.fallback(
          page: page,
          pageSummary: '',
          characterProfile: profile,
        );
    final normalizedAvoid = _avoidTerms(map['avoid'], fallback: base.avoid);
    return StoryImagePageSpec(
      page: map['page'] is int && (map['page'] as int) > 0
          ? map['page'] as int
          : page,
      sceneGoal: _firstText([
        map['sceneGoal'],
        base.sceneGoal,
        'Show a clear warm story moment.',
      ]),
      mainCharacterDescription: _firstText([
        map['mainCharacterDescription'],
        base.mainCharacterDescription,
        '${profile.appearance} ${profile.clothing} ${profile.colors}',
      ]),
      supportingCharacters: _firstText([
        map['supportingCharacters'],
        base.supportingCharacters,
        'None.',
      ]),
      sceneDescription: _firstText([
        map['sceneDescription'],
        base.sceneDescription,
        map['sceneGoal'],
        base.sceneGoal,
      ]),
      composition: _firstText([
        map['composition'],
        base.composition,
        'Full-frame composition, clear focal action, simple open scenery.',
      ]),
      emotion: _firstText([
        map['emotion'],
        base.emotion,
        'Warm, friendly, gentle, and easy to read.',
      ]),
      backgroundDescription: _firstText([
        map['backgroundDescription'],
        base.backgroundDescription,
        map['environmentDescription'],
        base.environmentDescription,
        'Complete edge-to-edge colorful environment with gentle setting details.',
      ]),
      environmentDescription: _firstText([
        map['environmentDescription'],
        base.environmentDescription,
        map['backgroundDescription'],
        base.backgroundDescription,
        profile.worldStyle,
        'A complete wordless colorful environment filling the whole canvas.',
      ]),
      foregroundElements: _stringList(
        map['foregroundElements'],
        fallback: base.foregroundElements,
        defaults: const [
          'main character clearly visible',
          'one simple story-relevant action',
        ],
      ),
      midgroundElements: _stringList(
        map['midgroundElements'],
        fallback: base.midgroundElements,
        defaults: const [
          'simple story path or floor plane',
          'plain decorative objects',
        ],
      ),
      backgroundElements: _stringList(
        map['backgroundElements'],
        fallback: base.backgroundElements,
        defaults: const [
          'soft wordless environment details',
          'gentle color shapes filling every edge',
        ],
      ),
      backgroundMustFillCanvas: _boolValue(
        map['backgroundMustFillCanvas'],
        fallback: base.backgroundMustFillCanvas,
        defaultValue: true,
      ),
      wordlessMode: _boolValue(
        map['wordlessMode'],
        fallback: base.wordlessMode,
        defaultValue: true,
      ),
      forbiddenTextSurfaces: _forbiddenTextSurfaces(
        map['forbiddenTextSurfaces'],
        fallback: base.forbiddenTextSurfaces,
      ),
      style: _firstText([map['style'], base.style, defaultStoryImageStyle]),
      avoid: normalizedAvoid,
    );
  }

  factory StoryImagePageSpec.fallback({
    required int page,
    required String pageSummary,
    String story = '',
    String visualFocus = '',
    String mood = '',
    String supportingCharacters = '',
    StoryImageCharacterProfile? characterProfile,
  }) {
    final profile = characterProfile ?? StoryImageCharacterProfile.fallback();
    final sceneGoal = _firstText([
      pageSummary,
      visualFocus,
      story,
      'Show a clear warm story moment.',
    ]);
    return StoryImagePageSpec(
      page: page,
      sceneGoal: sceneGoal,
      mainCharacterDescription:
          '${profile.appearance} ${profile.clothing} ${profile.colors}',
      supportingCharacters: _firstText([supportingCharacters, 'None.']),
      sceneDescription: sceneGoal,
      composition:
          'Full-frame composition with the main character large and clear in the central area, one simple focal action, and calm open scenery.',
      emotion: _firstText([mood, 'Warm, gentle, curious, safe, and friendly.']),
      backgroundDescription:
          'A complete edge-to-edge colorful setting with soft shapes and gentle details.',
      environmentDescription: [
        profile.worldStyle,
        'Complete colorful environment filling the whole vertical canvas.',
      ].where((entry) => entry.trim().isNotEmpty).join(' '),
      foregroundElements: [
        'main character clearly visible',
        _firstText([visualFocus, pageSummary, 'one simple story action']),
      ],
      midgroundElements: const [
        'simple path or floor shape',
        'story-relevant plain decorative objects',
      ],
      backgroundElements: const [
        'soft trees, clouds, hills, stars, furniture, or other wordless setting details',
        'gentle color shapes filling the image edges',
      ],
      backgroundMustFillCanvas: true,
      wordlessMode: true,
      forbiddenTextSurfaces: defaultStoryImageForbiddenTextSurfaces,
      style: defaultStoryImageStyle,
      avoid: defaultStoryImageAvoidTerms,
    );
  }

  SDMap toJson() => {
        'page': page,
        'sceneGoal': sceneGoal,
        'mainCharacterDescription': mainCharacterDescription,
        'supportingCharacters': supportingCharacters,
        'sceneDescription': sceneDescription,
        'composition': composition,
        'emotion': emotion,
        'backgroundDescription': backgroundDescription,
        'environmentDescription': environmentDescription,
        'foregroundElements': foregroundElements,
        'midgroundElements': midgroundElements,
        'backgroundElements': backgroundElements,
        'backgroundMustFillCanvas': backgroundMustFillCanvas,
        'wordlessMode': wordlessMode,
        'forbiddenTextSurfaces': forbiddenTextSurfaces,
        'style': style,
        'avoid': avoid,
      };
}

class StoryImageSpecPackage {
  const StoryImageSpecPackage({
    required this.characterProfile,
    required this.imagePageSpecs,
  });

  final StoryImageCharacterProfile characterProfile;
  final List<StoryImagePageSpec> imagePageSpecs;

  factory StoryImageSpecPackage.fromJson(
    Object? json, {
    required StoryImageCharacterProfile fallbackProfile,
    required List<StoryImagePageSpec> fallbackSpecs,
  }) {
    final map = json is Map
        ? Map<String, dynamic>.from(json)
        : const <String, dynamic>{};
    final profile = StoryImageCharacterProfile.fromJson(
      map['characterProfile'],
      fallback: fallbackProfile,
    );
    final rawSpecs = map['imagePageSpecs'] is List
        ? map['imagePageSpecs'] as List<dynamic>
        : const <dynamic>[];
    final specs = <StoryImagePageSpec>[];
    for (var index = 0; index < fallbackSpecs.length; index += 1) {
      final page = index + 1;
      final rawSpec = rawSpecs.cast<dynamic>().firstWhere(
            (entry) => entry is Map && entry['page'] == page,
            orElse: () => index < rawSpecs.length ? rawSpecs[index] : null,
          );
      specs.add(
        StoryImagePageSpec.fromJson(
          rawSpec,
          page: page,
          characterProfile: profile,
          fallback: fallbackSpecs[index],
        ),
      );
    }
    return StoryImageSpecPackage(
      characterProfile: profile,
      imagePageSpecs: specs,
    );
  }
}

String _text(Object? value) {
  return value is String ? value.replaceAll(RegExp(r'\s+'), ' ').trim() : '';
}

String _firstText(List<Object?> values) {
  for (final value in values) {
    final text = _text(value);
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

List<String> _avoidTerms(Object? value, {List<String> fallback = const []}) {
  final rawTerms = value is List
      ? value
      : fallback.isNotEmpty
          ? fallback
          : defaultStoryImageAvoidTerms;
  final terms = <String>[];
  for (final term in rawTerms) {
    final text = _text(term);
    if (text.isNotEmpty && !terms.contains(text)) {
      terms.add(text);
    }
  }
  for (final term in defaultStoryImageForbiddenTextSurfaces) {
    if (!terms.contains(term)) {
      terms.add(term);
    }
  }
  for (final term in defaultStoryImageAvoidTerms) {
    if (!terms.contains(term)) {
      terms.add(term);
    }
  }
  return List<String>.unmodifiable(terms);
}

List<String> _stringList(
  Object? value, {
  List<String> fallback = const [],
  List<String> defaults = const [],
}) {
  final rawTerms = value is List
      ? value
      : fallback.isNotEmpty
          ? fallback
          : defaults;
  final terms = <String>[];
  for (final term in rawTerms) {
    final text = _text(term);
    if (text.isNotEmpty && !terms.contains(text)) {
      terms.add(text);
    }
  }
  for (final term in defaults) {
    if (!terms.contains(term)) {
      terms.add(term);
    }
  }
  return List<String>.unmodifiable(terms);
}

bool _boolValue(
  Object? value, {
  required bool fallback,
  required bool defaultValue,
}) {
  if (value is bool) {
    return value;
  }
  return fallback == defaultValue ? defaultValue : fallback;
}

List<String> _forbiddenTextSurfaces(
  Object? value, {
  List<String> fallback = const [],
}) {
  return _stringList(
    value,
    fallback: fallback,
    defaults: defaultStoryImageForbiddenTextSurfaces,
  );
}
