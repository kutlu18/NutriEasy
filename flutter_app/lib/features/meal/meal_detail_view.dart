// meal_detail_view.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import 'meal_item_row.dart';

class MealDetailView extends StatelessWidget {
  const MealDetailView({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Öğün detayı'),
        actions: [
          IconButton(
            onPressed: () async {
              final deleted = await state.deleteMeal(meal);
              if (!context.mounted || !deleted) return;
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(meal.title,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            meal.mealType.title,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFFB794FF)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141417),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A2A2E)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MealStat(
                      title: 'Kalori',
                      value: '${meal.totalCalories}',
                      unit: 'kcal'),
                ),
                Container(width: 1, height: 42, color: const Color(0xFF2A2A2E)),
                Expanded(
                  child: MealStat(
                      title: 'Protein',
                      value: '${meal.macros.proteinGr}',
                      unit: 'g'),
                ),
                Container(width: 1, height: 42, color: const Color(0xFF2A2A2E)),
                Expanded(
                  child: MealStat(
                      title: 'Karb.',
                      value: '${meal.macros.carbsGr}',
                      unit: 'g'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...meal.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MealItemRow(
                item: item,
                onEdit: () => showMealItemEditSheet(
                  context,
                  meal: meal,
                  item: item,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

