//flutter
import 'package:flutter/material.dart';
//components
import 'package:apapane/details/text_field_container.dart';

class RoundedTextField extends StatelessWidget {
  const RoundedTextField({
    Key? key,
    required this.keyboardType,
    required this.onChanged,
    required this.controller,
    required this.borderColor,
    required this.shadowColor,
    required this.hintText,
  }) : super(key: key);
  final TextInputType keyboardType;
  final void Function(String) onChanged;
  final TextEditingController controller;
  final Color borderColor;
  final Color shadowColor;
  final String hintText;
  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      borderColor: borderColor,
      shadowColor: shadowColor,
      child: TextFormField(
        keyboardType: keyboardType,
        onChanged: onChanged,
        controller: controller,
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
