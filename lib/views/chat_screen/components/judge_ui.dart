import 'package:apapane/view_models/chat_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/views/common/create_button.dart';
import 'package:apapane/views/common/rounded_button.dart';

class JudgeUi extends ConsumerStatefulWidget {
  const JudgeUi({
    super.key,
    required this.screenHeight,
    required this.screenWidth,
    required this.onPressed,
    required this.chatViewModel,
  });
  final double screenHeight, screenWidth;
  final void Function() onPressed;
  final ChatViewModel chatViewModel;

  @override
  // ignore: library_private_types_in_public_api
  _JudgeUiState createState() => _JudgeUiState();
}

class _JudgeUiState extends ConsumerState<JudgeUi>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleTextAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleTextAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: widget.screenHeight,
        width: widget.screenWidth,
        color: Colors.black.withOpacity(0.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: widget.screenHeight * 0.4,
              child: const CircleAvatar(
                radius: 100,
                backgroundImage: AssetImage(judgeBackground),
              ),
            ),
            Positioned(
              bottom: widget.screenHeight * 0.6,
              child: ScaleTransition(
                scale: _scaleTextAnimation,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 56, 157, 80),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 255, 255, 255)
                            .withOpacity(0.6),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    selectTitle,
                    style: TextStyle(
                      fontFamily: 'ZenMaruGothic',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: widget.screenHeight * 0.27,
              child: ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  apapaneKnightImage,
                  height: widget.screenHeight * 0.45,
                  width: widget.screenWidth * 0.45,
                ),
              ),
            ),
            Positioned(
              bottom: widget.screenHeight * 0.31,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoundedButton(
                    onPressed: () => widget.chatViewModel.cancel(context),
                    widthRate: 0.4,
                    color: const Color.fromARGB(255, 66, 133, 244),
                    text: 'まだはなす',
                  ),
                  CreateButton(
                      judgeMode: true,
                      isValidCreate: widget.chatViewModel.isValidCreate,
                      width: widget.screenWidth * 0.4,
                      height: widget.screenHeight * 0.06,
                      onPressed: widget.onPressed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
