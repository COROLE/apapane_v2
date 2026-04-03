import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';

class AdminViewModel extends ChangeNotifier {
  Future<void> admin() async {
    await UIHelper.showFlutterToast(
      'Admin tools are disabled in local-only mode.',
    );
  }
}
