import 'package:apapane/models/story/story_image_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StoryImagePageSpec parses JSON and preserves required fields', () {
    final profile = StoryImageCharacterProfile.fromJson(const {
      'name': 'Kitsune',
      'appearance': 'small orange fox child',
      'clothing': 'blue scarf',
      'colors': 'orange, blue, warm pastel',
      'expressionStyle': 'gentle curious eyes',
      'personalityTone': 'kind and brave',
      'worldStyle': 'candy castle garden',
    });
    final spec = StoryImagePageSpec.fromJson(
      const {
        'page': 1,
        'sceneGoal': 'A fox finds a glowing strawberry lantern.',
        'mainCharacterDescription': 'small orange fox child, blue scarf',
        'supportingCharacters': 'gentle bear friend',
        'sceneDescription': 'The fox and bear stand in a candy garden.',
        'composition': 'Full-frame, fox large in the central area.',
        'emotion': 'Warm surprise and friendly curiosity.',
        'backgroundDescription': 'Simple candy trees and soft pastel path.',
        'environmentDescription': 'A candy garden that fills the full canvas.',
        'foregroundElements': ['fox child', 'strawberry lantern'],
        'midgroundElements': ['soft candy path'],
        'backgroundElements': ['candy trees', 'pastel hills'],
        'backgroundMustFillCanvas': true,
        'wordlessMode': true,
        'forbiddenTextSurfaces': ['signs', 'labels', 'logos'],
        'style': defaultStoryImageStyle,
        'avoid': ['text', 'letters'],
      },
      page: 1,
      characterProfile: profile,
    );

    expect(spec.page, 1);
    expect(spec.sceneGoal, contains('strawberry lantern'));
    expect(spec.mainCharacterDescription, contains('orange fox'));
    expect(spec.composition, contains('Full-frame'));
    expect(spec.emotion, contains('Warm surprise'));
    expect(spec.environmentDescription, contains('candy garden'));
    expect(spec.foregroundElements, contains('fox child'));
    expect(spec.midgroundElements, contains('soft candy path'));
    expect(spec.backgroundElements, contains('candy trees'));
    expect(spec.backgroundMustFillCanvas, isTrue);
    expect(spec.wordlessMode, isTrue);
    expect(spec.forbiddenTextSurfaces, contains('signs'));
    expect(spec.forbiddenTextSurfaces, contains('blackboards'));
    expect(spec.forbiddenTextSurfaces, contains('fake text'));
    expect(spec.forbiddenTextSurfaces, contains('pseudo-English'));
    expect(spec.forbiddenTextSurfaces, contains('pseudo-Chinese'));
    expect(spec.forbiddenTextSurfaces, contains('thought bubble'));
    expect(spec.avoid, contains('text'));
    expect(spec.avoid, contains('speech bubbles'));
    expect(spec.avoid, contains('signs'));
  });

  test('StoryImagePageSpec fallback fills missing values', () {
    final spec = StoryImagePageSpec.fromJson(
      const {
        'page': 2,
        'sceneGoal': 'A fox looks at a small candy door.',
      },
      page: 2,
    );

    expect(spec.page, 2);
    expect(spec.sceneGoal, 'A fox looks at a small candy door.');
    expect(spec.supportingCharacters, 'None.');
    expect(spec.style, defaultStoryImageStyle);
    expect(spec.backgroundDescription, contains('edge-to-edge'));
    expect(spec.environmentDescription, isNotEmpty);
    expect(spec.foregroundElements, contains('main character clearly visible'));
    expect(spec.midgroundElements, contains('plain decorative objects'));
    expect(
      spec.backgroundElements.any((entry) => entry.contains('wordless')),
      isTrue,
    );
    expect(spec.backgroundMustFillCanvas, isTrue);
    expect(spec.wordlessMode, isTrue);
    expect(spec.forbiddenTextSurfaces, contains('book covers with writing'));
    expect(spec.forbiddenTextSurfaces, contains('book with writing'));
    expect(spec.forbiddenTextSurfaces, contains('screens'));
    expect(spec.forbiddenTextSurfaces, contains('text box'));
    expect(spec.forbiddenTextSurfaces, contains('watermark'));
    expect(spec.avoid, contains('distorted hands'));
    expect(spec.avoid, contains('extra fingers'));
    expect(spec.avoid, contains('labels'));
  });

  test('StoryImageSpecPackage normalizes page specs by page number', () {
    final fallbackProfile = StoryImageCharacterProfile.fallback();
    final fallbackSpecs = [
      StoryImagePageSpec.fallback(
        page: 1,
        pageSummary: 'first fallback',
        characterProfile: fallbackProfile,
      ),
      StoryImagePageSpec.fallback(
        page: 2,
        pageSummary: 'second fallback',
        characterProfile: fallbackProfile,
      ),
    ];
    final package = StoryImageSpecPackage.fromJson(
      {
        'characterProfile': fallbackProfile.toJson(),
        'imagePageSpecs': [
          {
            ...fallbackSpecs[1].toJson(),
            'sceneGoal': 'second generated',
          },
          {
            ...fallbackSpecs[0].toJson(),
            'sceneGoal': 'first generated',
          },
        ],
      },
      fallbackProfile: fallbackProfile,
      fallbackSpecs: fallbackSpecs,
    );

    expect(package.imagePageSpecs, hasLength(2));
    expect(package.imagePageSpecs[0].sceneGoal, 'first generated');
    expect(package.imagePageSpecs[1].sceneGoal, 'second generated');
    expect(package.imagePageSpecs[0].toJson(), contains('wordlessMode'));
    expect(
      package.imagePageSpecs[0].toJson(),
      contains('backgroundMustFillCanvas'),
    );
    expect(
        package.imagePageSpecs[0].toJson(), contains('forbiddenTextSurfaces'));
  });
}
