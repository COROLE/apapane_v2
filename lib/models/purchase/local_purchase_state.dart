class LocalPurchaseState {
  const LocalPurchaseState({
    required this.coins,
    required this.isSubscriptionActive,
    required this.subscriptionEndAt,
  });

  final int coins;
  final bool isSubscriptionActive;
  final DateTime? subscriptionEndAt;

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'isSubscriptionActive': isSubscriptionActive,
        'subscriptionEndAt': subscriptionEndAt?.toIso8601String(),
      };

  factory LocalPurchaseState.fromJson(Map<String, dynamic> json) {
    final rawEndAt = json['subscriptionEndAt']?.toString();
    return LocalPurchaseState(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      isSubscriptionActive: json['isSubscriptionActive'] == true,
      subscriptionEndAt: rawEndAt == null || rawEndAt.isEmpty
          ? null
          : DateTime.tryParse(rawEndAt),
    );
  }

  factory LocalPurchaseState.initial() => const LocalPurchaseState(
        coins: 0,
        isSubscriptionActive: false,
        subscriptionEndAt: null,
      );

  LocalPurchaseState copyWith({
    int? coins,
    bool? isSubscriptionActive,
    DateTime? subscriptionEndAt,
    bool clearSubscriptionEndAt = false,
  }) {
    return LocalPurchaseState(
      coins: coins ?? this.coins,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
      subscriptionEndAt: clearSubscriptionEndAt
          ? null
          : subscriptionEndAt ?? this.subscriptionEndAt,
    );
  }
}
