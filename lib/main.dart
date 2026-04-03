import 'package:apapane/config/app_env.dart';
import 'package:apapane/config/firebase_bootstrap.dart';
import 'package:apapane/constants/strings.dart';
import 'package:apapane/local/local_auth_session.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:apapane/views/common/bottom_nav_bar.dart';
import 'package:apapane/views/home_screen.dart';
import 'package:apapane/views/parent_hub_screen.dart';
import 'package:apapane/views/story_shelf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    await AppEnv.load();
    await FirebaseBootstrap.initialize();
    await LocalAuthSession.instance.restore();
    await LocalAuthSession.instance.ensureGuestSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootstrapErrorScreen(
              errorMessage: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _initialization = _initialize();
                });
              },
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootstrapLoadingScreen(),
          );
        }

        return const ProviderScope(child: MyApp());
      },
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: router,
      title: startUpperTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'ZenMaruGothic'),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '起動に失敗しました',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '初期設定を完了できませんでした。Firebase の設定、通信状態、ストア設定を確認してから、もう一度お試しください。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SelectableText(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bottomNavigationBarViewModelProvider)
          .initPageController(_pageController);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mainViewModel = ref.watch(mainViewModelProvider);
    final bottomNavigationBarViewModel =
        ref.watch(bottomNavigationBarViewModelProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: mainViewModel.isLoading
          ? const Center(child: Text(loadingText))
          : PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              onPageChanged: bottomNavigationBarViewModel.onPageChanged,
              children: const [
                HomeScreen(),
                StoryShelfScreen(),
                ParentHubScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBars(
        bottomNavigationBarViewModel: bottomNavigationBarViewModel,
      ),
    );
  }
}
