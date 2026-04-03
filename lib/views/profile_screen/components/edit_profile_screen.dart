import 'package:apapane/constants/strings.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:apapane/providers/simple_firestore_providers.dart';
import 'package:apapane/ui_core/dialog_core.dart';
import 'package:apapane/views/common/circle_progress_indicator.dart';
import 'package:apapane/views/common/icon_image.dart';
import 'package:apapane/views/common/original_flash_bar.dart';
import 'package:apapane/views/common/rounded_button.dart';
import 'package:apapane/views/common/rounded_profile_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainViewModel = ref.watch(mainViewModelProvider);
    final editProfileViewModel = ref.watch(editProfileViewModelProvider);
    final bottomNavBarViewModel =
        ref.watch(bottomNavigationBarViewModelProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final actionButtonWidth = screenWidth > 600 ? 0.4 : 0.72;

    return editProfileViewModel.isLoading
        ? const CircleProgressIndicator(
            message: 'プロフィールを保存しています...',
            circleIndicatorImage: updateProfileImage,
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text('プロフィール編集'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextButton(
                    onPressed: () {
                      DialogCore.cupertinoAlertDialog(
                        context,
                        'ログアウトしますか？',
                        'この端末の保護者アカウントをログアウトして、ゲストモードに戻します。',
                        () async => mainViewModel.logout(
                          context: context,
                          bottomNavBarViewModel: bottomNavBarViewModel,
                        ),
                      );
                    },
                    child: const Text(
                      'ログアウト',
                      style: TextStyle(
                        color: Color(0xFF2D5301),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                Image.asset(
                  judgeBackground,
                  fit: BoxFit.cover,
                  height: screenHeight,
                  width: double.infinity,
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Text(
                                  '保護者プロフィール',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2B2B2B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'アカウント名や画像、サポート情報をここで管理できます。',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF666666),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                RoundedProfileIcon(
                                  child: IconImage(
                                    length: 120,
                                    iconImageData:
                                        editProfileViewModel.croppedImage,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: editProfileViewModel.selectImage,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF4C542),
                                    foregroundColor: const Color(0xFF2B2B2B),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.photo_camera_back),
                                  label: const Text(
                                    '画像を変更',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OriginalFlashBar(
                                    controller:
                                        editProfileViewModel.nameController,
                                    hintText:
                                        mainViewModel.firestoreUser.userName,
                                    height: 60,
                                    onPressed: () {},
                                    isSend: false,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                RoundedButton(
                                  onPressed: () =>
                                      editProfileViewModel.saveButtonPressed(
                                    context,
                                    mainViewModel,
                                    bottomNavBarViewModel,
                                  ),
                                  widthRate: actionButtonWidth,
                                  color: editProfileViewModel.isChanged
                                      ? const Color(0xFFE45C5C)
                                      : const Color(0xFF2D7A63),
                                  text: editProfileViewModel.isChanged
                                      ? '変更を保存'
                                      : 'ホームに戻る',
                                ),
                                const SizedBox(height: 28),
                                _SectionCard(
                                  title: 'ご案内',
                                  child: Column(
                                    children: [
                                      _ActionButton(
                                        icon: Icons.privacy_tip_outlined,
                                        label: 'プライバシーポリシー',
                                        onPressed: editProfileViewModel
                                            .openPrivacyPolicy,
                                      ),
                                      const SizedBox(height: 12),
                                      _ActionButton(
                                        icon: Icons.description_outlined,
                                        label: '利用規約',
                                        onPressed: editProfileViewModel
                                            .openTermsOfService,
                                      ),
                                      const SizedBox(height: 12),
                                      _ActionButton(
                                        icon: Icons.mail_outline,
                                        label: 'お問い合わせ',
                                        onPressed: editProfileViewModel
                                            .openSupportEmail,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'アカウント操作',
                                  child: Column(
                                    children: [
                                      _ActionButton(
                                        icon: Icons.logout,
                                        label: 'ログアウト',
                                        onPressed: () {
                                          DialogCore.cupertinoAlertDialog(
                                            context,
                                            'ログアウトしますか？',
                                            'この端末の保護者アカウントをログアウトして、ゲストモードに戻します。',
                                            () async => mainViewModel.logout(
                                              context: context,
                                              bottomNavBarViewModel:
                                                  bottomNavBarViewModel,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _ActionButton(
                                        icon: Icons.delete_outline,
                                        label: 'アカウントを削除',
                                        isDestructive: true,
                                        onPressed: () {
                                          DialogCore.cupertinoAlertDialog(
                                            context,
                                            'アカウントを削除しますか？',
                                            'アパパネのアカウントと同期済みのおはなしデータが削除されます。',
                                            () async {
                                              Navigator.pop(context);
                                              await editProfileViewModel
                                                  .deleteAccountPressed(
                                                context,
                                                mainViewModel,
                                                bottomNavBarViewModel,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      if (mainViewModel.firestoreUser.isAdmin)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 12),
                                          child: _ActionButton(
                                            icon: Icons.admin_panel_settings,
                                            label: '管理者ツール',
                                            isDark: true,
                                            onPressed: () =>
                                                context.push('/admin'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E0D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF343434),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.isDark = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? const Color(0xFFFFE5E5)
        : isDark
            ? const Color(0xFF2B2B2B)
            : Colors.white;
    final foregroundColor = isDestructive
        ? const Color(0xFFC62828)
        : isDark
            ? Colors.white
            : const Color(0xFF2D2D2D);
    final borderColor = isDestructive
        ? const Color(0xFFF1B7B7)
        : isDark
            ? const Color(0xFF2B2B2B)
            : const Color(0xFFD4D0C8);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
