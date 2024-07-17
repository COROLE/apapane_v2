//flutter
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CircleImage extends StatelessWidget {
  const CircleImage({super.key, required this.length, required this.image});
  final double length;
  final dynamic image;
  bool isNetWorkImage(imageData) =>
      imageData.startsWith('http') || imageData.startsWith('https');
  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (image is Uint8List) {
      imageProvider = MemoryImage(image);
    } else if (image is String && isNetWorkImage(image)) {
      imageProvider = NetworkImage(image);
    } else if (image is String) {
      imageProvider = AssetImage(image);
    } else if (image is ImageProvider) {
      imageProvider = image;
    } else {
      throw ArgumentError(
          'Image must be either Uint8List, AssetImage path, or ImageProvider');
    }

    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.fill),
        shape: BoxShape.circle,
      ),
    );
  }
}
