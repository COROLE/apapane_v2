import 'dart:io';

import 'package:apapane/core/firestore/col_ref_core.dart';
import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/firestore/query_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/ui_core/dialog_core.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product/product.dart';
import '../models/purchase/purchase.dart';
import '../repositories/purchase_repository.dart';

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseRepository _purchaseRepository;
  final FirestoreRepository _firestoreRepository;

  PurchaseViewModel(this._purchaseRepository, this._firestoreRepository) {
    _initialize();
  }

  bool _isLoading = true;
  bool _isRestoreLoading = false;
  List<Product> _products = [];
  int _coinCount = 0;
  bool _isAvailable = false;
  bool _isPurchaseInProgress = false;
  late bool _isSubscriptionActive;

  bool get isLoading => _isLoading;
  bool get isRestoreLoading => _isRestoreLoading;
  List<Product> get products => _products;
  int get coinCount => _coinCount;
  bool get isAvailable => _isAvailable;
  bool get isPurchaseInProgress => _isPurchaseInProgress;
  bool get isSubscriptionActive => _isSubscriptionActive;

  Future<void> _initialize() async {
    await _purchaseRepository.initialize();
    _purchaseRepository.setOnPurchaseCompletedCallback(_processPurchase);
    await _loadProducts();
    await _loadCoinCount();
    await _loadSubscriptionStatus();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final result = await _purchaseRepository.getProducts();
    result.when(success: (res) {
      _products = res.map((p) => Product.fromProductDetails(p)).toList();
      _isAvailable = _products.isNotEmpty;
      notifyListeners();
    }, failure: (_) async {
      await UIHelper.showFlutterToast('Failed to load products');
    });
  }

  Future<void> _loadCoinCount() async {
    final user = IDCore.authUser();
    if (user == null) return;
    final result = await _firestoreRepository
        .getDoc(DocRefCore.publicUserDocRef(user.uid));
    result.when(success: (doc) {
      final data = doc.data();
      _coinCount = data?['coins'] ?? 0;
      notifyListeners();
    }, failure: (_) async {
      await UIHelper.showFlutterToast('Failed to load coin count');
    });
  }

  Future<void> _loadSubscriptionStatus() async {
    final user = IDCore.authUser();
    if (user == null) return;
    final result = await _firestoreRepository
        .getDocs(QueryCore.subscriptionGetByEndDate(user.uid));
    result.when(success: (docs) {
      final now = DateTime.now();
      final activeSubscriptions = docs
          .map((doc) => Purchase.fromJson(doc.data()))
          .where((purchase) => purchase.endDate
              .toDate()
              .isAfter(now)) // Convert Timestamp to DateTime
          .toList();
      _isSubscriptionActive = activeSubscriptions.isNotEmpty;
      notifyListeners();
    }, failure: (_) async {
      await UIHelper.showFlutterToast('Failed to load subscription status');
    });
  }

  Future<void> purchaseProduct(Product product) async {
    _isPurchaseInProgress = true;
    notifyListeners();

    try {
      final productDetails = product.toProductDetails();
      final result = await _purchaseRepository.purchaseProduct(productDetails);
      result.when(success: (res) async {
        if (res.purchaseID.trim().isEmpty || res.productID.trim().isEmpty) {
          debugPrint('purchaseID is empty');
          return;
        }
        await _processPurchase(res);
      }, failure: (_) async {
        await UIHelper.showFlutterToast('Failed to purchase product');
      });
    } catch (e) {
      debugPrint(
          'Error purchaseProduct on purchase_view_model:${e.toString()}');
    } finally {
      _isPurchaseInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _processPurchase(Purchase purchase) async {
    if (_isRestoreLoading) return;
    final user = IDCore.authUser();
    if (user == null) return;
    if (purchase.productID == 'consumable') {
      final data = purchase.toJson();
      final result = await _firestoreRepository.createDoc(
          ColRefCore.consumablesColRef(user.uid).doc(purchase.purchaseID),
          data);
      result.when(success: (_) async {
        _coinCount++;
        notifyListeners();
        await UIHelper.showFlutterToast('コインを購入しました！');
      }, failure: (_) async {
        await UIHelper.showFlutterToast('Failed to update purchase');
      });
    } else {
      final data = Purchase.createWithDates(purchase: purchase).toJson();
      final result = await _firestoreRepository.createDoc(
          ColRefCore.subscriptionsColRef(user.uid).doc(purchase.purchaseID),
          data);
      await _loadSubscriptionStatus();
      result.when(success: (_) async {
        await UIHelper.showFlutterToast('サブスクリプションを購入しました！');
      }, failure: (_) async {
        await UIHelper.showFlutterToast('Failed to update purchase');
      });
    }
  }

  Future<void> restorePurchases() async {
    _isRestoreLoading = true;
    notifyListeners();

    final result = await _purchaseRepository.restorePurchases();
    result.when(success: (_) async {
      await _loadSubscriptionStatus();
      _isRestoreLoading = false;
      notifyListeners();
      await UIHelper.showFlutterToast('購入を復元しました！');
    }, failure: (_) async {
      _isRestoreLoading = false;
      await UIHelper.showFlutterToast('Failed to restore purchases');
    });
  }

  Future<void> consumeCoin() async {
    final user = IDCore.authUser();
    if (user == null) return;
    if (_coinCount <= 0) {
      await UIHelper.showFlutterToast('コインがありません');
      return;
    }
    final result = await _firestoreRepository
        .updateDoc(DocRefCore.publicUserDocRef(user.uid), {
      'coins': FieldValue.increment(-1),
    });
    result.when(success: (res) {
      _coinCount--;
      notifyListeners();
    }, failure: (_) async {
      await UIHelper.showFlutterToast('Failed to consume coin');
    });
  }

  void showCancelSubscriptionDialog(BuildContext context) {
    DialogCore.cupertinoAlertDialog(context, 'サブスクリプションのキャンセル',
        'サブスクリプションをキャンセルしますか。', _launchSubscriptionManagement);
  }

  Future<void> _launchSubscriptionManagement() async {
    final url = Platform.isAndroid
        ? 'https://play.google.com/store/account/subscriptions'
        : 'https://apps.apple.com/account/subscriptions';
    try {
      // ignore: deprecated_member_use
      if (await canLaunch(url)) {
        // ignore: deprecated_member_use
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint(e.toString());
      await UIHelper.showFlutterToast('サブスクの管理画面を開けませんでした');
    }
  }
}
