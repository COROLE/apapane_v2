import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/views/abstract/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/view_models/login_view_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    implements AuthState {
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ref.read(loginViewModelProvider);
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
  void onSubmit(BuildContext context) => _viewModel.login(context: context);

  @override
  Color get emailBorderColor => Colors.blueAccent;
  @override
  Color get passwordBorderColor => Colors.lightBlue;
  @override
  Color get buttonColor => Colors.lightBlue;

  @override
  String get buttonText => loginText;

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
