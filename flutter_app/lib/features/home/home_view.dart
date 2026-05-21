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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'NutriEasy',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: NutriColors.leaf,
                fontWeight: FontWeight.w800,
              ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => showMealLoggingSheet(context),
          icon: const Icon(Icons.menu),
        ),
        actions: [
          IconButton(
            onPressed: () => showMealLoggingSheet(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final dashboard = state.dashboard;
          final hasMeals = state.meals.isNotEmpty;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _Greeting(user: state.user),
              const SizedBox(height: 16),
              _TodayCard(dashboard: dashboard),
              const SizedBox(height: 18),
              SectionHeader(title: 'Öğün slotları'),
              const SizedBox(height: 10),
              _MealSlotGrid(meals: state.meals),
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Öğün ekle',
                actionLabel: 'Hepsi',
                onAction: () => showMealLoggingSheet(context),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_camera_outlined,
                      label: 'Fotoğrafla',
                      tint: const Color(0xFFD0EBD6),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhotoMealInputView())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.chat_bubble_outline,
                      label: 'Yazarak',
                      tint: Colors.white,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TextMealInputView())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.mic_none,
                      label: 'Sesle',
                      tint: const Color(0xFFEDE7FF),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceMealInputView())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionHeader(title: 'Bugünün öğünleri'),
              const SizedBox(height: 10),
              if (!hasMeals)
                const _EmptyMealPrompt()
              else
                ...state.meals.map(
                  (meal) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MealDetailView(meal: meal))),
                      child: _MealTile(meal: meal),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              SectionHeader(title: 'Günlük hedefler'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _GoalMiniCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Su',
                      value: '4 / 8',
                      tint: const Color(0xFFD7E7FF),
                      progress: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GoalMiniCard(
                      icon: Icons.directions_walk_outlined,
                      title: 'Adım',
                      value: '6.5k / 10k',
                      tint: const Color(0xFFDDF4E0),
                      progress: 0.65,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _FastingCard(
                summary: state.fastingSnapshot,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FastingView())),
              ),
              const SizedBox(height: 18),
              _NuriCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NuriChatView())),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NutriColors.leaf,
        foregroundColor: Colors.white,
        onPressed: () => showMealLoggingSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Merhaba, ${user.name}', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Bugün nasıl hissediyorsun? Öğünlerini hızlıca ekleyelim.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.dashboard});

  final TodayDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final consumedRatio = (dashboard.consumedCalories / dashboard.calorieTarget).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EE),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x120D3A2A), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bugün', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NutriColors.leaf)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${dashboard.consumedCalories}',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: NutriColors.leaf,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('/ ${dashboard.calorieTarget} kcal', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted)),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _Pill(text: 'Kalan: ${dashboard.remainingCalories} kcal'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: consumedRatio,
              minHeight: 10,
              color: NutriColors.leaf,
              backgroundColor: const Color(0xFFD8D3CE),
            ),
          ),
          const SizedBox(height: 14),
          _MacroRow(
            label: 'Protein',
            current: dashboard.consumedMacros.proteinGr,
            target: dashboard.macroTargets.proteinGr,
            tint: NutriColors.leaf,
          ),
          const SizedBox(height: 8),
          _MacroRow(
            label: 'Karbonhidrat',
            current: dashboard.consumedMacros.carbsGr,
            target: dashboard.macroTargets.carbsGr,
            tint: NutriColors.coral,
          ),
          const SizedBox(height: 8),
          _MacroRow(
            label: 'Yağ',
            current: dashboard.consumedMacros.fatGr,
            target: dashboard.macroTargets.fatGr,
            tint: NutriColors.amber,
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.tint,
  });

  final String label;
  final int current;
  final int target;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: tint,
              backgroundColor: const Color(0xFFE4E0DC),
            ),
          ),
        ),
        const SizedBox(width: 10),
          SizedBox(
            width: 72,
          child: Text('$current/$target g', textAlign: TextAlign.end, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NutriColors.muted)),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: NutriColors.leaf),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NutriColors.leaf)),
          ],
        ),
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDDEFE6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_mealIcon(meal.mealType), color: NutriColors.leaf),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.mealType.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NutriColors.muted)),
                const SizedBox(height: 4),
                Text(meal.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('${meal.items.length} öğe', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('${meal.totalCalories} kcal', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NutriColors.leaf)),
        ],
      ),
    );
  }

  IconData _mealIcon(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => Icons.wb_sunny_outlined,
      MealType.lunch => Icons.lunch_dining_outlined,
      MealType.dinner => Icons.nightlight_outlined,
      MealType.snack => Icons.icecream_outlined,
    };
  }
}

