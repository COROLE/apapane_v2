//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/text_field_container.dart';

class RoundedPasswordField extends StatelessWidget {
  const RoundedPasswordField({
    super.key,
    required this.onChanged,
    required this.passwordController,
    required this.obscureText,
    required this.toggleObscureText,
    required this.borderColor,
    required this.shadowColor,
  });
  final void Function(String)? onChanged;
  final TextEditingController passwordController;
  final bool obscureText;
  final void Function()? toggleObscureText;
  final Color borderColor, shadowColor;
  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      borderColor: borderColor,
      shadowColor: shadowColor,
      child: TextFormField(
        keyboardType: TextInputType.visiblePassword,
        onChanged: onChanged,
        controller: passwordController,
        obscureText: obscureText,
        decoration: InputDecoration(
            border: InputBorder.none,
            suffix: IconButton(
              icon: obscureText
                  ? const Icon(Icons.visibility_off)
                  : const Icon(Icons.visibility),
              onPressed: toggleObscureText,
            ),
            hintText: passwordText,
            hintStyle: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
