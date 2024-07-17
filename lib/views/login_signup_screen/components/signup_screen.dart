import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/views/abstract/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/view_models/signup_view_model.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    implements AuthState {
  late final SignUpViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(signUpViewModelProvider);
  }

  @override
  String get email => _viewModel.email;
  @override
  set email(String value) => _viewModel.email = value;

  @override
  String get password => _viewModel.password;
  @override
  set password(String value) => _viewModel.password = value;

  @override
  bool get isObscure => _viewModel.isObscure;
  @override
  void toggleIsObscure() => _viewModel.toggleIsObscure();

  @override
  void onSubmit(BuildContext context) => _viewModel.createUser(context);

  @override
  Color get emailBorderColor => const Color.fromARGB(255, 6, 128, 10);
  @override
  Color get passwordBorderColor => const Color.fromARGB(255, 13, 220, 20);
  @override
  Color get buttonColor => const Color.fromARGB(255, 15, 153, 20);

  @override
  String get buttonText => signUpText;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final viewModel = ref.watch(loginViewModelProvider);
        return AuthState.buildAuthWidget(
            this, context, ref, viewModel.isObscure);
      },
    );
  }
}
