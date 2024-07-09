import 'package:go_router/go_router.dart';

import 'package:apapane/domain/firestore_user/firestore_user.dart';
import 'package:apapane/view_old/admin_screen.dart';
import 'package:apapane/view_old/chat_screen/components/mic_ui.dart';
import 'package:apapane/view_old/main_screen/home_screen.dart';
import 'package:apapane/view_old/main_screen/profile_screen/components/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
//pages
import 'package:apapane/main.dart';
import 'package:apapane/view_old/login_signup_screen/login_signup_screen.dart';
import 'package:apapane/view_old/chat_screen/chat_screen.dart';
import 'package:apapane/view_old/story_screen/story_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MyApp(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginSignUpScreen(),
    ),
    GoRoute(
      path: '/story',
      builder: (context, state) {
        final isNew = state.uri.queryParameters['isNew'] == 'true'; // 修正箇所
        return StoryScreen(isNew: isNew);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/mic',
      builder: (context, state) => const MicUi(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) {
        final currentUserDoc =
            state.extra as DocumentSnapshot<Map<String, dynamic>>;
        final firestoreUser = state.extra as FirestoreUser;
        return AdminScreen(
            currentUserDoc: currentUserDoc, firestoreUser: firestoreUser);
      },
    ),
    GoRoute(
      path: '/edit-profile',
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
