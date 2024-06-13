//flutter
import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton(
      {super.key,
      required this.onPressed,
      required this.widthRate,
      required this.color,
      required this.text});

  final void Function()? onPressed;
  final double widthRate;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: maxWidth * widthRate,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
