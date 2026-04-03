import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class RectangleImage extends StatelessWidget {
  const RectangleImage({
    super.key,
    required this.imageUrl,
    this.overrideImageProvider,
  });

  final String imageUrl;
  final ImageProvider? overrideImageProvider;

  @override
  Widget build(BuildContext context) {
    final imageProvider = overrideImageProvider ?? _imageProvider(imageUrl);
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF7F0E8),
          ),
          child: Image(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImageProvider(path);
    }
    if ((path.startsWith('/') || path.contains(':\\')) &&
        File(path).existsSync()) {
      return FileImage(File(path));
    }
    return AssetImage(path);
  }
}
