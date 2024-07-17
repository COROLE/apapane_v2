//flutter
import 'package:flutter/material.dart';

class BottomNavigationBarViewModel extends ChangeNotifier {
  int currentIndex = 0;
  late PageController pageController;

  BottomNavigationBarViewModel();

  void initPageController(PageController controller) {
    pageController = controller;
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  void onTabTapped(int index) {
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
    }
    currentIndex = index;
    notifyListeners();
  }

  void resetIndex() {
    currentIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
