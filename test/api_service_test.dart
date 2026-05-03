import 'package:apapane/services/api/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generateImageSpecs payload includes StoryCanon when available', () {
    final payload = ApiService.buildGenerateImageSpecsPayload(
      title: 'Moon Lantern',
      story: '1. display story text',
      pages: const [
        {
          'page': 1,
          'story': 'display story text',
          'visualFocus': 'fallback visual focus',
        },
      ],
      characterSheet: const {
        'protagonist': 'small rabbit',
        'companion': 'tiny bear',
        'worldDetails': 'forest',
        'artDirection': 'soft colors',
      },
      mode: 'mini',
      storyCanon: const {
        'title': 'Moon Lantern',
        'pagePlans': [
          {
            'page': 1,
            'visualBeat': 'rabbit follows glowing petals',
          },
        ],
      },
    );

    expect(payload, contains('storyCanon'));
    expect(payload['storyCanon'], isA<Map<String, dynamic>>());
    expect(payload['pages'], isNotEmpty);
  });
}
