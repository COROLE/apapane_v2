import 'package:apapane/main.dart';
import 'package:apapane/views/login_signup_screen/login_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows splash screen on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('アパパネ'), findsOneWidget);
  });

  testWidgets('login screen explains parent sign-in',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginSignUpScreen(),
        ),
      ),
    );

    expect(find.text('保護者ログイン'), findsOneWidget);
    expect(find.text('Googleでログイン'), findsOneWidget);
    expect(
      find.textContaining('おはなしの同期、購入内容の管理'),
      findsOneWidget,
    );
    expect(
      find.textContaining('保護者が'),
      findsOneWidget,
    );
  });
}
