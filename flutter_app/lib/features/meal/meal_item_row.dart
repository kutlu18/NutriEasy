// meal_item_row.dart — split from meal_view.dart for clarity.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

Future<void> showMealItemEditSheet(
  BuildContext context, {
  required Meal meal,
  required MealItem item,
}) async {
  final state = AppScope.of(context);
  var quantity = item.quantity;

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final ratio = item.quantity == 0 ? 1.0 : quantity / item.quantity;
          final calories = (item.calories * ratio).round();
          final protein = (item.proteinGr * ratio).round();
          final carbs = (item.carbsGr * ratio).round();
          final fat = (item.fatGr * ratio).round();

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4FB),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D2E8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 16),
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '${quantity.toStringAsFixed(1)} ${item.unit}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundStepButton(
                      icon: Icons.remove,
                      onTap: () {
                        setSheetState(() {
                          quantity = (quantity - 0.5).clamp(0.5, 10.0);
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          quantity.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(item.unit,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _RoundStepButton(
                      icon: Icons.add,
                      onTap: () {
                        setSheetState(() {
                          quantity = (quantity + 0.5).clamp(0.5, 10.0);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Kucuk',
                    'Normal',
                    'Buyuk',
                  ]
                      .map(
                        (label) => ActionChip(
                          label: Text(label),
                          onPressed: () {
                            setSheetState(() {
                              quantity = switch (label) {
                                'Kucuk' => item.quantity * 0.75,
                                'Normal' => item.quantity,
                                'Buyuk' => item.quantity * 1.25,
                                _ => item.quantity,
                              };
                            });
                          },
                          backgroundColor: Colors.white,
                          labelStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          shape: StadiumBorder(
                              side: BorderSide(
                                  color: NutriColors.mint.withOpacity(0.8))),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: _MealStat(
                              title: 'Kalori',
                              value: '$calories',
                              unit: 'kcal')),
                      Container(
                          width: 1, height: 36, color: const Color(0xFFE6E1EE)),
                      Expanded(
                          child: _MealStat(
                              title: 'Protein', value: '$protein', unit: 'g')),
                      Container(
                          width: 1, height: 36, color: const Color(0xFFE6E1EE)),
                      Expanded(
                          child: _MealStat(
                              title: 'Karb.', value: '$carbs', unit: 'g')),
                      Container(
                          width: 1, height: 36, color: const Color(0xFFE6E1EE)),
                      Expanded(
                          child: _MealStat(
                              title: 'Yag', value: '$fat', unit: 'g')),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  title: state.isUpdatingMealItem ? 'Kaydediliyor' : 'Uygula',
                  icon: Icons.check,
                  isBusy: state.isUpdatingMealItem,
                  onPressed: () async {
                    final ok = await state.updateMealItem(
                      meal: meal,
                      item: item,
                      quantity: quantity,
                    );
                    if (!sheetContext.mounted || !ok) return;
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


class MealItemRow extends StatelessWidget {
  const MealItemRow({super.key, required this.item, this.onEdit});

  final MealItem item;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A2E)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant_outlined,
                color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF9B9BA1)),
                ),
                if (item.confidence != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Guven: ${item.confidence!.title}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.confidence == Confidence.low
                              ? NutriColors.amber
                              : const Color(0xFF69F0AE),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.calories} kcal',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.white),
              ),
              Text(
                'P ${item.proteinGr}  C ${item.carbsGr}  F ${item.fatGr}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF9B9BA1)),
              ),
            ],
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              color: const Color(0xFFB794FF),
              tooltip: 'Düzenle',
            ),
          ],
        ],
      ),
    );
  }
}


