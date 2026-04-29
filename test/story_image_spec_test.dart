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
        'composition': 'Vertical 9:16, fox large in the foreground.',
        'emotion': 'Warm surprise and friendly curiosity.',
        'backgroundDescription': 'Simple candy trees and soft pastel path.',
        'style': defaultStoryImageStyle,
        'avoid': ['text', 'letters'],
      },
      page: 1,
      characterProfile: profile,
    );

    expect(spec.page, 1);
    expect(spec.sceneGoal, contains('strawberry lantern'));
    expect(spec.mainCharacterDescription, contains('orange fox'));
    expect(spec.composition, contains('Vertical 9:16'));
    expect(spec.emotion, contains('Warm surprise'));
    expect(spec.avoid, contains('text'));
    expect(spec.avoid, contains('speech bubbles'));
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
    expect(spec.avoid, contains('distorted hands'));
    expect(spec.avoid, contains('extra fingers'));
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
  });
}
