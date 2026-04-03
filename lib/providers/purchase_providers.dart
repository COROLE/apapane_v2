import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/repositories/purchase_repository.dart';
import 'package:apapane/view_models/purchase_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository();
});

final purchaseViewModelProvider =
    ChangeNotifierProvider<PurchaseViewModel>((ref) {
  return PurchaseViewModel(
    ref.read(purchaseRepositoryProvider),
    ref.read(firestoreRepositoryProvider),
  );
});
