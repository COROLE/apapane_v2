import 'package:apapane/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginSignUpScreen extends ConsumerWidget {
  const LoginSignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(loginViewModelProvider);
    final theme = Theme.of(context);
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE4D4),
                Color(0xFFFFF4EF),
                Color(0xFFE2F1F0),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => context.go('/home'),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('アパパネにもどる'),
                            ),
                          ),
                          Text(
                            '保護者ログイン',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '保護者アカウントでログインすると、おはなしの同期、購入内容の管理、家族アカウントの設定ができます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF5A5A5A),
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (isIos) ...[
                            ElevatedButton.icon(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => viewModel.loginWithApple(
                                        context: context,
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF111111),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.apple),
                              label: const Text(
                                'Appleでログイン',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          ElevatedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () => viewModel.loginWithGoogle(
                                      context: context,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D7A63),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: viewModel.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Googleでログイン',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isIos
                                ? 'iPhone / iPad では、保護者が Apple または Google でログインできます。'
                                : 'Android では、保護者が Google ログインでおはなしを同期できます。',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 12,
                              height: 1.5,
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
        ),
      ),
    );
  }
}
