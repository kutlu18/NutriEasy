// subscription domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.

enum SubscriptionPlan { free, monthly, yearly }

extension SubscriptionPlanTitle on SubscriptionPlan {
  String get title => switch (this) {
        SubscriptionPlan.free => 'Free',
        SubscriptionPlan.monthly => 'Premium Aylık',
        SubscriptionPlan.yearly => 'Premium Yıllık',
      };
}

extension SubscriptionPlanPrice on SubscriptionPlan {
  String get priceLabel => switch (this) {
        SubscriptionPlan.free => '0 TL',
        SubscriptionPlan.monthly => '149 TL / ay',
        SubscriptionPlan.yearly => '999 TL / yıl',
      };
}


class SubscriptionState {
  SubscriptionState({
    this.active = false,
    this.plan = SubscriptionPlan.free,
    this.source = 'mock',
    this.purchasedAt,
    this.renewsAt,
    this.lastUpdatedAt,
  });

  final bool active;
  final SubscriptionPlan plan;
  final String source;
  final String? purchasedAt;
  final String? renewsAt;
  final String? lastUpdatedAt;

  bool get hasWeeklyPlanAccess => active;
  bool get hasAdvancedInsightAccess => active;
  bool get hasDeepAiAccess => active;
  bool get hasAdFreeAccess => active;
  bool get hasSmarterAlternativesAccess => active;

  SubscriptionState copyWith({
    bool? active,
    SubscriptionPlan? plan,
    String? source,
    String? purchasedAt,
    String? renewsAt,
    String? lastUpdatedAt,
  }) {
    return SubscriptionState(
      active: active ?? this.active,
      plan: plan ?? this.plan,
      source: source ?? this.source,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      renewsAt: renewsAt ?? this.renewsAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }

  factory SubscriptionState.fromMap(Map<String, dynamic> data) {
    return SubscriptionState(
      active: data['active'] as bool? ?? false,
      plan: subscriptionPlanFromDb(data['plan']),
      source: data['source']?.toString() ?? 'mock',
      purchasedAt: data['purchasedAt']?.toString(),
      renewsAt: data['renewsAt']?.toString(),
      lastUpdatedAt: data['lastUpdatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'active': active,
        'plan': subscriptionPlanDbValue(plan),
        'source': source,
        if (purchasedAt != null) 'purchasedAt': purchasedAt,
        if (renewsAt != null) 'renewsAt': renewsAt,
        if (lastUpdatedAt != null) 'lastUpdatedAt': lastUpdatedAt,
      };
}


SubscriptionPlan subscriptionPlanFromDb(Object? value) => switch (value?.toString()) {
      'monthly' => SubscriptionPlan.monthly,
      'yearly' => SubscriptionPlan.yearly,
      'free' => SubscriptionPlan.free,
      _ => SubscriptionPlan.free,
    };


String subscriptionPlanDbValue(SubscriptionPlan plan) => switch (plan) {
      SubscriptionPlan.free => 'free',
      SubscriptionPlan.monthly => 'monthly',
      SubscriptionPlan.yearly => 'yearly',
    };


