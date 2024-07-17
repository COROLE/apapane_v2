//flutter
import 'package:flutter/material.dart';

class DetailButton extends StatelessWidget {
  const DetailButton({super.key, required this.onPressed, required this.size});
  final void Function()? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 213, 213, 213).withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
          color: const Color.fromARGB(255, 0, 0, 0),
          onPressed: onPressed,
          icon: Icon(
            Icons.dehaze_sharp,
            size: size,
          )),
    );
  }
}
