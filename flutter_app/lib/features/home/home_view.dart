import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';
import '../chat/chat_view.dart';
import '../fasting/fasting_view.dart';
import '../meal/meal_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: NutriColors.background,
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final dashboard = state.dashboard;
          final nextMeal = state.meals.isEmpty ? null : state.meals.last;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 112),
              children: [
                const _HomeTopBar(),
                const SizedBox(height: 56),
                _Greeting(user: state.user, tagline: state.homeGreeting),
                const SizedBox(height: 32),
                _DailySummaryCard(dashboard: dashboard),
                const SizedBox(height: 26),
                if (state.photoMealInputEnabled)
                  Row(
                    children: [
                      Expanded(
                        child: _HeroActionCard(
                          title: 'Nuri',
                          subtitle: 'Bana bir şeyler sor',
                          icon: Icons.psychology_alt_outlined,
                          highlighted: true,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NuriChatView())),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _HeroActionCard(
                          title: 'Yemek Tara',
                          subtitle: 'Kameranla keşfet',
                          icon: Icons.photo_camera_outlined,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PhotoMealInputView())),
                        ),
                      ),
                    ],
                  )
                else
                  _HeroActionCard(
                    title: 'Nuri',
                    subtitle: 'Bana beslenmeyle ilgili bir şey sor',
                    icon: Icons.psychology_alt_outlined,
                    highlighted: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const NuriChatView())),
                  ),
                const SizedBox(height: 30),
                Text('Son Eklediğin Öğün',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 14),
                if (nextMeal == null)
                  _NextMealCard.empty(
                      onTap: () => showMealLoggingSheet(context))
                else
                  _NextMealCard(
                    meal: nextMeal,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MealDetailView(meal: nextMeal))),
                  ),
                const SizedBox(height: 24),
                _MealSlots(
                  meals: state.meals,
                  onSlotTap: (type) =>
                      showMealLoggingSheet(context, initialMealType: type),
                ),
                const SizedBox(height: 20),
                _FastingInsightCard(
                  summary: state.fastingSnapshot,
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FastingView())),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NutriColors.leaf,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => showMealLoggingSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: () => unawaited(state.setMainTabIndex(4)),
          child: const CircleAvatar(
            radius: 26,
            backgroundColor: NutriColors.mintSoft,
            child: Icon(Icons.person_outline, color: NutriColors.leaf),
          ),
        ),
        const Spacer(),
        Text(
          'NutriEasy',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: NutriColors.leaf,
                fontWeight: FontWeight.w900,
              ),
        ),
        const Spacer(),
        // Görsel dengeyi korumak için sağ tarafa avatar boyutunda
        // boş bir alan bırakıyoruz. Bildirim/hatırlatma akışı henüz
        // hazır değil; gerçek kontrol gelene kadar yanıltıcı bir
        // simge koymamayı tercih ediyoruz.
        const SizedBox(width: 52),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user, required this.tagline});

  final UserProfile user;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final displayName = user.name.trim().isEmpty ? 'Hoş geldin' : user.name;
    final headline =
        user.name.trim().isEmpty ? 'Hoş geldin' : 'Merhaba, $displayName';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          tagline,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: NutriColors.muted,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.dashboard});

  final TodayDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final isEmpty = dashboard.consumedCalories == 0;
    final consumedRatio = dashboard.calorieTarget == 0
        ? 0.0
        : (dashboard.consumedCalories / dashboard.calorieTarget)
            .clamp(0.0, 1.0);

    return NutriCard(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Günlük Özet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: NutriColors.leafDark),
              ),
              const Spacer(),
              Text(
                'BUGÜN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: NutriColors.ink,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(
                        value: consumedRatio,
                        strokeWidth: 14,
                        strokeCap: StrokeCap.round,
                        color: NutriColors.leaf,
                        backgroundColor: const Color(0xFFE6E4E0),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isEmpty
                              ? '${dashboard.calorieTarget}'
                              : '${dashboard.consumedCalories}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          isEmpty ? 'KCAL HEDEFİN' : 'KCAL',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: NutriColors.muted,
                                    letterSpacing: 1,
                                    fontSize: isEmpty ? 10 : null,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _MacroProgress(
                      label: 'Protein',
                      value: dashboard.consumedMacros.proteinGr,
                      target: dashboard.macroTargets.proteinGr,
                      color: NutriColors.leaf,
                    ),
                    const SizedBox(height: 14),
                    _MacroProgress(
                      label: 'Karbonhidrat',
                      value: dashboard.consumedMacros.carbsGr,
                      target: dashboard.macroTargets.carbsGr,
                      color: const Color(0xFF9ACFCA),
                    ),
                    const SizedBox(height: 14),
                    _MacroProgress(
                      label: 'Yağ',
                      value: dashboard.consumedMacros.fatGr,
                      target: dashboard.macroTargets.fatGr,
                      color: NutriColors.coral,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroProgress extends StatelessWidget {
  const _MacroProgress({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    final isOver = target > 0 && value > target;
    final valueText = isOver
        ? '${value}g / ${target}g ✓'
        : '$value/${target}g';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: NutriColors.muted))),
            Text(
              valueText,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            color: color,
            backgroundColor: const Color(0xFFE1DFDC),
          ),
        ),
      ],
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return NutriCard(
      onTap: onTap,
      color: highlighted ? NutriColors.mintSoft : NutriColors.surface,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      borderColor: highlighted ? NutriColors.leaf : null,
      child: SizedBox(
        height: 152,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: highlighted ? NutriColors.leaf : NutriColors.surfaceLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: highlighted ? Colors.white : NutriColors.leafDark),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: NutriColors.leafDark),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NutriColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextMealCard extends StatelessWidget {
  const _NextMealCard({
    required this.meal,
    required this.onTap,
  }) : empty = false;

  const _NextMealCard.empty({required this.onTap})
      : meal = null,
        empty = true;

  final Meal? meal;
  final VoidCallback onTap;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    final currentMeal = meal;

    return NutriCard(
      onTap: onTap,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: empty ? NutriColors.surfaceLow : NutriColors.mintSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              empty ? Icons.add : Icons.restaurant_outlined,
              color: NutriColors.leaf,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empty
                      ? 'ÖĞÜN EKLE'
                      : '${currentMeal!.mealType.title.toUpperCase()} • BUGÜN',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: NutriColors.muted,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  empty ? 'İlk öğününü kaydet' : currentMeal!.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  empty
                      ? 'Yazarak hızlıca ilk öğününü ekle.'
                      : '${currentMeal!.totalCalories} kcal',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: NutriColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: NutriColors.surfaceLow, shape: BoxShape.circle),
            child: Icon(empty ? Icons.arrow_forward : Icons.check,
                color: NutriColors.leafDark),
          ),
        ],
      ),
    );
  }
}

