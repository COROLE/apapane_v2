//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';

final purchaseProvider = ChangeNotifierProvider((ref) => PurchaseModel());

class PurchaseModel extends ChangeNotifier {}
