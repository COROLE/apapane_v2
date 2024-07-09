import 'package:apapane/typedefs/result_typedef.dart';
import '../models/result/result.dart';
import '../services/purchase/purchase_service.dart';
import '../models/purchase/purchase.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseRepository {
  final PurchaseService _purchaseService;

  PurchaseRepository(this._purchaseService);

  FutureResult<bool> initialize() async {
    try {
      await _purchaseService.initialize();
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> setOnPurchaseCompletedCallback(
      void Function(Purchase) callback) async {
    try {
      _purchaseService.setOnPurchaseCompletedCallback(callback);
      return const Result.success(true);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<List<ProductDetails>> getProducts() async {
    try {
      final result = await _purchaseService.getProducts();
      return Result.success(result);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<Purchase> purchaseProduct(ProductDetails product) async {
    try {
      final result = await _purchaseService.purchaseProduct(product);
      return Result.success(result);
    } catch (e) {
      return const Result.failure();
    }
  }

  FutureResult<bool> restorePurchases() async {
    try {
      final result = await _purchaseService.restorePurchases();
      return Result.success(result);
    } catch (e) {
      return const Result.failure();
    }
  }
}
