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
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LoginModel loginModel = ref.watch(loginProvider);
    final TextEditingController emailController =
        TextEditingController(text: loginModel.email);
    final TextEditingController passwordController =
        TextEditingController(text: loginModel.password);
    final double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.1,
          ),
          const Text(mailAddressText, style: TextStyle(color: Colors.grey)),
          RoundedTextField(
              keyboardType: TextInputType.emailAddress,
              onChanged: (text) => loginModel.email = text,
              controller: emailController,
              borderColor: Colors.blueAccent,
              shadowColor: Colors.blueAccent.withOpacity(0.5),
              hintText: mailAddressText),
          const Text(passwordText, style: TextStyle(color: Colors.grey)),
          RoundedPasswordField(
            onChanged: (text) => loginModel.password = text,
            passwordController: passwordController,
            obscureText: loginModel.isObscure,
            toggleObscureText: () => loginModel.toggleIsObscure(),
            borderColor: Colors.lightBlue,
            shadowColor: Colors.lightBlue.withOpacity(0.5),
          ),
          SizedBox(
            height: screenHeight * 0.03,
          ),
          RoundedButton(
              onPressed: () => loginModel.login(context: context),
              widthRate: 0.85,
              color: Colors.lightBlue.withOpacity(0.5),
              text: loginText)
        ],
      ),
    );
  }
}
