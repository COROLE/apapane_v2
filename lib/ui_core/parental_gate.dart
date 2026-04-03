import 'dart:math';

import 'package:flutter/material.dart';

Future<bool> showParentalGate(BuildContext context) async {
  final random = Random();
  final first = random.nextInt(6) + 7;
  final second = random.nextInt(4) + 3;
  final answer = first + second;
  final controller = TextEditingController();
  var isValid = false;

  final unlocked = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('保護者の方へ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '保護者向け設定を開く前に、かんたんな確認に答えてください。',
                ),
                const SizedBox(height: 12),
                Text(
                  '$first + $second = ?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'こたえ',
                  ),
                  onChanged: (value) {
                    final nextValid = int.tryParse(value.trim()) == answer;
                    if (nextValid != isValid) {
                      setState(() {
                        isValid = nextValid;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: isValid
                    ? () => Navigator.of(dialogContext).pop(true)
                    : null,
                child: const Text('保護者メニューをひらく'),
              ),
            ],
          );
        },
      );
    },
  );

  controller.dispose();
  return unlocked ?? false;
}
