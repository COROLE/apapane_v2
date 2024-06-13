//flutter
import 'package:flutter/material.dart';

class CircleImage extends StatelessWidget {
  const CircleImage({super.key, required this.length, required this.image});
  final double length;
  final ImageProvider<Object> image;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        image: DecorationImage(image: image, fit: BoxFit.fill),
        shape: BoxShape.circle,
      ),
    );
  }
}
