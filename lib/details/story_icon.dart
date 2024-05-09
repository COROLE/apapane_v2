// //flutter
import 'package:apapane/details/rectangle_image.dart';
import 'package:flutter/material.dart';

class StoryIcon extends StatelessWidget {
  const StoryIcon({Key? key, required this.storyImageURL}) : super(key: key);
  final String storyImageURL;
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    //与えられたstoryImageURLが空の時に表示する
    return Container(
        padding: const EdgeInsets.all(4),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(10), boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ]),
        child: storyImageURL.isEmpty
            ? Icon(
                Icons.book,
                size: screenHeight * 0.1,
              )
            : RectangleImage(image: NetworkImage(storyImageURL)));
  }
}
