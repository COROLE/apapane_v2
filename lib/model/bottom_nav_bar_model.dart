//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavigationBarProvider =
    ChangeNotifierProvider((ref) => BottomNavigationBarModel());

class BottomNavigationBarModel extends ChangeNotifier {
  int currentIndex = 0;
  late PageController pageController;

  BottomNavigationBarModel() {
    init();
  }

  void profileSavedAction() {
    currentIndex = 0;
    pageController.jumpToPage(0); // PageControllerも更新
    notifyListeners();
  }

  void init() {
    currentIndex = 0;
    pageController = PageController(initialPage: currentIndex, keepPage: false);
    notifyListeners();
  }

  void onPageChanged({required int index}) {
    currentIndex = index;
    notifyListeners();
  }

  void onTabTapped({required int index}) {
    currentIndex = index;
    pageController.jumpToPage(index); // Update the current page
    notifyListeners();
  }
}
