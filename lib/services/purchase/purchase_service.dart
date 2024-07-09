import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../../../models/purchase/purchase.dart';

class PurchaseService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static const String consumableId = 'consumable';
  static const String silverSubscriptionId = 'silver_subscription';
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  static const List<String> _kProductIds = <String>[
    consumableId,
    silverSubscriptionId
  ];

  void Function(Purchase)? _onPurchaseCompleted;

  Future<void> initialize() async {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(_onPurchaseUpdate,
        onDone: _onPurchaseDone, onError: _onPurchaseError);

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }
  }

  void setOnPurchaseCompletedCallback(void Function(Purchase) callback) {
    _onPurchaseCompleted = callback;
  }

  List<ProductDetails> _sortProducts(List<ProductDetails> products) {
    final Map<String, ProductDetails> productMap = {
      for (var product in products) product.id: product
    };
    return _kProductIds
        .where((id) => productMap.containsKey(id))
        .map((id) => productMap[id]!)
        .toList();
  }

  Future<List<ProductDetails>> getProducts() async {
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    final sortedResponse = _sortProducts(response.productDetails);
    return sortedResponse;
  }

  Future<Purchase> purchaseProduct(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    if (product.id == consumableId) {
      await _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam, autoConsume: Platform.isIOS || true);
    } else {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    }

    // 購入の完了を待つ
    final purchaseDetails = await _waitForPurchaseCompletion(product.id);

    return Purchase.fromPurchaseDetails(purchaseDetails);
  }

  Future<PurchaseDetails> _waitForPurchaseCompletion(String productId) async {
    final Completer<PurchaseDetails> completer = Completer();
    final StreamSubscription<List<PurchaseDetails>> subscription =
        _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      for (var purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.productID == productId) {
          completer.complete(purchaseDetails);
          break;
        }
      }
    });

    final purchaseDetails = await completer.future;
    await subscription.cancel(); // 購読をキャンセル
    return purchaseDetails;
  }

  Future<bool> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
    return true;
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // 購入が完了した場合の処理
        final purchase = Purchase.fromPurchaseDetails(purchaseDetails);
        // ここで購入情報を保存するか、他の処理を行います
        debugPrint('Purchase completed: $purchase');
        _onPurchaseCompleted?.call(purchase);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // エラーが発生した場合の処理
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }
    }
  }

  void _onPurchaseDone() {
    _subscription.cancel();
  }

  void _onPurchaseError(error) {
    debugPrint('Error in purchase stream: $error');
  }
}

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
