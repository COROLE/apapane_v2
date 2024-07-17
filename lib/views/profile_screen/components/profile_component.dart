//flutter
import 'package:flutter/material.dart';

class ProfileComponent extends StatelessWidget {
  const ProfileComponent({super.key, required this.image});
  final String image;
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Image.asset(
      image,
      height: screenHeight,
      width: screenWidth,
      fit: BoxFit.cover,
    );
  }
}