class _MealSlotGrid extends StatelessWidget {
  const _MealSlotGrid({required this.meals});

  final List<Meal> meals;

  @override
  Widget build(BuildContext context) {
    final slots = [
      _MealSlotModel(
        label: 'Kahvaltı',
        mealType: MealType.breakfast,
        icon: Icons.wb_sunny_outlined,
      ),
      _MealSlotModel(
        label: 'Öğle',
        mealType: MealType.lunch,
        icon: Icons.lunch_dining_outlined,
      ),
      _MealSlotModel(
        label: 'Akşam',
        mealType: MealType.dinner,
        icon: Icons.nightlight_outlined,
      ),
      _MealSlotModel(
        label: 'Ara öğün',
        mealType: MealType.snack,
        icon: Icons.icecream_outlined,
      ),
    ];

    return Column(
      children: slots
          .map(
            (slot) {
              final meal = meals.where((item) => item.mealType == slot.mealType).isNotEmpty
                  ? meals.firstWhere((item) => item.mealType == slot.mealType)
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MealSlotCard(
                  label: slot.label,
                  icon: slot.icon,
                  meal: meal,
                ),
              );
            },
          )
          .toList(),
    );
  }
}

class _MealSlotModel {
  _MealSlotModel({
    required this.label,
    required this.mealType,
    required this.icon,
  });

  final String label;
  final MealType mealType;
  final IconData icon;
}

class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({
    required this.label,
    required this.icon,
    required this.meal,
  });

  final String label;
  final IconData icon;
  final Meal? meal;

  @override
  Widget build(BuildContext context) {
    final hasMeal = meal != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasMeal ? const Color(0xFFDDEFE6) : const Color(0xFFF1F0ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: hasMeal ? NutriColors.leaf : NutriColors.muted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  hasMeal ? meal!.title : 'Henüz eklenmedi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NutriColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasMeal ? '${meal!.totalCalories} kcal' : '0 kcal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: hasMeal ? NutriColors.leaf : NutriColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                hasMeal ? '${meal!.items.length} öğe' : 'Bekliyor',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMealPrompt extends StatelessWidget {
  const _EmptyMealPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.restaurant_outlined, color: NutriColors.leaf),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Henüz öğün yok', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('İlk öğününü eklemek için üstteki hızlı aksiyonları kullan.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  const _GoalMiniCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.progress,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, color: NutriColors.leaf),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: NutriColors.leaf,
              backgroundColor: const Color(0xFFE4E0DC),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastingCard extends StatelessWidget {
  const _FastingCard({
    required this.summary,
    required this.onTap,
  });

  final FastingSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = summary.currentState == FastingStateLabel.active;
    final broken = summary.currentState == FastingStateLabel.broken;
    final tint = broken
        ? const Color(0x1FECA4A4)
        : active
            ? const Color(0xFFDCEFD8)
            : const Color(0xFFF4F1EE);
    final accent = broken ? NutriColors.coral : active ? NutriColors.leaf : NutriColors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(
                    active ? Icons.timelapse_outlined : broken ? Icons.warning_amber_outlined : Icons.nightlight_outlined,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fasting', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(summary.statusLabel, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  summary.timerLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(summary.statusDetail, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: summary.progress,
                minHeight: 8,
                color: accent,
                backgroundColor: const Color(0xFFE4E0DC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NuriCard extends StatelessWidget {
  const _NuriCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF10312A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFD0EBD6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: NutriColors.leaf),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nuri AI', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün protein hedefini tutturmak için akşamı hafif tutabiliriz.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFD1E5DA)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD0EBD6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: NutriColors.leaf,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
