//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/rounded_button.dart';
import 'package:apapane/details/rounded_password_field.dart';
import 'package:apapane/details/rounded_text_field.dart';
//models
import 'package:apapane/model/signup_model.dart';

class SignUpScreen extends ConsumerWidget {
  SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SignUpModel signUpModel = ref.watch(signUpProvider);
    final TextEditingController emailController =
        TextEditingController(text: signUpModel.email);
    final TextEditingController passwordController =
        TextEditingController(text: signUpModel.password);
    return Column(
      children: [
        Text(mailAddressText),
        RoundedTextField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (text) => signUpModel.email = text,
            controller: emailController,
            borderColor: Colors.pink,
            shadowColor: Colors.pink.withOpacity(0.3),
            hintText: mailAddressText),
        Text(passwordText),
        RoundedPasswordField(
          onChanged: (text) => signUpModel.password = text,
          passwordController: passwordController,
          obscureText: signUpModel.isObscure,
          toggleObscureText: () => signUpModel.toggleIsObscure(),
          borderColor: Colors.pink,
          shadowColor: Colors.pink.withOpacity(0.3),
        ),
        RoundedButton(
            onPressed: () => signUpModel.createUser(context: context),
            widthRate: 0.85,
            color: Colors.pink.withOpacity(0.3),
            text: signUpText)
      ],
    );
  }
}
