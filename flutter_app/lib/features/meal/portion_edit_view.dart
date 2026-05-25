// portion_edit_view.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/widgets.dart';
import 'meal_item_row.dart';

class PortionEditView extends StatefulWidget {
  const PortionEditView({super.key});

  @override
  State<PortionEditView> createState() => _PortionEditViewState();
}

class _PortionEditViewState extends State<PortionEditView> {
  double multiplier = 1.0;
  final presets = const <String, double>{
    'Küçük': 0.75,
    'Normal': 1.0,
    'Büyük': 1.35,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final analysis = state.selectedAnalysis;
    if (analysis == null) {
      return const Scaffold(body: Center(child: Text('Analiz bulunamadı')));
    }

    final calories = (analysis.totalCalories * multiplier).round();
    final portionLabel = multiplier < 1
        ? 'Küçük'
        : multiplier > 1
            ? 'Büyük'
            : 'Normal';

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Porsiyonu düzenle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            analysis.sourceLabel ?? 'Öğün',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Porsiyon tahmini. Gerekirse hızlıca değiştir.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF9B9BA1)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: presets.entries
                .map(
                  (entry) => ChoiceChip(
                    label: Text(entry.key),
                    selected: (multiplier - entry.value).abs() < 0.01,
                    onSelected: (_) => setState(() => multiplier = entry.value),
                    selectedColor: const Color(0xFFB794FF),
                    backgroundColor: const Color(0xFF16161A),
                    labelStyle:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: (multiplier - entry.value).abs() < 0.01
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141417),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A2A2E)),
            ),
            child: Column(
              children: [
                Text(
                  '$calories kcal',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$portionLabel porsiyon',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: const Color(0xFF8A8A93)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RoundStepButton(
                      icon: Icons.remove,
                      onTap: () => setState(() =>
                          multiplier = (multiplier - 0.1).clamp(0.5, 2.0)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          multiplier.toStringAsFixed(1),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kat',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF9B9BA1)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    RoundStepButton(
                      icon: Icons.add,
                      onTap: () => setState(() =>
                          multiplier = (multiplier + 0.1).clamp(0.5, 2.0)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '200 ml / 1 bardak gibi önceden bilinen birimlere göre ölçeklenir.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF9B9BA1)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...analysis.detectedItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MiniPortionRow(item: item, multiplier: multiplier),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            title: 'Uygula',
            icon: Icons.check,
            onPressed: () {
              state.updateSelectedAnalysisPortion(multiplier);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _MiniPortionRow extends StatelessWidget {
  const _MiniPortionRow({required this.item, required this.multiplier});

  final MealItem item;
  final double multiplier;

  @override
  Widget build(BuildContext context) {
    final quantity = (item.quantity * multiplier * 10).roundToDouble() / 10;
    final calories = (item.calories * multiplier).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2E)),
      ),
      child: Row(
        children: [
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
                  '$quantity ${item.unit}  •  ${item.proteinGr}P ${item.carbsGr}C ${item.fatGr}F',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF9B9BA1)),
                ),
              ],
            ),
          ),
          Text('$calories kcal',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: const Color(0xFFB794FF))),
        ],
      ),
    );
  }
}

