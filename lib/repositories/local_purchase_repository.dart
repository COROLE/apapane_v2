import 'dart:convert';
import 'dart:io';

import 'package:apapane/models/product/product.dart';
import 'package:apapane/models/purchase/local_purchase_state.dart';
import 'package:path_provider/path_provider.dart';

class LocalPurchaseRepository {
  static const String consumableId = 'consumable';
  static const String subscriptionId = 'silver_subscription';

  List<Product> getDemoProducts() {
    return const [
      Product(
        id: consumableId,
        title: 'コイン 1枚',
        description: 'ストーリー生成に使うコインを1枚追加します。',
        price: 'Demo',
        currencyCode: 'JPY',
        isSubscription: false,
      ),
      Product(
        id: subscriptionId,
        title: 'Silver Subscription',
        description: '30日間、毎月6コイン分のおはなし作成枠が使えます。',
        price: 'Demo',
        currencyCode: 'JPY',
        isSubscription: true,
      ),
    ];
  }

  Future<LocalPurchaseState> loadState(String uid) async {
    final file = await _stateFile(uid);
    if (!await file.exists()) {
      return LocalPurchaseState.initial();
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return LocalPurchaseState.initial();
    }
    return LocalPurchaseState.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<LocalPurchaseState> purchase(
    String uid,
    Product product,
  ) async {
    final currentState = await loadState(uid);
    final nextState = product.isSubscription
        ? currentState.copyWith(
            isSubscriptionActive: true,
            subscriptionEndAt: DateTime.now().add(const Duration(days: 30)),
          )
        : currentState.copyWith(coins: currentState.coins + 1);
    await _saveState(uid, nextState);
    return nextState;
  }

  Future<LocalPurchaseState> restore(String uid) => loadState(uid);

  Future<LocalPurchaseState> consumeCoin(String uid) async {
    final currentState = await loadState(uid);
    if (currentState.coins <= 0) {
      return currentState;
    }
    final nextState = currentState.copyWith(coins: currentState.coins - 1);
    await _saveState(uid, nextState);
    return nextState;
  }

  Future<LocalPurchaseState> cancelSubscription(String uid) async {
    final currentState = await loadState(uid);
    final nextState = currentState.copyWith(
      isSubscriptionActive: false,
      clearSubscriptionEndAt: true,
    );
    await _saveState(uid, nextState);
    return nextState;
  }

  Future<void> _saveState(String uid, LocalPurchaseState state) async {
    final file = await _stateFile(uid);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(state.toJson()),
    );
  }

  Future<File> _stateFile(String uid) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return File(
      '${documentsDirectory.path}${Platform.pathSeparator}apapane_local_store'
      '${Platform.pathSeparator}users${Platform.pathSeparator}$uid'
      '${Platform.pathSeparator}purchase_state.json',
    );
  }
}
