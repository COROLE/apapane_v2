import 'dart:typed_data';

import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/views/common/rounded_title.dart';
import 'package:apapane/views/story_screen/components/end_story_screen.dart';
import 'package:apapane/views/story_screen/components/rounded_story_screen.dart';
import 'package:apapane/views/story_screen/components/start_story_screen.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StoryScreen extends ConsumerWidget {
  const StoryScreen({super.key, required this.isNew});

  final bool isNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('StoryScreen built, isNew: $isNew');
    final mainViewModel = ref.watch(mainViewModelProvider);
    final storyViewModel = ref.watch(storyViewModelProvider);

    final pagesList = <Widget>[
      StartStoryScreen(
        seconds: 30,
        child: RoundedTitle(
          storyTitle: storyViewModel.titleText,
        ),
      ),
      ...storyViewModel.storyPages.asMap().entries.map((entry) {
        final pageIndex = entry.key;
        final page = entry.value;
        final sentence = page['story'].toString();

        return _AsyncStoryPage(
          storyViewModel: storyViewModel,
          pageIndex: pageIndex,
          sentence: sentence,
          isNew: isNew,
          imageSource: page['image']?.toString(),
        );
      }),
      EndStoryScreen(
        storyViewModel: storyViewModel,
        mainViewModel: mainViewModel,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 46, 46, 46),
      body: PageView(
        scrollDirection: Axis.vertical,
        onPageChanged: (int pageIndex) {
          storyViewModel.onPageChanged();
        },
        children: pagesList,
      ),
    );
  }
}

class _AsyncStoryPage extends StatefulWidget {
  const _AsyncStoryPage({
    required this.storyViewModel,
    required this.pageIndex,
    required this.sentence,
    required this.isNew,
    required this.imageSource,
  });

  final StoryViewModel storyViewModel;
  final int pageIndex;
  final String sentence;
  final bool isNew;
  final String? imageSource;

  @override
  State<_AsyncStoryPage> createState() => _AsyncStoryPageState();
}

class _AsyncStoryPageState extends State<_AsyncStoryPage> {
  Uint8List? _picture;

  @override
  void initState() {
    super.initState();
    _picture = widget.storyViewModel.peekStoryPageImage(
      pageIndex: widget.pageIndex,
      sentence: widget.sentence,
      imageSource: widget.imageSource,
    );
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _AsyncStoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageSource != widget.imageSource ||
        oldWidget.sentence != widget.sentence ||
        oldWidget.pageIndex != widget.pageIndex ||
        oldWidget.isNew != widget.isNew) {
      _picture = widget.storyViewModel.peekStoryPageImage(
        pageIndex: widget.pageIndex,
        sentence: widget.sentence,
        imageSource: widget.imageSource,
      );
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      var picture = await widget.storyViewModel.resolveStoryPageImage(
        sentence: widget.sentence,
        pageIndex: widget.pageIndex,
        isNew: widget.isNew,
        imageSource: widget.imageSource,
      );
      if (picture.isEmpty) {
        picture = await widget.storyViewModel.buildFallbackStoryImage(
          sentence: widget.sentence,
          pageIndex: widget.pageIndex,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _picture = picture;
      });
    } catch (error) {
      debugPrint('Async story image load failed: $error');
      try {
        final fallbackPicture =
            await widget.storyViewModel.buildFallbackStoryImage(
          sentence: widget.sentence,
          pageIndex: widget.pageIndex,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _picture = fallbackPicture;
        });
        return;
      } catch (fallbackError) {
        debugPrint('Fallback story image generation failed: $fallbackError');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _picture = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoundedStoryScreen(
      storyViewModel: widget.storyViewModel,
      pageIndex: widget.pageIndex,
      picture: _picture,
      sentence: widget.sentence,
    );
  }
}
