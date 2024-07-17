import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:flutter/material.dart';
//views
import 'package:apapane/views/archive_screen.dart';
import 'package:apapane/views/home_screen.dart';
import 'package:apapane/views/profile_screen/profile_screen.dart';
import 'package:apapane/views/public_screen.dart';
//packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
//options
import 'gen/firebase_options.dart';
//constants
import 'package:apapane/constants/strings.dart';
import 'app/router.dart';
//components
import 'package:apapane/views/common/bottom_nav_bar.dart';
import 'views/purchase_page.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: router,
      title: startUpperTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "ZenMaruGothic",
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
          ? const Center(
              child: Text(loadingText),
            )
          : PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              onPageChanged: (index) =>
                  bottomNavigationBarViewModel.onPageChanged(index),
              children: const [
                HomeScreen(),
                PublicScreen(),
                ArchiveScreen(),
                PurchasePage(),
                ProfileScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBars(
        bottomNavigationBarViewModel: bottomNavigationBarViewModel,
      ),
    );
  }
}
