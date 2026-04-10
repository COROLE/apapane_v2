import 'package:apapane/local/local_firestore.dart';

class PurchaseEntitlements {
  const PurchaseEntitlements({
    required this.coins,
    required this.isSubscriptionActive,
    required this.subscriptionEndAt,
  });

  final int coins;
  final bool isSubscriptionActive;
  final DateTime? subscriptionEndAt;

  factory PurchaseEntitlements.initial() {
    return const PurchaseEntitlements(
      coins: 0,
      isSubscriptionActive: false,
      subscriptionEndAt: null,
    );
  }

  factory PurchaseEntitlements.fromUserData(
    Map<String, dynamic>? data, {
    DateTime? now,
  }) {
    if (data == null) {
      return PurchaseEntitlements.initial();
    }

    final effectiveNow = now ?? DateTime.now();
    final subscription =
        (data['silverSubscription'] as Map<String, dynamic>?) ?? const {};
    final endAt = _toDateTime(subscription['endAt']);
    final isActive = subscription['isActive'] == true &&
        (endAt == null || endAt.isAfter(effectiveNow));

    return PurchaseEntitlements(
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      isSubscriptionActive: isActive,
      subscriptionEndAt: endAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is Map<String, dynamic>) {
      final seconds = value['seconds'] ?? value['_seconds'] ?? value['Seconds'];
      final nanoseconds =
          value['nanoseconds'] ?? value['_nanoseconds'] ?? value['Nanoseconds'];
      if (seconds is int) {
        final milliseconds = seconds * 1000 +
            ((nanoseconds is int ? nanoseconds : 0) / 1000000).round();
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
