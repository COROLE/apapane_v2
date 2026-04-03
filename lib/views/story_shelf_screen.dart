import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/views/archive_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StoryShelfScreen extends ConsumerStatefulWidget {
  const StoryShelfScreen({super.key});

  @override
  ConsumerState<StoryShelfScreen> createState() => _StoryShelfScreenState();
}

class _StoryShelfScreenState extends ConsumerState<StoryShelfScreen> {
  @override
  Widget build(BuildContext context) {
    final mainViewModel = ref.watch(mainViewModelProvider);
    final currentIndex = ref.watch(
      bottomNavigationBarViewModelProvider.select(
        (viewModel) => viewModel.currentIndex,
      ),
    );

    if (mainViewModel.hasSyncedAccount) {
      if (currentIndex != 1) {
        return const SizedBox.shrink();
      }
      ref.watch(archiveViewModelProvider);
      return const ArchiveScreen();
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 72,
                color: Color(0xFF2D7A63),
              ),
              const SizedBox(height: 16),
              const Text(
                'ゲストのままでは、この本棚に物語は保存されません。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ほかの端末にも保存したいときや家族で共有したいときは、保護者メニューを開いてログインしてください。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.5,
                  color: Color(0xFF5A5A5A),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  ref.read(bottomNavigationBarViewModelProvider).onTabTapped(2);
                },
                child: const Text('保護者メニューをひらく'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
