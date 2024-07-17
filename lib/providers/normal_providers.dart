import 'package:apapane/view_models/bottom_nav_bar_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavigationBarViewModelProvider =
    ChangeNotifierProvider((ref) => BottomNavigationBarViewModel());
