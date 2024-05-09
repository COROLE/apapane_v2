//flutter
import 'package:apapane/details/story_icon.dart';
import 'package:flutter/material.dart';

class LibraryInkWell extends StatelessWidget {
  const LibraryInkWell(
      {Key? key,
      required this.height,
      required this.width,
      required this.onTap,
      required this.storyImageURL,
      required this.titleText})
      : super(key: key);
  final double height, width;
  final void Function()? onTap;
  final String storyImageURL, titleText;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(height: height * 0.02),
          StoryIcon(
            storyImageURL: storyImageURL,
          ),
          SizedBox(height: height * 0.01),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              titleText,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.white),
            ),
          ),
          const Divider(
            color: Color.fromARGB(255, 166, 166, 166),
            thickness: 1,
          ),
        ],
      ),
    );
  }
}
