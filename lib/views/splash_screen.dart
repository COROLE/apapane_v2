// ignore_for_file: file_names

import 'package:apapane/constants/strings.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 3))
        .then((value) => context.pushReplacement('/login/redirection'));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: buildTopScreen(),
      ),
    );
  }

  Widget buildTopScreen() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: FractionalOffset.topLeft,
          end: FractionalOffset.bottomRight,
          colors: [
            const Color.fromARGB(253, 252, 42, 0).withOpacity(0.8),
            const Color.fromARGB(255, 255, 216, 216).withOpacity(0.8),
          ],
          stops: const [
            0.0,
            1.0,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Apapane',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 70),
          ),
          const SizedBox(
            height: 30,
          ),
          Image.asset(
            apapaneImage,
            width: 400,
            height: 400,
          ),
        ],
      ),
    );
  }
}
