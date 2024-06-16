//flutter
import 'package:flutter/material.dart';
//views
import 'package:apapane/view/main_screen/archive_screen.dart';
import 'package:apapane/view/main_screen/home_screen.dart';
import 'package:apapane/view/main_screen/profile_screen/profile_screen.dart';
import 'package:apapane/view/main_screen/public_screen.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
//options
import 'firebase_options.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/view/login_signup_screen/login_signup_screen.dart';
import 'package:apapane/details/bottom_nav_bar.dart';
//models
import 'package:apapane/model/bottom_nav_bar_model.dart';
import 'package:apapane/model/main_model.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //MyAppが起動した最初の時にユーザーがログインしているかどうかの確認
    //今変数は一回きり
    final User? onceUser = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      title: startUpperTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "ZenMaruGothic",
      ),
      home: onceUser == null
          ? const LoginSignUpScreen()
          : const MyHomePage(
              title: startUpperTitle,
            ),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //MainModelが起動し、init()が実行される
    final MainModel mainModel = ref.watch(mainProvider);
    final BottomNavigationBarModel bottomNavigationBarModel =
        ref.watch(bottomNavigationBarProvider);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: mainModel.isLoading
            ? const Center(
                child: Text(loadingText),
              )
            : PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: bottomNavigationBarModel.pageController,
                onPageChanged: (index) =>
                    bottomNavigationBarModel.onPageChanged(index: index),
                //childrenの個数はElementsの個数と同じ
                children: const [
                  HomeScreen(),
                  PublicScreen(),
                  ArchiveScreen(),
                  ProfileScreen(),
                ],
              ),
        bottomNavigationBar: BottomNavigationBars(
            bottomNavigationBarModel: bottomNavigationBarModel));
  }
}
