import 'dart:io';

import 'package:apapane/models/product/product.dart';
import 'package:apapane/models/purchase/purchase_entitlements.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseRepository {
  PurchaseRepository({
    InAppPurchase? inAppPurchase,
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  })  : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const String consumableId = 'consumable';
  static const String subscriptionId = 'silver_subscription';
  static const String _androidPackageName = 'com.coroleai.apapaneapp';
  static const String _iosBundleId = 'com.corole.apapane';

  final InAppPurchase _inAppPurchase;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final Map<String, ProductDetails> _catalog = {};

  Stream<List<PurchaseDetails>> get purchaseUpdates =>
      _inAppPurchase.purchaseStream;

  Future<bool> isStoreAvailable() => _inAppPurchase.isAvailable();

  Future<List<Product>> loadProducts() async {
    const ids = {
      consumableId,
      subscriptionId,
    };
    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      _catalog.clear();
      return const [];
    }

    final response = await _inAppPurchase.queryProductDetails(ids);
    if (response.error != null) {
      throw StateError(response.error!.message);
    }

    _catalog
      ..clear()
      ..addEntries(
        response.productDetails.map(
          (product) => MapEntry(product.id, product),
        ),
      );

    final products = response.productDetails
        .map(Product.fromProductDetails)
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return products;
  }

  Future<void> buy(Product product) async {
    final details = _catalog[product.id];
    if (details == null) {
      throw StateError('商品情報を読み込めていません: ${product.id}');
    }

    final purchaseParam = PurchaseParam(productDetails: details);
    if (product.isSubscription) {
      final started =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        throw StateError('定期購入の処理を開始できませんでした。');
      }
      return;
    }

    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
    if (!started) {
      throw StateError('購入処理を開始できませんでした。');
    }
  }

  Future<void> restore() => _inAppPurchase.restorePurchases();

  Future<PurchaseEntitlements> loadEntitlements(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return PurchaseEntitlements.fromUserData(snapshot.data());
  }

  Future<PurchaseEntitlements> verifyPurchase(PurchaseDetails purchase) async {
    final callable = _functions.httpsCallable('verifyPurchase');
    final purchaseId =
        purchase.purchaseID ?? purchase.verificationData.serverVerificationData;
    final response = await callable.call({
      'platform': Platform.isAndroid ? 'android' : 'ios',
      'packageName': Platform.isAndroid ? _androidPackageName : _iosBundleId,
      'productId': purchase.productID,
      'purchaseId': purchaseId,
      'verificationData': purchase.verificationData.serverVerificationData,
      'source': purchase.verificationData.source,
    });
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('購入確認の応答が正しくありませんでした。');
    }
    return PurchaseEntitlements.fromUserData(data);
  }

  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _inAppPurchase.completePurchase(purchase);
    }
  }

  Future<PurchaseEntitlements> consumeCoin(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final currentCoins = (snapshot.data()?['coins'] as num?)?.toInt() ?? 0;
      if (currentCoins <= 0) {
        return;
      }
      transaction.update(userRef, {'coins': currentCoins - 1});
    });
    return loadEntitlements(uid);
  }

  Future<Uri?> subscriptionManagementUri() async {
    if (Platform.isIOS) {
      return Uri.parse('https://apps.apple.com/account/subscriptions');
    }
    if (Platform.isAndroid) {
      return Uri.parse(
        'https://play.google.com/store/account/subscriptions?sku='
        '$subscriptionId&package=$_androidPackageName',
      );
    }
    return null;
  }
}
