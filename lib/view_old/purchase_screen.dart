import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:apapane/constants/others.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apapane/constants/voids.dart' as voids;
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final bool _kAutoConsume = Platform.isIOS || true;
const String _kConsumableId = 'consumable';
const String _kSilverSubscriptionId = 'silver_subscription';
const List<String> _kProductIds = <String>[
  _kConsumableId,
  _kSilverSubscriptionId
];

class PurchasePage extends StatefulWidget {
  const PurchasePage({super.key});

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final Set<String> _processedPurchaseIDs = <String>{};
  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  final List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  bool _isPurchaseInProgress = false;
  bool _isAvailable = false;
  bool _loading = true;
  int _coinCount = 0; // コイン数を保持する新しい変数

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription =
        purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      debugPrint('Error in purchase stream: $error');
    });
    initStoreInfo();
    _loadCoinCount(); // コイン数を初期化するために必要
    _completePendingPurchases(); // 保留中のトランザクションを完了する
  }

  // 保留中のトランザクションを完了する
  Future<void> _completePendingPurchases() async {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      final SKPaymentQueueWrapper queue = SKPaymentQueueWrapper();
      final List<SKPaymentTransactionWrapper> transactions =
          await queue.transactions();
      for (final SKPaymentTransactionWrapper transaction in transactions) {
        if (transaction.transactionState ==
            SKPaymentTransactionStateWrapper.purchased) {
          await queue.finishTransaction(transaction);
        }
      }
    } else if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final QueryPurchaseDetailsResponse purchaseResponse =
          await androidPlatformAddition.queryPastPurchases();
      for (final PurchaseDetails purchase in purchaseResponse.pastPurchases) {
        if (purchase.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchase);
        }
      }
    }
  }

  // コイン数をデータベースから読み込む
  Future<void> _loadCoinCount() async {
    final user = returnAuthUser();
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _coinCount = userDoc['coins'] ?? 0;
        });
        debugPrint('Coin count loaded: $_coinCount');
      }
    }
  }

  Future<void> initStoreInfo() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        setState(() {
          _isAvailable = isAvailable;
          _loading = false;
        });
        return;
      }

      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      }

      final ProductDetailsResponse productDetailResponse =
          await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
      if (productDetailResponse.error != null) {
        setState(() {});
        return;
      }

      if (productDetailResponse.productDetails.isEmpty) {
        setState(() {});
        return;
      }

      setState(() {
        _isAvailable = isAvailable;
        _products = _sortProducts(productDetailResponse.productDetails);
        _notFoundIds = productDetailResponse.notFoundIDs;
        _loading = false;
      });
    } catch (e) {
      await voids.showFluttertoast(msg: 'Error on initStoreInfo: $e');
      debugPrint('Error: $e');
    }
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

  @override
  void dispose() {
    _subscription.cancel();
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    } else {
      debugPrint('Attempted to call setState() on an unmounted State object.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('おかいものページ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.yellow,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[100]!, Colors.purple[100]!],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildParentInfo(),
                    const SizedBox(height: 20),
                    _buildProductList(),
                    const SizedBox(height: 20),
                    _buildConsumableBox(),
                    const SizedBox(height: 20),
                    _buildRestoreButton(),
                    const SizedBox(height: 20),
                    _buildSubscriptionCancelButton(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildParentInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '保護者の方へ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'このページでは、お子様が使用できるアイテムを購入できます。購入前に内容をご確認ください。',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'おかいものリスト',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._products.map((product) => _buildProductItem(product)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(ProductDetails product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          product.id == _kConsumableId ? Icons.star : Icons.card_membership,
          color: Colors.orange,
          size: 48,
        ),
        title: Text(
          product.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(product.description),
        trailing: _buildPurchaseButton(product),
      ),
    );
  }

  Widget _buildPurchaseButton(ProductDetails product) {
    return ElevatedButton(
      onPressed: _isPurchaseInProgress ? null : () => _handlePurchase(product),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        product.price,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _handlePurchase(ProductDetails product) async {
    try {
      // 保留中の購入がないか確認
      final bool hasPendingPurchase = _purchases.any((purchase) =>
          purchase.productID == product.id &&
          purchase.status == PurchaseStatus.pending);
      if (hasPendingPurchase) {
        await voids.showFluttertoast(msg: '保留中の購入があります。しばらくお待ちください。');
        return;
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      if (product.id == _kConsumableId) {
        _inAppPurchase.buyConsumable(
          purchaseParam: purchaseParam,
          autoConsume: _kAutoConsume || Platform.isIOS,
        );
      } else {
        _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }
    } catch (e) {
      await voids.showFluttertoast(msg: 'Error on _buildPurchaseButton: $e');
      debugPrint('Error: $e');
    }
  }

  Card _buildConsumableBox() {
    if (_loading) {
      return const Card(
          child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Fetching consumables…')));
    }
    if (!_isAvailable || _notFoundIds.contains(_kConsumableId)) {
      return const Card();
    }
    const ListTile consumableHeader =
        ListTile(title: Text('Purchased consumables'));
    return Card(
      child: Column(
        children: [
          consumableHeader,
          const Divider(),
          Column(children: [
            ListTile(
              leading:
                  const Icon(Icons.stars, size: 42.0, color: Colors.orange),
              title: const Text('こはく'),
              trailing: Text(
                  'x$_coinCount'), // _consumables.length の代わりに _coinCount を使用
              onTap: () {
                _handleConsumablePressed();
              },
            )
          ]),
        ],
      ),
    );
  }

  Widget _buildRestoreButton() {
    if (_loading) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
          style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white),
          onPressed: () async {
            try {
              _inAppPurchase.restorePurchases();
            } catch (e) {
              await voids.showFluttertoast(
                  msg: 'Error on restorePurchases: $e');
              debugPrint('Error: $e');
            }
          },
          child: const Text('Restore purchases'),
        ),
      ]),
    );
  }

  Widget _buildSubscriptionCancelButton() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
          style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          onPressed: () => _showCancelSubscriptionDialog(context),
          child: const Text('Cancel Subscription'),
        ),
      ]),
    );
  }

  void _showCancelSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Subscription'),
          content: const Text(
              'Are you sure you want to cancel your subscription? This action will take you to the subscription management page.'),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchSubscriptionManagement();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchSubscriptionManagement() async {
    final url = Platform.isAndroid
        ? 'https://play.google.com/store/account/subscriptions'
        : 'https://apps.apple.com/account/subscriptions';
    // ignore: deprecated_member_use
    if (await canLaunch(url)) {
      // ignore: deprecated_member_use
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // コインを消費する処理を修正
  void _handleConsumablePressed() async {
    try {
      if (_coinCount > 0) {
        await _consumeCoin();
      } else {
        await voids.showFluttertoast(msg: 'コインがありません');
      }
    } catch (e) {
      await voids.showFluttertoast(
          msg: 'Error on _handleConsumablePressed: $e');
      debugPrint('Error on _handleConsumablePressed: $e');
    }
  }

  // コインを消費する処理
  Future<void> _consumeCoin() async {
    final user = returnAuthUser();
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'coins': FieldValue.increment(-1),
      });
      setState(() {
        _coinCount--;
      });
      await voids.showFluttertoast(msg: 'コインを消費しました！ありがとう！');
      debugPrint('Coin consumed. Current coin count: $_coinCount');
    }
  }

  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    try {
      if (_processedPurchaseIDs.contains(purchaseDetails.purchaseID)) {
        debugPrint('Purchase already processed: ${purchaseDetails.purchaseID}');
        return; // 既に処理済みの購入はスキップ
      }

      if (purchaseDetails.productID == _kSilverSubscriptionId) {
        setState(() {});
        await _updateDatabaseWithPurchase(purchaseDetails);
        await voids.showFluttertoast(msg: 'プレミアムパスをゲットしました！ありがとう！');
      } else if (purchaseDetails.productID == _kConsumableId) {
        await _updateDatabaseWithPurchase(purchaseDetails);
        await voids.showFluttertoast(msg: 'チャージが完了しました！ありがとう！');
      }

      _processedPurchaseIDs.add(purchaseDetails.purchaseID!);
      setState(() {});
    } catch (e) {
      await voids.showFluttertoast(msg: 'Error on deliverProduct: $e');
      debugPrint('Error on deliverProduct: $e');
    }
  }

  Future _verifySubscriptionAndUpdate(PurchaseDetails purchaseDetails) async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String packageName = packageInfo.packageName;
      final Map<String, dynamic> requestBody = {
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'productID': purchaseDetails.productID,
      };
      if (Platform.isAndroid) {
        requestBody['packageName'] = packageName;
        requestBody['purchaseToken'] =
            purchaseDetails.verificationData.serverVerificationData;
      } else if (Platform.isIOS) {
        requestBody['receiptData'] =
            purchaseDetails.verificationData.serverVerificationData;
      }
      final response = await http.post(
        Uri.parse(
            'https://us-central1-apapane-3cca0.cloudfunctions.net/verifyPurchase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['valid']) {
          await _updateDatabaseWithPurchase(purchaseDetails);
          if (!_processedPurchaseIDs.contains(purchaseDetails.purchaseID)) {
            await voids.showFluttertoast(msg: 'サブスクリプションが更新されました！');
          }
          _processedPurchaseIDs
              .add(purchaseDetails.purchaseID!); // 購入が処理済みであることを記録
          return true;
        } else {
          return false;
        }
      } else {
        debugPrint(
            'Error on _verifySubscriptionAndUpdate: ${response.body} ${response.statusCode}');
        return false;
      }
    } catch (e) {
      await voids.showFluttertoast(
          msg: 'Error on _verifySubscriptionAndUpdate: $e');
      debugPrint('Error on _verifySubscriptionAndUpdate: $e');
      return false;
    }
  }

  Future<void> _updateDatabaseWithPurchase(
      PurchaseDetails purchaseDetails) async {
    try {
      final user = returnAuthUser();
      if (user != null) {
        final purchaseMap = {
          'productID': purchaseDetails.productID,
          'purchaseID': purchaseDetails.purchaseID,
          'transactionDate': purchaseDetails.transactionDate,
          'verificationData': {
            'localVerificationData':
                purchaseDetails.verificationData.localVerificationData,
            'serverVerificationData':
                purchaseDetails.verificationData.serverVerificationData,
          },
          'status': purchaseDetails.status.toString(),
        };

        debugPrint('Updating Firestore with purchaseMap: $purchaseMap');

        if (purchaseDetails.productID == _kSilverSubscriptionId) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final List existingPurchases = userDoc['purchases'] ?? [];
          existingPurchases.removeWhere(
              (purchase) => purchase['productID'] == purchaseDetails.productID);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'purchases': FieldValue.arrayUnion([purchaseMap]),
          });
        } else if (purchaseDetails.productID == _kConsumableId) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'coins': FieldValue.increment(1),
          });
          setState(() {
            _coinCount++;
          });

          // デバッグログを追加
          debugPrint('Coins incremented. Current coin count: $_coinCount');
        }
      }
    } catch (e) {
      await voids.showFluttertoast(
          msg: 'Error on _updateDatabaseWithPurchase: $e');
      debugPrint('Error on _updateDatabaseWithPurchase: $e');
    } finally {
      setState(() {
        _isPurchaseInProgress = false;
      });
    }
  }

  void showPendingUI() {
    setState(() {});
  }

  void handleError(IAPError error) async {
    setState(() {
      _isPurchaseInProgress = false;
    });
    await voids.showFluttertoast(msg: 'Error on handleError: ${error.message}');
    debugPrint('Error: ${error.message}');
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) async {
    await voids.showFluttertoast(
        msg: 'Invalid purchase: ${purchaseDetails.productID}');
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    try {
      for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
        if (purchaseDetails.purchaseID == null ||
            _processedPurchaseIDs.contains(purchaseDetails.purchaseID)) {
          debugPrint(
              'Skipping already processed purchase: ${purchaseDetails.purchaseID}');
          continue;
        }
        if (purchaseDetails.status == PurchaseStatus.pending) {
          showPendingUI();
        } else {
          if (purchaseDetails.status == PurchaseStatus.error) {
            handleError(purchaseDetails.error!);
          } else if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            if (purchaseDetails.productID == _kSilverSubscriptionId) {
              final valid = await _verifySubscriptionAndUpdate(purchaseDetails);
              if (valid) {
                await deliverProduct(purchaseDetails);
              } else {
                _handleInvalidPurchase(purchaseDetails);
                continue;
              }
            } else {
              await deliverProduct(purchaseDetails);
            }
          } else {
            _handleInvalidPurchase(purchaseDetails);
            continue;
          }
          if (Platform.isAndroid &&
              !_kAutoConsume &&
              purchaseDetails.productID == _kConsumableId) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                _inAppPurchase.getPlatformAddition();
            await androidAddition.consumePurchase(purchaseDetails);
          }
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
        _processedPurchaseIDs.add(purchaseDetails.purchaseID!);
      }

      setState(() {
        _purchases.addAll(purchaseDetailsList);
      });

      debugPrint('_purchases after update: $_purchases');
      debugPrint('_coinCount after update: $_coinCount');
    } catch (e) {
      await voids.showFluttertoast(
          msg: 'Error on _listenToPurchaseUpdated: $e');
      debugPrint('Error on _listenToPurchaseUpdated: $e');
    }
  }

  Future confirmPriceChange(BuildContext context) async {
    try {
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition
            iapStoreKitPlatformAddition = _inAppPurchase.getPlatformAddition();
        await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
      }
    } catch (e) {
      await voids.showFluttertoast(msg: 'Error on confirmPriceChange: $e');
      debugPrint('Error on confirmPriceChange: $e');
    }
  }
}

/// Example implementation of the SKPaymentQueueDelegate.
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
