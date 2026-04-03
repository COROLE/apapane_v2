import 'dart:typed_data';

import 'package:apapane/views/common/rectangle_image.dart';
import 'package:apapane/views/common/rounded_sentence.dart';
import 'package:apapane/views/story_screen/components/rounded_story_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List onePixelPng() => Uint8List.fromList(const [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0xF8,
        0xCF,
        0xC0,
        0x00,
        0x00,
        0x03,
        0x01,
        0x01,
        0x00,
        0xC9,
        0xFE,
        0x92,
        0xEF,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

  Future<void> pumpStoryLayout(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              StoryPageViewport(
                child: ColoredBox(color: Colors.blue),
              ),
              RoundedSentence(
                sentence: 'これは とても ながい おはなしですが したの カードの 中で きれいに おさまります',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('story artwork keeps a 9:16 frame on a narrow phone',
      (tester) async {
    await pumpStoryLayout(
      tester,
      size: const Size(320, 640),
    );

    final viewport = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    final sentenceRect = tester.getRect(find.textContaining('これは'));

    expect(viewport.aspectRatio, closeTo(9 / 16, 0.0001));
    expect(find.byType(SafeArea), findsOneWidget);
    expect(sentenceRect.left, greaterThanOrEqualTo(0));
    expect(sentenceRect.right, lessThanOrEqualTo(320));
    expect(sentenceRect.bottom, lessThanOrEqualTo(640));
  });

  testWidgets('story artwork keeps a 9:16 frame on a tall phone',
      (tester) async {
    await pumpStoryLayout(
      tester,
      size: const Size(430, 932),
    );

    final viewport = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    final sentenceRect = tester.getRect(find.textContaining('これは'));

    expect(viewport.aspectRatio, closeTo(9 / 16, 0.0001));
    expect(sentenceRect.right, lessThanOrEqualTo(430));
    expect(sentenceRect.bottom, lessThanOrEqualTo(932));
  });

  testWidgets('story thumbnails preserve a 9:16 aspect ratio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 140,
            child: RectangleImage(
              imageUrl: 'https://example.com/cover.jpg',
              overrideImageProvider: MemoryImage(onePixelPng()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final thumbnailAspect =
        tester.widget<AspectRatio>(find.byType(AspectRatio).first);
    expect(thumbnailAspect.aspectRatio, closeTo(9 / 16, 0.0001));
  });
}
