import 'package:apapane/repositories/purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final activeSubscriptionEnd = DateTime(2026, 4, 11);
  final expiredSubscriptionEnd = DateTime(2026, 4, 9);
  final now = DateTime(2026, 4, 10);

  test('story creation preflight allows active subscriptions', () {
    final decision = PurchaseRepository.evaluateStoryCreationClaim(
      {
        'coins': 3,
        'silverSubscription': {
          'isActive': true,
          'endAt': activeSubscriptionEnd.toIso8601String(),
        },
      },
      now: now,
    );

    expect(decision.kind, StoryCreationClaimKind.subscription);
    expect(decision.canCreate, isTrue);
    expect(decision.shouldConsumeCoin, isFalse);
    expect(decision.entitlements.coins, 3);
    expect(decision.entitlements.isSubscriptionActive, isTrue);
  });

  test('story creation consumes one coin when subscription is inactive', () {
    final decision = PurchaseRepository.evaluateStoryCreationClaim(
      const {
        'coins': 2,
        'silverSubscription': {
          'isActive': false,
        },
      },
      now: now,
    );

    expect(decision.kind, StoryCreationClaimKind.coinConsumed);
    expect(decision.canCreate, isTrue);
    expect(decision.shouldConsumeCoin, isTrue);
    expect(decision.entitlements.coins, 1);
    expect(decision.entitlements.isSubscriptionActive, isFalse);
  });

  test('story creation is denied when user has no coins and no subscription',
      () {
    final decision = PurchaseRepository.evaluateStoryCreationClaim(
      const {
        'coins': 0,
        'silverSubscription': {
          'isActive': false,
        },
      },
      now: now,
    );

    expect(decision.kind, StoryCreationClaimKind.denied);
    expect(decision.canCreate, isFalse);
    expect(decision.entitlements.coins, 0);
  });

  test('expired subscriptions are treated as inactive', () {
    final decision = PurchaseRepository.evaluateStoryCreationClaim(
      {
        'coins': 0,
        'silverSubscription': {
          'isActive': true,
          'endAt': expiredSubscriptionEnd.toIso8601String(),
        },
      },
      now: now,
    );

    expect(decision.kind, StoryCreationClaimKind.denied);
    expect(decision.canCreate, isFalse);
    expect(decision.entitlements.isSubscriptionActive, isFalse);
  });
}
