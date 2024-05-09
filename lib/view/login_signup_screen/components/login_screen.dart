//flutter
import 'package:apapane/details/rounded_button.dart';
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/rounded_password_field.dart';
import 'package:apapane/details/rounded_text_field.dart';
//models
import 'package:apapane/model/login_model.dart';

class LoginScreen extends ConsumerWidget {
  LoginScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginModel loginModel = ref.watch(loginProvider);
    final TextEditingController emailController =
        TextEditingController(text: loginModel.email);
    final TextEditingController passwordController =
        TextEditingController(text: loginModel.password);
    return Column(
      children: [
        Text(mailAddressText),
        RoundedTextField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (text) => loginModel.email = text,
            controller: emailController,
            borderColor: Colors.pink,
            shadowColor: Colors.pink.withOpacity(0.3),
            hintText: mailAddressText),
        Text(passwordText),
        RoundedPasswordField(
          onChanged: (text) => loginModel.password = text,
          passwordController: passwordController,
          obscureText: loginModel.isObscure,
          toggleObscureText: () => loginModel.toggleIsObscure(),
          borderColor: Colors.pink,
          shadowColor: Colors.pink.withOpacity(0.3),
        ),
        RoundedButton(
            onPressed: () => loginModel.login(context: context),
            widthRate: 0.85,
            color: Colors.pink.withOpacity(0.3),
            text: loginText)
      ],
    );
  }
}
