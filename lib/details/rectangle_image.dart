//flutter
import 'package:flutter/material.dart';

class RectangleImage extends StatelessWidget {
  const RectangleImage({Key? key, required this.image}) : super(key: key);
  final ImageProvider<Object> image;
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenHeight * 0.2,
      height: screenHeight * 0.24,
      decoration: BoxDecoration(
        image: DecorationImage(image: image, fit: BoxFit.fill),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
