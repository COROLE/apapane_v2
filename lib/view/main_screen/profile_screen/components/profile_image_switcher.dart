//dart
import 'dart:async';
//flutter
import 'package:flutter/material.dart';
//models
import 'package:apapane/model/main/profile_model.dart';

class ProfileImageSwitcher extends StatefulWidget {
  final ProfileModel profileModel;

  const ProfileImageSwitcher({Key? key, required this.profileModel})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ProfileImageSwitcherState createState() => _ProfileImageSwitcherState();
}

class _ProfileImageSwitcherState extends State<ProfileImageSwitcher>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late Timer _timer;
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 3.0).animate(_controller);

    // 最初のタイマーを200ms後に設定
    Future.delayed(const Duration(milliseconds: 10), () {
      if (mounted) {
        setState(() {
          _currentIndex =
              (_currentIndex + 1) % widget.profileModel.imagesList.length;
        });
        _controller.forward(from: 0.0);
      }

      // 最初の実行後、2000ms間隔のタイマーを設定
      _timer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
        setState(() {
          _currentIndex =
              (_currentIndex + 1) % widget.profileModel.imagesList.length;
        });
        _controller.forward(from: 0.0);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FadeTransition(
          opacity: _opacityAnimation,
          child: widget.profileModel.imagesList[_currentIndex],
        ),
        FadeTransition(
          opacity: ReverseAnimation(_opacityAnimation),
          child: Container(
            color: const Color.fromARGB(255, 34, 34, 34),
          ),
        ),
      ],
    );
  }
}
