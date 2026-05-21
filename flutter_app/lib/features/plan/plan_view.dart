import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';
import '../premium/premium_view.dart' as premium;

class DailyPlanView extends StatelessWidget {
  const DailyPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final plan = state.dailyPlan;
        final totalCalories =
            plan.fold<int>(0, (sum, item) => sum + item.calories);
        final appliedCount = plan.where((item) => item.isApplied).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gunluk plan'),
            actions: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanEditView()),
                ),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text('Bugunun rehberi',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Plan, sadece bir liste degil. Bugun ne yiyecegini sade bir akista gosterir.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: NutriColors.muted),
              ),
              const SizedBox(height: 16),
              _DailySummaryCard(
                totalCalories: totalCalories,
                targetCalories: state.calorieTargetForProfile,
                appliedCount: appliedCount,
                totalCount: plan.length,
              ),
              const SizedBox(height: 18),
              if (state.canAccessWeeklyPlan)
                _WeeklyPlanPreviewCard(plan: plan)
              else
                _PremiumGateCard(
                  title: 'Haftalik plan',
                  subtitle:
                      'Premium ile haftanin akisini tek yerde gorebilirsin.',
                  benefits: const [
                    '7 gunluk rehber akis',
                    'Ogun siralama optimizasyonu',
                    'Akilli alternatifler',
                  ],
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const premium.PremiumView()),
                  ),
                ),
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Ogun kartlari',
                actionLabel: 'Duzenle',
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlanEditView()),
                ),
              ),
              const SizedBox(height: 10),
              ...plan.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanMealCard(
                    meal: meal,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => RecipeDetailView(meal: meal)),
                    ),
                    onApply: () async {
                      await state.applyPlannedMeal(meal);
                    },
                    onAlternative: () => showAlternativeSheet(context, meal),
                    onEdit: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PlanEditView(meal: meal)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showAlternativeSheet(
    BuildContext context, PlannedMeal meal) async {
  final state = AppScope.of(context);
  final alternatives = meal.alternatives;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: NutriColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D2CD),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Alternatif oneriler',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Ayni ogun slotu icin hafif farkli secenekler.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: NutriColors.muted),
              ),
              const SizedBox(height: 16),
              if (alternatives.isEmpty)
                const EmptyState(
                  title: 'Alternatif yok',
                  subtitle:
                      'Bu kart icin simdilik baska bir secenek bulunmuyor.',
                  icon: Icons.swap_horiz,
                )
              else
                ...alternatives.map(
                  (alternative) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AlternativeCard(
                      meal: alternative,
                      onTap: () {
                        state.replacePlannedMeal(meal, alternative);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class PlanEditView extends StatefulWidget {
  const PlanEditView({super.key, this.meal});

  final PlannedMeal? meal;

  @override
  State<PlanEditView> createState() => _PlanEditViewState();
}

class _PlanEditViewState extends State<PlanEditView> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meal?.title ?? '');
    _noteController = TextEditingController(text: widget.meal?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final meals = widget.meal != null ? [widget.meal!] : state.dailyPlan;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan duzenle')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.meal != null) ...[
            Text('Kart detayini duzenle',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Baslik'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Not'),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: 'Alternatifler'),
            const SizedBox(height: 10),
            ...widget.meal!.alternatives.map(
              (alternative) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlternativeCard(
                  meal: alternative,
                  onTap: () {
                    state.replacePlannedMeal(widget.meal!, alternative);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              title: 'Kaydet',
              icon: Icons.save_outlined,
              onPressed: () {
                final updated = widget.meal!.copyWith(
                  title: _titleController.text.trim().isEmpty
                      ? widget.meal!.title
                      : _titleController.text.trim(),
                  note: _noteController.text.trim().isEmpty
                      ? null
                      : _noteController.text.trim(),
                );
                state.editPlannedMeal(widget.meal!, updated);
                Navigator.of(context).pop();
              },
            ),
          ] else ...[
            Text('Gunluk plan kartlari',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Her karti acip basligini veya alternatifini degistirebilirsin.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: NutriColors.muted),
            ),
            const SizedBox(height: 16),
            ...meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EditablePlanCard(
                  meal: meal,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PlanEditView(meal: meal)));
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RecipeDetailView extends StatelessWidget {
  const RecipeDetailView({super.key, required this.meal});

  final PlannedMeal meal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tarif detayi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(meal.title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(meal.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: NutriColors.muted)),
          const SizedBox(height: 16),
          _RecipeMetaGrid(meal: meal),
          const SizedBox(height: 16),
          _ActionRow(
            primaryLabel: 'Plani uygula',
            primaryIcon: Icons.play_circle_fill_outlined,
            onPrimary: () => state.applyPlannedMeal(meal),
            secondaryLabel: 'Alternatif',
            secondaryIcon: Icons.swap_horiz,
            onSecondary: () => showAlternativeSheet(context, meal),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Icerik'),
          const SizedBox(height: 10),
          ...meal.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InlineMessage(
                text:
                    '${ingredient.amount} ${ingredient.unit} ${ingredient.name}',
                icon: Icons.check_circle_outline,
                backgroundColor: const Color(0x14D0EBD6),
                foregroundColor: NutriColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SectionHeader(title: 'Yapilis'),
          const SizedBox(height: 10),
          ...meal.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StepCard(
                    index: entry.key + 1,
                    text: entry.value,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.totalCalories,
    required this.targetCalories,
    required this.appliedCount,
    required this.totalCount,
  });

  final int totalCalories;
  final int targetCalories;
  final int appliedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final ratio = (totalCalories / targetCalories).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bugun',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: NutriColors.leaf)),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCalories / $targetCalories kcal',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const Spacer(),
              _Pill(text: '$appliedCount / $totalCount uygulandi'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              color: NutriColors.leaf,
              backgroundColor: const Color(0xFFD8D3CE),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanMealCard extends StatelessWidget {
  const _PlanMealCard({
    required this.meal,
    required this.onTap,
    required this.onApply,
    required this.onAlternative,
    required this.onEdit,
  });

  final PlannedMeal meal;
  final VoidCallback onTap;
  final Future<void> Function() onApply;
  final VoidCallback onAlternative;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final statusColor = meal.isApplied ? NutriColors.leaf : NutriColors.muted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: meal.isApplied
                        ? const Color(0xFFDDEFE6)
                        : const Color(0xFFF1F0ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_mealIcon(meal.mealType), color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.mealType.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: statusColor)),
                      const SizedBox(height: 4),
                      Text(meal.title,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                Text('${meal.calories} kcal',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: statusColor)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              meal.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(text: '${meal.prepMinutes + meal.cookMinutes} dk'),
                const SizedBox(width: 8),
                _Chip(text: '${meal.proteinGr}P'),
                const SizedBox(width: 8),
                _Chip(text: '${meal.carbsGr}C'),
                const SizedBox(width: 8),
                _Chip(text: '${meal.fatGr}F'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    title: meal.isApplied ? 'Uygulandi' : 'Plani uygula',
                    icon: meal.isApplied
                        ? Icons.check_circle_outline
                        : Icons.play_arrow_outlined,
                    isBusy: false,
                    onPressed:
                        meal.isApplied ? null : () => unawaited(onApply()),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onAlternative,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Alternatif',
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Duzenle',
                ),
              ],
            ),
          ],
        ),
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

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({
    required this.meal,
    required this.onTap,
  });

  final PlannedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD0EBD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.swap_horiz, color: NutriColors.leaf),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(meal.description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text('${meal.calories} kcal',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: NutriColors.leaf)),
          ],
        ),
      ),
    );
  }
}

