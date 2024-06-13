//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/rounded_button.dart';

class ReloadScreen extends StatelessWidget {
  const ReloadScreen({super.key, required this.onReload});
  final void Function()? onReload;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(noStoryTitle),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: RoundedButton(
                onPressed: onReload,
                widthRate: 0.8,
                color: Colors.pink.withOpacity(0.8),
                text: reloadText),
          )
        ],
      ),
    );
  }
}
