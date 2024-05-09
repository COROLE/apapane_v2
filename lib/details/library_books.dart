//flutter
import 'package:flutter/material.dart';
//packages
import 'package:pull_to_refresh/pull_to_refresh.dart';
//components
import 'package:apapane/view/refresh_screen.dart';

class LibraryBooks extends StatelessWidget {
  const LibraryBooks(
      {Key? key,
      required this.image,
      required this.titleText,
      required this.height,
      required this.width,
      required this.refreshController,
      required this.child,
      required this.onRefresh,
      required this.onLoading})
      : super(key: key);
  final String image, titleText;
  final double height, width;
  final RefreshController refreshController;
  final Widget child;
  final void Function()? onRefresh, onLoading;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          image,
          height: height,
          width: width,
          fit: BoxFit.cover,
        ),
        Positioned(
          top: height * 0.065,
          left: width * 0.1,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              titleText,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
        ),
        Positioned(
          left: width * 0.1,
          top: height * 0.1,
          bottom: height * 0.003,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            width: width * 0.8,
            height: height,
            child: RefreshScreen(
                onRefresh: onRefresh,
                onLoading: onLoading,
                refreshController: refreshController,
                child: child),
          ),
        ),
      ],
    );
  }
}