class _EditablePlanCard extends StatelessWidget {
  const _EditablePlanCard({
    required this.meal,
    required this.onTap,
  });

  final PlannedMeal meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD0EBD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.edit_note, color: NutriColors.leaf),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(meal.description,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _RecipeMetaGrid extends StatelessWidget {
  const _RecipeMetaGrid({required this.meal});

  final PlannedMeal meal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: MetricCard(
                title: 'Süre',
                value: '${meal.totalMinutes} dk',
                subtitle: 'Hazırlık + pişirme',
                tint: NutriColors.mint)),
        const SizedBox(width: 10),
        Expanded(
            child: MetricCard(
                title: 'Porsiyon',
                value: '${meal.servings}',
                subtitle: 'Kişilik',
                tint: const Color(0xFFEDE7FF))),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondary,
  });

  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            title: primaryLabel,
            icon: primaryIcon,
            onPressed: onPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSecondary,
            icon: Icon(secondaryIcon),
            label: Text(secondaryLabel),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFD0EBD6),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Center(
              child: Text('$index',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: NutriColors.leaf)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
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

class _WeeklyPlanPreviewCard extends StatelessWidget {
  const _WeeklyPlanPreviewCard({required this.plan});

  final List<PlannedMeal> plan;

  @override
  Widget build(BuildContext context) {
    final preview = plan.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF0E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Haftalik plan hazir',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Bu hafta icin onerilen akis, ogunleri tek bakista toparlar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...preview.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: NutriColors.leaf, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(meal.title)),
                  Text('${meal.calories} kcal'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumGateCard extends StatelessWidget {
  const _PremiumGateCard({
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final List<String> benefits;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ...benefits.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      color: NutriColors.leaf, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            title: 'Premium ac',
            icon: Icons.workspace_premium_outlined,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
