import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/services/firestore/firestore_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/purchase/purchase_service.dart';
import '../repositories/purchase_repository.dart';
import '../view_models/purchase_view_model.dart';

final purchaseServiceProvider =
    Provider<PurchaseService>((ref) => PurchaseService());
final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(
    ref.read(purchaseServiceProvider),
  );
});
final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(
    ref.read(firestoreServiceProvider),
  );
});

final purchaseViewModelProvider =
    ChangeNotifierProvider<PurchaseViewModel>((ref) {
  return PurchaseViewModel(ref.read(purchaseRepositoryProvider),
      ref.read(firestoreRepositoryProvider));
});
