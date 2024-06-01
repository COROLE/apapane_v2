import 'package:flutter/material.dart';

class TextFieldContainer extends StatelessWidget {
  const TextFieldContainer({
    Key? key,
    required this.borderColor,
    required this.child,
    required this.shadowColor,
    this.vertical = 0.0,
  }) : super(key: key);

  final Color borderColor;
  final Color shadowColor;
  final Widget child;
  final double vertical;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double width = size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: vertical),
      width: width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.25),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: child,
    );
  }
}
