import 'dart:async';

import 'package:apapane/core/firestore/doc_ref_core.dart';
import 'package:apapane/core/id_core/id_core.dart';
import 'package:apapane/models/product/product.dart';
import 'package:apapane/models/purchase/purchase_entitlements.dart';
import 'package:apapane/repositories/firestore_repository.dart';
import 'package:apapane/repositories/purchase_repository.dart';
import 'package:apapane/ui_core/dialog_core.dart';
import 'package:apapane/ui_core/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseViewModel extends ChangeNotifier {
  PurchaseViewModel(this._purchaseRepository, this._firestoreRepository) {
    _initialize();
  }

  final PurchaseRepository _purchaseRepository;
  final FirestoreRepository _firestoreRepository;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isLoading = true;
  bool _isRestoreLoading = false;
  List<Product> _products = [];
  int _coinCount = 0;
  bool _isAvailable = false;
  bool _isPurchaseInProgress = false;
  bool _isSubscriptionActive = false;

  bool get isLoading => _isLoading;
  bool get isRestoreLoading => _isRestoreLoading;
  List<Product> get products => _products;
  int get coinCount => _coinCount;
  bool get isAvailable => _isAvailable;
  bool get isPurchaseInProgress => _isPurchaseInProgress;
  bool get isSubscriptionActive => _isSubscriptionActive;

  Future<void> _initialize() async {
    _purchaseSubscription ??=
        _purchaseRepository.purchaseUpdates.listen(_handlePurchaseUpdates);
    try {
      _isAvailable = await _purchaseRepository.isStoreAvailable();
      _products = await _purchaseRepository.loadProducts();
      await _loadState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadState() async {
    final user = IDCore.authUser();
    if (user == null || user.isGuest) {
      _coinCount = 0;
      _isSubscriptionActive = false;
      return;
    }
    final state = await _purchaseRepository.loadEntitlements(user.uid);
    _applyEntitlements(state);
    await _syncProfileCoins(user.uid);
    notifyListeners();
  }

  Future<void> purchaseProduct(Product product) async {
    final user = IDCore.authUser();
    if (user == null || user.isGuest || _isPurchaseInProgress) {
      return;
    }

    _isPurchaseInProgress = true;
    notifyListeners();
    try {
      await _purchaseRepository.buy(product);
    } catch (error) {
      _isPurchaseInProgress = false;
      notifyListeners();
      await UIHelper.showFlutterToast(error.toString());
    }
  }

  Future<void> restorePurchases() async {
    final user = IDCore.authUser();
    if (user == null || user.isGuest) {
      return;
    }
    _isRestoreLoading = true;
    notifyListeners();
    try {
      await _purchaseRepository.restore();
      await Future<void>.delayed(const Duration(seconds: 1));
      final state = await _purchaseRepository.loadEntitlements(user.uid);
      _applyEntitlements(state);
      await _syncProfileCoins(user.uid);
      await UIHelper.showFlutterToast('購入内容を復元しました。');
    } catch (error) {
      await UIHelper.showFlutterToast(error.toString());
    } finally {
      _isRestoreLoading = false;
      notifyListeners();
    }
  }

  Future<void> consumeCoin() async {
    final user = IDCore.authUser();
    if (user == null || user.isGuest) {
      return;
    }
    if (_coinCount <= 0) {
      await UIHelper.showFlutterToast('コインがありません。');
      return;
    }
    final state = await _purchaseRepository.consumeCoin(user.uid);
    _applyEntitlements(state);
    await _syncProfileCoins(user.uid);
    notifyListeners();
  }

  void manageSubscription(BuildContext context) {
    DialogCore.cupertinoAlertDialog(
      context,
      '定期購入の管理画面を開きますか？',
      '定期購入の管理は App Store または Google Play で行います。',
      () async {
        Navigator.pop(context);
        final uri = await _purchaseRepository.subscriptionManagementUri();
        if (uri == null) {
          await UIHelper.showFlutterToast(
            '定期購入の管理画面を開けませんでした。',
          );
          return;
        }
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          await UIHelper.showFlutterToast('ストアのページを開けませんでした。');
        }
      },
    );
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final user = IDCore.authUser();
    if (user == null || user.isGuest) {
      return;
    }

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isPurchaseInProgress = true;
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final state = await _purchaseRepository.verifyPurchase(purchase);
            _applyEntitlements(state);
            await _syncProfileCoins(user.uid);
            await UIHelper.showFlutterToast(
              purchase.productID == PurchaseRepository.subscriptionId
                  ? '定期購入の状態を更新しました。'
                  : '購入内容を反映しました。',
            );
          } catch (error) {
            await UIHelper.showFlutterToast(error.toString());
          } finally {
            _isPurchaseInProgress = false;
            _isRestoreLoading = false;
            await _purchaseRepository.completePurchase(purchase);
            notifyListeners();
          }
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _isPurchaseInProgress = false;
          _isRestoreLoading = false;
          final purchaseError = purchase.error;
          final message = purchaseError?.message.trim();
          if (message != null && message.isNotEmpty) {
            await UIHelper.showFlutterToast(message);
          }
          await _purchaseRepository.completePurchase(purchase);
          notifyListeners();
          break;
      }
    }
  }

  void _applyEntitlements(PurchaseEntitlements state) {
    _coinCount = state.coins;
    _isSubscriptionActive = state.isSubscriptionActive;
  }

  Future<void> _syncProfileCoins(String uid) async {
    await _firestoreRepository.updateDoc(
      DocRefCore.publicUserDocRef(uid),
      {'coins': _coinCount},
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
