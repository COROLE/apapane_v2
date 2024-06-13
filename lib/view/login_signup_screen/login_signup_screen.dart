//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
//pages
import 'package:apapane/view/login_signup_screen/components/login_screen.dart';
import 'package:apapane/view/login_signup_screen/components/signup_screen.dart';

class LoginSignUpScreen extends ConsumerWidget {
  const LoginSignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Apapane', style: TextStyle(color: Colors.black)),
            bottom: TabBar(
              indicatorColor: Colors.pinkAccent,
              labelColor: Colors.pink[300],
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(text: 'ログイン'),
                Tab(text: '新規登録'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              LoginScreen(),
              SignUpScreen(),
            ],
          ),
        ));
  }
}
