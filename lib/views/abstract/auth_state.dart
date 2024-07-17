import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/views/common/rounded_button.dart';
import 'package:apapane/views/common/rounded_password_field.dart';
import 'package:apapane/views/common/rounded_text_field.dart';

abstract class AuthState {
  String get email;
  set email(String value);

  String get password;
  set password(String value);

  bool get isObscure;
  void toggleIsObscure();

  void onSubmit(BuildContext context);

  Color get emailBorderColor;
  Color get passwordBorderColor;
  Color get buttonColor;

  String get buttonText;

  static Widget buildAuthWidget(
      AuthState state, BuildContext context, WidgetRef ref, bool isObscure) {
    final TextEditingController emailController =
        TextEditingController(text: state.email);
    final TextEditingController passwordController =
        TextEditingController(text: state.password);
    final double screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.1),
          const Text(mailAddressText, style: TextStyle(color: Colors.grey)),
          RoundedTextField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (text) => state.email = text,
            controller: emailController,
            borderColor: state.emailBorderColor,
            shadowColor: state.emailBorderColor.withOpacity(0.5),
            hintText: mailAddressText,
          ),
          const Text(passwordText, style: TextStyle(color: Colors.grey)),
          RoundedPasswordField(
            onChanged: (text) => state.password = text,
            passwordController: passwordController,
            obscureText: isObscure,
            toggleObscureText: state.toggleIsObscure,
            borderColor: state.passwordBorderColor,
            shadowColor: state.passwordBorderColor.withOpacity(0.5),
          ),
          SizedBox(height: screenHeight * 0.03),
          RoundedButton(
            onPressed: () => state.onSubmit(context),
            widthRate: 0.85,
            color: state.buttonColor.withOpacity(0.8),
            text: state.buttonText,
          ),
        ],
      ),
    );
  }
}
