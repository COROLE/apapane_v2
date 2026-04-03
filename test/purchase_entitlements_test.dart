import 'package:apapane/models/purchase/purchase_entitlements.dart';
import 'package:apapane/local/local_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns initial entitlements when user data is missing', () {
    final entitlements = PurchaseEntitlements.fromUserData(null);

    expect(entitlements.coins, 0);
    expect(entitlements.isSubscriptionActive, isFalse);
    expect(entitlements.subscriptionEndAt, isNull);
  });

  test('parses active subscription and coins from Firestore user data', () {
    final future = DateTime.now().add(const Duration(days: 30));
    final entitlements = PurchaseEntitlements.fromUserData({
      'coins': 3,
      'silverSubscription': {
        'isActive': true,
        'endAt': Timestamp.fromDate(future),
      },
    });

    expect(entitlements.coins, 3);
    expect(entitlements.isSubscriptionActive, isTrue);
    expect(entitlements.subscriptionEndAt, future);
  });
}