class _MealSlots extends StatelessWidget {
  const _MealSlots({required this.meals, required this.onSlotTap});

  final List<Meal> meals;
  final ValueChanged<MealType> onSlotTap;

  @override
  Widget build(BuildContext context) {
    final slots = [
      (MealType.breakfast, 'Kahvaltı', Icons.wb_sunny_outlined),
      (MealType.lunch, 'Öğle', Icons.lunch_dining_outlined),
      (MealType.dinner, 'Akşam', Icons.nightlight_outlined),
      (MealType.snack, 'Ara', Icons.local_cafe_outlined),
    ];

    return Row(
      children: [
        for (var index = 0; index < slots.length; index++) ...[
          Expanded(
            child: _SlotPill(
              label: slots[index].$2,
              icon: slots[index].$3,
              active: meals.any((meal) => meal.mealType == slots[index].$1),
              onTap: () => onSlotTap(slots[index].$1),
            ),
          ),
          if (index != slots.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? NutriColors.leaf : NutriColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [NutriColors.cardShadow],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: active ? Colors.white : NutriColors.muted, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: active ? Colors.white : NutriColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FastingInsightCard extends StatelessWidget {
  const _FastingInsightCard({
    required this.summary,
    required this.onTap,
  });

  final FastingSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = summary.currentState == FastingStateLabel.active;

    if (active) {
      return NutriCard(
        onTap: onTap,
        color: const Color(0xFFEAF5F1),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: NutriColors.leaf,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Oruç aktif',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(summary.statusLabel,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                summary.timerLabel,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: NutriColors.leaf,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            if (summary.metabolicPhaseLabel.isNotEmpty) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  summary.metabolicPhaseLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NutriColors.muted,
                        letterSpacing: 0.4,
                      ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Inactive: compact row layout
    return NutriCard(
      onTap: onTap,
      color: NutriColors.surface,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NutriColors.mintSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_outlined,
                color: NutriColors.leaf),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oruç durumu',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(summary.statusLabel,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            summary.timerLabel,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: NutriColors.leaf),
          ),
        ],
      ),
    );
  }
}
