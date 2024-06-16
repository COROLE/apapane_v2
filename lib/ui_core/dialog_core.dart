import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DialogCore {
  static void cupertinoAlertDialog(
    BuildContext context,
    String content,
    String title,
    void Function()? positiveAction,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          content: Text(content),
          title: Text(title),
          actions: [
            CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text("もどる")),
            CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: positiveAction,
                child: const Text("はい"))
          ],
        );
      },
    );
  }
}
