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
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SignUpModel signUpModel = ref.watch(signUpProvider);
    final TextEditingController emailController =
        TextEditingController(text: signUpModel.email);
    final TextEditingController passwordController =
        TextEditingController(text: signUpModel.password);
    final double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.1,
        ),
        const Text(mailAddressText, style: TextStyle(color: Colors.grey)),
        RoundedTextField(
            keyboardType: TextInputType.emailAddress,
            onChanged: (text) => signUpModel.email = text,
            controller: emailController,
            borderColor: Colors.green[800]!,
            shadowColor: Colors.green[800]!.withOpacity(0.5),
            hintText: mailAddressText),
        const Text(passwordText, style: TextStyle(color: Colors.grey)),
        RoundedPasswordField(
          onChanged: (text) => signUpModel.password = text,
          passwordController: passwordController,
          obscureText: signUpModel.isObscure,
          toggleObscureText: () => signUpModel.toggleIsObscure(),
          borderColor: Colors.lightGreen[
              400]!, // Brighter and stylish color for password field
          shadowColor:
              Colors.lightGreen[400]!.withOpacity(0.5), // Matching shadow color
        ),
        SizedBox(
          height: screenHeight * 0.03,
        ),
        RoundedButton(
            onPressed: () => signUpModel.createUser(context: context),
            widthRate: 0.85,
            color: Colors.lightGreen[400]!
                .withOpacity(0.8), // Brighter and stylish color for button
            text: signUpText)
      ],
    );
  }
}
