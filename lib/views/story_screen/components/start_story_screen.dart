import 'package:apapane/constants/strings.dart';
import 'package:flutter/material.dart';

class StartStoryScreen extends StatefulWidget {
  const StartStoryScreen(
      {super.key, required this.child, required this.seconds});
  @override
  // ignore: library_private_types_in_public_api
  _StartStoryScreenState createState() => _StartStoryScreenState();
  final Widget child;
  final int seconds;
}

class _StartStoryScreenState extends State<StartStoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;
  late Widget child;
  late int seconds;

  @override
  void initState() {
    super.initState();
    seconds = widget.seconds;
    _controller = AnimationController(
      duration: Duration(seconds: seconds),
      vsync: this,
    )..repeat(reverse: true);
    child = widget.child;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double screenHeightMax = screenHeight * 3.24;
    _animation =
        Tween<double>(begin: 0, end: screenHeightMax).animate(_controller)
          ..addListener(() {
            setState(() {});
          });

    return Scaffold(
      body: Stack(children: [
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(), // Disable scrolling
          child: SizedBox(
            height: screenHeight * 2,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -(_animation?.value ?? 0),
                  child: Column(
                    children: [
                      for (int i = 0; i < titlePicture.length; i++)
                        SizedBox(
                          height: screenWidth,
                          child: Image.asset(
                            titlePicture[i], // 画像を指定
                            height: screenWidth,
                            width: screenWidth,
                            fit: BoxFit.cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: const Color.fromARGB(255, 34, 34, 34).withOpacity(0.3),
          width: screenWidth,
          height: screenHeightMax,
        ),
        Center(child: child)
      ]),
    );
  }
}
