import 'dart:typed_data';

import 'package:apapane/view_models/story_view_model.dart';
import 'package:apapane/views/common/rounded_sentence.dart';
import 'package:flutter/material.dart';

class StoryPageViewport extends StatelessWidget {
  const StoryPageViewport({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedStoryScreen extends StatelessWidget {
  const RoundedStoryScreen({
    super.key,
    required this.storyViewModel,
    required this.pageIndex,
    required this.picture,
    required this.sentence,
  });

  final StoryViewModel storyViewModel;
  final int pageIndex;
  final Uint8List? picture;
  final String sentence;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF181B29),
                Color(0xFF262B3F),
              ],
            ),
          ),
        ),
        StoryPageViewport(
          child: _buildImageWidget(),
        ),
        RoundedSentence(sentence: sentence),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.78),
                ),
                child: IconButton(
                  iconSize: 32,
                  icon: !storyViewModel.isVolume
                      ? const Icon(
                          Icons.volume_off,
                          color: Color(0xFFE04747),
                        )
                      : storyViewModel.isVoiceDownloading
                          ? SizedBox(
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.6,
                              ),
                            )
                          : const Icon(
                              Icons.volume_up,
                              color: Color(0xFF2A9D5B),
                            ),
                  onPressed: () =>
                      storyViewModel.onVolumePressed(sentence: sentence),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget() {
    final imageBytes = picture;
    if (imageBytes == null || imageBytes.isEmpty) {
      return _buildFallbackSurface();
    }

    return ColoredBox(
      color: const Color(0xFFF7F0E8),
      child: Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildFallbackSurface();
        },
      ),
    );
  }

  Widget _buildFallbackSurface() {
    final diagnostic = storyViewModel.imageDiagnosticForPage(pageIndex);
    final headline = diagnostic == null ? '画像を準備しています' : '画像を表示できませんでした';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE2D2),
            Color(0xFFFFC5D8),
            Color(0xFFCFE8FF),
          ],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5B3A3A),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (diagnostic != null) ...[
                const SizedBox(height: 12),
                Text(
                  diagnostic,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7A4A4A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
