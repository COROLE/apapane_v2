import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/main.dart';
import 'package:apapane/views/splash_screen.dart';
import 'package:go_router/go_router.dart';

import 'package:apapane/models/firestore_user/firestore_user.dart';
import 'package:apapane/views/admin_screen.dart';
import 'package:apapane/views/chat_screen/components/mic_ui.dart';
import 'package:apapane/views/profile_screen/components/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//pages
import 'package:apapane/views/login_signup_screen/login_signup_screen.dart';
import 'package:apapane/views/chat_screen/chat_screen.dart';
import 'package:apapane/views/story_screen/story_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login/redirection',
      name: 'login-redirection',
      redirect: (context, state) {
        final onceUser = IDCore.authUser();
        if (onceUser != null) {
          return '/home';
        } else {
          return '/login';
        }
      },
    ),
    GoRoute(
      path: '/login',
      name: 'login-signup',
      builder: (context, state) => const LoginSignUpScreen(),
    ),
    GoRoute(
      path: '/story',
      name: 'story',
      builder: (context, state) {
        final isNew = state.uri.queryParameters['isNew'] == 'true'; // 修正箇所
        return StoryScreen(isNew: isNew);
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MyHomePage(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/mic',
      name: 'mic',
      builder: (context, state) => const MicUi(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        final currentUserDoc =
            extra['currentUserDoc'] as DocumentSnapshot<Map<String, dynamic>>;
        final firestoreUser = extra['firestoreUser'] as FirestoreUser;
        return AdminScreen(
          currentUserDoc: currentUserDoc,
          firestoreUser: firestoreUser,
        );
      },
    ),
    GoRoute(
      path: '/edit/profile',
      name: 'edit-profile',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const EditProfileScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.ease;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          final scaleAnimation = animation.drive(tween);

          return ScaleTransition(
            scale: scaleAnimation,
            child: child,
          );
        },
      ),
    ),
  ],
);
