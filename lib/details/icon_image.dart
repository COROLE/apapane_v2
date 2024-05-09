//flutter
import 'package:flutter/material.dart';
//components
import 'package:apapane/details/circle_image.dart';

class IconImage extends StatelessWidget {
  const IconImage({Key? key, required this.length, required this.iconImageURL})
      : super(key: key);
  final double length;
  final String iconImageURL;
  @override
  Widget build(BuildContext context) {
    //与えられたIconImageURLが空の時に表示する
    return iconImageURL.isEmpty
        ? Container(
            decoration:
                const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
            width: length * 1.5,
            height: length * 1.5,
            child: Icon(
              Icons.person,
              size: length,
              color: Color.fromARGB(255, 209, 208, 208),
            ),
          )
        : CircleImage(length: length, image: NetworkImage(iconImageURL));
  }
}
