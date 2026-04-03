import 'package:apapane/views/common/rectangle_image.dart';
import 'package:flutter/material.dart';

class StoryIcon extends StatelessWidget {
  const StoryIcon({super.key, required this.storyImageURL});

  final String storyImageURL;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = (screenWidth * 0.34).clamp(112.0, 168.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.32),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
        width: thumbnailWidth,
        child: storyImageURL.isEmpty
            ? AspectRatio(
                aspectRatio: 9 / 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.84),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.book,
                      size: 46,
                    ),
                  ),
                ),
              )
            : RectangleImage(imageUrl: storyImageURL),
      ),
    );
  }
}
