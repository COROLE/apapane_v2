import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/views/common/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(adminViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Screen')),
      body: Center(
        child: RoundedButton(
          onPressed: viewModel.admin,
          widthRate: 0.6,
          color: Colors.black,
          text: 'Admin',
        ),
      ),
    );
  }
}
