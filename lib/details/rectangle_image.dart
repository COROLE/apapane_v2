//flutter
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RectangleImage extends StatelessWidget {
  const RectangleImage({Key? key, required this.imageUrl}) : super(key: key);
  final String imageUrl;
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      width: screenHeight * 0.2,
      height: screenHeight * 0.24,
      decoration: BoxDecoration(
        image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.fill),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
