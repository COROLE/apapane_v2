import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/ui_core/dialog_core.dart';
import 'package:apapane/ui_core/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParentHubScreen extends ConsumerStatefulWidget {
  const ParentHubScreen({super.key});

  @override
  ConsumerState<ParentHubScreen> createState() => _ParentHubScreenState();
}

class _ParentHubScreenState extends ConsumerState<ParentHubScreen> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    final mainViewModel = ref.watch(mainViewModelProvider);
    final editProfileViewModel = ref.read(editProfileViewModelProvider);
    final bottomNavBarViewModel =
        ref.read(bottomNavigationBarViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('保護者メニュー'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: !_isUnlocked
                ? _buildLockedCard(context)
                : ListView(
                    children: [
                      _buildSectionCard(
                        title: mainViewModel.hasSyncedAccount
                            ? '保護者アカウント: ${mainViewModel.displayName}'
                            : 'ゲストであそんでいます',
                        body: mainViewModel.hasSyncedAccount
                            ? 'ここでは、家族アカウントや購入内容、各種ご案内を保護者の方が管理できます。'
                            : 'ゲストのままでもおはなしは作れます。保護者がログインすると、端末をまたいで保存したり購入内容を管理したりできます。',
                      ),
                      const SizedBox(height: 16),
                      if (mainViewModel.hasSyncedAccount) ...[
                        FilledButton(
                          onPressed: () {
                            editProfileViewModel.init(mainViewModel);
                            context.push('/edit/profile');
                          },
                          child: const Text('プロフィールを管理'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.push('/parent/store'),
                          child: const Text('購入内容を管理'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () {
                            DialogCore.cupertinoAlertDialog(
                              context,
                              'ログアウトしますか？',
                              'この端末ではゲストモードに戻ります。',
                              () async {
                                setState(() {
                                  _isUnlocked = false;
                                });
                                await mainViewModel.logout(
                                  context: context,
                                  bottomNavBarViewModel: bottomNavBarViewModel,
                                );
                              },
                            );
                          },
                          child: const Text('ログアウト'),
                        ),
                      ] else ...[
                        FilledButton(
                          onPressed: () => context.push('/login'),
                          child: const Text('保護者ログイン'),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton(
                            onPressed: editProfileViewModel.openPrivacyPolicy,
                            child: const Text('プライバシーポリシー'),
                          ),
                          OutlinedButton(
                            onPressed: editProfileViewModel.openTermsOfService,
                            child: const Text('利用規約'),
                          ),
                          OutlinedButton(
                            onPressed: editProfileViewModel.openSupportEmail,
                            child: const Text('お問い合わせ'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: Color(0xFF2D7A63),
            ),
            const SizedBox(height: 16),
            const Text(
              '保護者エリア',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ログイン、購入、外部リンクは、子ども向け配信に合わせて保護者確認のあとに開けるようにしています。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5A5A5A),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final unlocked = await showParentalGate(context);
                if (!mounted || !unlocked) {
                  return;
                }
                setState(() {
                  _isUnlocked = true;
                });
              },
              child: const Text('保護者メニューをひらく'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String body,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFF5A5A5A),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
