import 'package:apapane/constants/strings.dart';
import 'package:apapane/enums/confirm_action.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EndStoryScreen extends ConsumerWidget {
  const EndStoryScreen({
    super.key,
    required this.storyViewModel,
    required this.mainViewModel,
  });

  final StoryViewModel storyViewModel;
  final MainViewModel mainViewModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuestMode = !mainViewModel.hasSyncedAccount;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(endImage),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: () => _handleEndPressed(context, ref, isGuestMode),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color.fromARGB(196, 255, 2, 86),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: const Text(
              endButtonText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleEndPressed(
    BuildContext context,
    WidgetRef ref,
    bool isGuestMode,
  ) async {
    try {
      switch (storyViewModel.toStoryPageType) {
        case ToStoryPageType.memoryStory:
          context.pop();
          break;
        case ToStoryPageType.newStory:
          await showCupertinoModalPopup<void>(
            context: context,
            builder: (innerContext) => CupertinoActionSheet(
              title: Text(isGuestMode ? 'おはなしをおわる' : selectTitle),
              message: isGuestMode
                  ? const Text(
                      '保存や同期を使うときは、保護者メニューからログインしてください。',
                    )
                  : null,
              actions: [
                if (!isGuestMode)
                  CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () async {
                      storyViewModel.confirmAction = ConfirmAction.save;
                      innerContext.pop();

                      final didSave = await storyViewModel.endButtonPressed(
                        mainViewModel: mainViewModel,
                      );

                      if (!didSave) {
                        return;
                      }

                      ref.invalidate(archiveViewModelProvider);

                      if (context.mounted) {
                        _goHome(context, ref);
                      }
                    },
                    child: const Text(
                      saveText,
                      style: TextStyle(color: Colors.pink),
                    ),
                  ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    storyViewModel.confirmAction = ConfirmAction.cancel;
                    innerContext.pop();
                    await storyViewModel.endButtonPressed(
                      mainViewModel: mainViewModel,
                    );
                    if (context.mounted) {
                      _goHome(context, ref);
                    }
                  },
                  child: Text(isGuestMode ? 'おわる' : noText),
                ),
              ],
            ),
          );
          break;
        case ToStoryPageType.initialValue:
          context.pop();
          break;
      }
    } catch (error) {
      debugPrint('End story flow failed: $error');
    }
  }

  void _goHome(BuildContext context, WidgetRef ref) {
    ref.read(bottomNavigationBarViewModelProvider).onPageChanged(0);
    context.go('/home');
  }
}
