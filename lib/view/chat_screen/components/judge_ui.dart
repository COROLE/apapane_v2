import 'package:flutter/material.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/details/create_button.dart';
import 'package:apapane/details/rounded_button.dart';
import 'package:apapane/model/chat_model.dart';
import 'package:apapane/model/story_model.dart';
import 'package:apapane/constants/voids.dart' as voids;
import 'package:flutter/widgets.dart';

class JudgeUi extends StatefulWidget {
  const JudgeUi({
    super.key,
    required this.screenHeight,
    required this.screenWidth,
    required this.chatModel,
    required this.storyModel,
  });

  final double screenHeight, screenWidth;
  final ChatModel chatModel;
  final StoryModel storyModel;

  @override
  // ignore: library_private_types_in_public_api
  _JudgeUiState createState() => _JudgeUiState();
}

class _JudgeUiState extends State<JudgeUi> with SingleTickerProviderStateMixin {
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
                radius: 100, // Adjust the size as needed
                backgroundImage: AssetImage(
                    judgeBackground), // Replace 'your_image.png' with your asset image
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
                )),
            Positioned(
              bottom: widget.screenHeight * 0.27,
              child: ScaleTransition(
                scale: _animation,
                child: Image.asset(
                  apapaneKnightImage,
                  height: widget.screenHeight * 0.45, // Reduced height
                  width: widget.screenWidth * 0.45, // Reduced width
                ),
              ),
            ),
            Positioned(
              bottom: widget.screenHeight * 0.31,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RoundedButton(
                    onPressed: () => widget.chatModel.cancel(),
                    widthRate: 0.4,
                    color:
                        const Color.fromARGB(255, 66, 133, 244), // Blue color
                    text: 'まだはなす',
                  ),
                  CreateButton(
                    judgeMode: true,
                    isValidCreate: widget.chatModel.isValidCreate,
                    width: widget.screenWidth * 0.4,
                    height: widget.screenHeight * 0.06,
                    onPressed: widget.chatModel.isCommentLoading
                        ? () async => await voids.showFluttertoast(
                              msg: pleaseWaitMSG,
                            )
                        : () async =>
                            await widget.chatModel.createButtonPressed(
                              context: context,
                              storyModel: widget.storyModel,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
