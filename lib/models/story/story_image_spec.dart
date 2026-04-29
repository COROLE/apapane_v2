import 'package:apapane/models/story/story_generation_draft.dart';
import 'package:apapane/typedefs/firestore_typedef.dart';

const String defaultStoryImageStyle =
    "Soft children's picture book illustration, warm pastel color palette, "
    'gentle lighting, clean composition, simple readable shapes, visually '
    'appealing for young children, polished and cohesive, high-quality '
    'storytelling illustration.';

const List<String> defaultStoryImageAvoidTerms = [
  'text',
  'letters',
  'captions',
  'speech bubbles',
  'scary expression',
  'horror mood',
  'dark atmosphere',
  'cluttered background',
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
        'Simple consistent picture-book clothing.',
      ]),
      colors: _firstText([map['colors'], base.colors, 'Warm pastel colors.']),
      expressionStyle: _firstText([
        map['expressionStyle'],
        base.expressionStyle,
        'Gentle, readable expressions.',
      ]),
      personalityTone: _firstText([
        map['personalityTone'],
        base.personalityTone,
        'Kind, curious, and friendly.',
      ]),
      worldStyle: _firstText([
        map['worldStyle'],
        base.worldStyle,
        "A safe, warm children's picture-book world.",
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
        'A cute, friendly main character with a rounded picture-book design.',
      ]),
      clothing:
          'Simple child-friendly clothing or accessories that stay consistent on every page.',
      colors: _firstText([
        draft?.characterSheet.artDirection,
        'Warm pastel colors with clear, readable character colors.',
      ]),
      expressionStyle:
          'Gentle, readable facial expressions with bright curious eyes.',
      personalityTone:
          'Kind, curious, brave in a gentle way, friendly for young children.',
      worldStyle: _firstText([
        draft?.characterSheet.worldDetails,
        "A safe, warm, simple children's picture-book world.",
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
        'Show page $page as a clear storybook moment.',
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
        'Vertical 9:16 composition, clear focal action, uncluttered layout.',
      ]),
      emotion: _firstText([
        map['emotion'],
        base.emotion,
        'Warm, friendly, gentle, and easy to read.',
      ]),
      backgroundDescription: _firstText([
        map['backgroundDescription'],
        base.backgroundDescription,
        'Simple soft background with minimal details.',
      ]),
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
      'Show page $page as a clear warm picture-book moment.',
    ]);
    return StoryImagePageSpec(
      page: page,
      sceneGoal: sceneGoal,
      mainCharacterDescription:
          '${profile.appearance} ${profile.clothing} ${profile.colors}',
      supportingCharacters: _firstText([supportingCharacters, 'None.']),
      sceneDescription: sceneGoal,
      composition:
          'Vertical 9:16 composition with the main character large and clear in the foreground, one simple focal action, and enough open space to read the scene immediately.',
      emotion: _firstText([mood, 'Warm, gentle, curious, safe, and friendly.']),
      backgroundDescription:
          'Simple uncluttered background with soft shapes and only the details needed to understand the scene.',
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
  for (final term in defaultStoryImageAvoidTerms) {
    if (!terms.contains(term)) {
      terms.add(term);
    }
  }
  return List<String>.unmodifiable(terms);
}
