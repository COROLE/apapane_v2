import 'package:apapane/typedefs/firestore_typedef.dart';

enum StoryMode {
  mini,
  standard,
  premium,
}

extension StoryModeInfo on StoryMode {
  String get key => name;

  String get displayName {
    switch (this) {
      case StoryMode.mini:
        return 'みじかい';
      case StoryMode.standard:
        return 'ふつう';
      case StoryMode.premium:
        return 'たっぷり';
    }
  }

  int get pageCount {
    switch (this) {
      case StoryMode.mini:
        return 4;
      case StoryMode.standard:
        return 8;
      case StoryMode.premium:
        return 12;
    }
  }

  int get coinCost {
    switch (this) {
      case StoryMode.mini:
        return 1;
      case StoryMode.standard:
        return 2;
      case StoryMode.premium:
        return 3;
    }
  }

  String get shortDescription {
    switch (this) {
      case StoryMode.mini:
        return 'さくっと読める';
      case StoryMode.standard:
        return 'ちゃんと冒険できる';
      case StoryMode.premium:
        return '特別な1冊に';
    }
  }

  bool get isRecommended => this == StoryMode.standard;
}

StoryMode storyModeFromKey(String? key) {
  for (final mode in StoryMode.values) {
    if (mode.key == key) {
      return mode;
    }
  }
  return StoryMode.mini;
}

enum StoryTone {
  funny,
  heartwarming,
  bedtime,
  adventure,
}

enum StoryEndingStyle {
  happy,
  gentle,
  funnyTwist,
}

enum StoryWorldType {
  forest,
  ocean,
  space,
  sweets,
  dinosaur,
  custom,
}

extension StoryToneInfo on StoryTone {
  String get label {
    switch (this) {
      case StoryTone.funny:
        return 'おもしろい';
      case StoryTone.heartwarming:
        return 'あたたかい';
      case StoryTone.bedtime:
        return '寝る前向け';
      case StoryTone.adventure:
        return 'ぼうけん';
    }
  }
}

extension StoryEndingStyleInfo on StoryEndingStyle {
  String get label {
    switch (this) {
      case StoryEndingStyle.happy:
        return 'ハッピーエンド';
      case StoryEndingStyle.gentle:
        return 'ほっとする終わり';
      case StoryEndingStyle.funnyTwist:
        return 'ちょっと笑える終わり';
    }
  }
}

extension StoryWorldTypeInfo on StoryWorldType {
  String get label {
    switch (this) {
      case StoryWorldType.forest:
        return '森';
      case StoryWorldType.ocean:
        return '海';
      case StoryWorldType.space:
        return '宇宙';
      case StoryWorldType.sweets:
        return 'おかしの国';
      case StoryWorldType.dinosaur:
        return '恐竜の島';
      case StoryWorldType.custom:
        return '子どもの入力を優先';
    }
  }
}

class StoryOptions {
  const StoryOptions({
    this.tone = StoryTone.adventure,
    this.endingStyle = StoryEndingStyle.funnyTwist,
    this.worldType = StoryWorldType.custom,
  });

  final StoryTone tone;
  final StoryEndingStyle endingStyle;
  final StoryWorldType worldType;

  SDMap toJson() => {
        'tone': tone.name,
        'endingStyle': endingStyle.name,
        'worldType': worldType.name,
      };
}

class StoryPreview {
  const StoryPreview({
    required this.title,
    required this.summary,
    required this.pagePlan,
    required this.mode,
    required this.pageCount,
    required this.coinCost,
    required this.storyOptions,
  });

  final String title;
  final String summary;
  final List<String> pagePlan;
  final StoryMode mode;
  final int pageCount;
  final int coinCost;
  final StoryOptions storyOptions;

  factory StoryPreview.fromJson(
    SDMap json, {
    StoryMode fallbackMode = StoryMode.standard,
    StoryOptions fallbackOptions = const StoryOptions(),
  }) {
    final mode = storyModeFromKey(json['mode']?.toString());
    final resolvedMode = json['mode'] == null ? fallbackMode : mode;
    return StoryPreview(
      title: json['title']?.toString().trim() ?? '',
      summary: json['summary']?.toString().trim() ?? '',
      pagePlan: (json['pagePlan'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      mode: resolvedMode,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? resolvedMode.pageCount,
      coinCost: (json['coinCost'] as num?)?.toInt() ?? resolvedMode.coinCost,
      storyOptions: fallbackOptions,
    );
  }
}

class StoryCreationStatus {
  const StoryCreationStatus({
    required this.coins,
    required this.isSubscriptionActive,
    required this.monthlyStoryCredits,
    required this.storyCreditsUsed,
    required this.storyCreditsRemaining,
  });

  final int coins;
  final bool isSubscriptionActive;
  final int monthlyStoryCredits;
  final int storyCreditsUsed;
  final int storyCreditsRemaining;

  factory StoryCreationStatus.fromJson(SDMap json) {
    return StoryCreationStatus(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      isSubscriptionActive: json['isSubscriptionActive'] == true,
      monthlyStoryCredits: (json['monthlyStoryCredits'] as num?)?.toInt() ?? 6,
      storyCreditsUsed: (json['storyCreditsUsed'] as num?)?.toInt() ?? 0,
      storyCreditsRemaining:
          (json['storyCreditsRemaining'] as num?)?.toInt() ?? 0,
    );
  }
}

class StoryGenerationReservation {
  const StoryGenerationReservation({
    required this.requestId,
    required this.status,
    required this.mode,
    required this.pageCount,
    required this.coinCost,
    required this.paymentSource,
  });

  final String requestId;
  final String status;
  final StoryMode mode;
  final int pageCount;
  final int coinCost;
  final String paymentSource;

  factory StoryGenerationReservation.fromJson(SDMap json) {
    final mode = storyModeFromKey(json['mode']?.toString());
    return StoryGenerationReservation(
      requestId: json['requestId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      mode: mode,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? mode.pageCount,
      coinCost: (json['coinCost'] as num?)?.toInt() ?? mode.coinCost,
      paymentSource: json['paymentSource']?.toString() ?? '',
    );
  }
}
