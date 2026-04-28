import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/models/story/story_generation_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StoryPreviewScreen extends ConsumerWidget {
  const StoryPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatViewModel = ref.watch(chatViewModelProvider);
    final storyViewModel = ref.watch(storyViewModelProvider);
    final preview = chatViewModel.storyPreview;
    final status = chatViewModel.storyCreationStatus;

    if (preview == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('あらすじ')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('もどる'),
          ),
        ),
      );
    }

    final silverText = status == null
        ? 'Silver枠はログイン後に確認します'
        : status.isSubscriptionActive
            ? 'Silver残り ${status.storyCreditsRemaining}/${status.monthlyStoryCredits} コイン分'
            : 'Silverは未加入です';

    return Scaffold(
      appBar: AppBar(
        title: const Text('あらすじ'),
        backgroundColor: const Color(0xFF2E9D57),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  preview.title,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${preview.mode.displayName} / ${preview.pageCount}ページ / ${preview.coinCost}コイン',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(silverText),
                const SizedBox(height: 18),
                const Text(
                  'あらすじ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  preview.summary,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 18),
                const Text(
                  'ページごとの展開',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...preview.pagePlan.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '${entry.key + 1}. ${entry.value}',
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  icon: const Icon(Icons.brush),
                  label: const Text('この内容で絵本にする'),
                  onPressed: () => chatViewModel.confirmPreviewAndCreate(
                    context: context,
                    storyViewModel: storyViewModel,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    chatViewModel.canRegeneratePreview
                        ? 'もう一回あらすじを作る'
                        : 'あらすじ作り直しは3回まで',
                  ),
                  onPressed: chatViewModel.canRegeneratePreview
                      ? () => chatViewModel.regenerateStoryPreview(
                            context: context,
                          )
                      : null,
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('もどる'),
                ),
              ],
            ),
            if (chatViewModel.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xAAFFFFFF),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
