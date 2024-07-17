import 'package:flutter/material.dart';
import 'package:apapane/views/common/bottom_nav_bar_element.dart';
import 'package:apapane/view_models/bottom_nav_bar_view_model.dart';

class BottomNavigationBars extends StatelessWidget {
  const BottomNavigationBars(
      {super.key, required this.bottomNavigationBarViewModel});

  final BottomNavigationBarViewModel bottomNavigationBarViewModel;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.shifting,
      items: bottomNavigationBarElements,
      currentIndex: bottomNavigationBarViewModel.currentIndex,
      onTap: (index) {
        bottomNavigationBarViewModel.onTabTapped(index);
      },
      selectedItemColor: Colors.pink,
      unselectedItemColor: Colors.grey,
    );
  }
}
