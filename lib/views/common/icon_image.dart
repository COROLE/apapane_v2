//flutter
import 'package:apapane/constants/strings.dart';
import 'package:flutter/material.dart';
//components
import 'package:apapane/views/common/circle_image.dart';

class IconImage extends StatelessWidget {
  const IconImage(
      {super.key, required this.length, required this.iconImageData});
  final double length;
  final dynamic iconImageData;
  @override
  Widget build(BuildContext context) {
    //与えられたIconImageURLが空の時に表示する
    return iconImageData.isEmpty
        ? CircleImage(
            length: length,
            image: apapaneImage,
          )
        : CircleImage(length: length, image: iconImageData);
  }
}
