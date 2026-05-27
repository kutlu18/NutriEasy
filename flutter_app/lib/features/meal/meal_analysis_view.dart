// meal_analysis_view.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

import 'correction_view.dart';
import 'portion_edit_view.dart';
import 'meal_item_row.dart';

class MealAnalysisView extends StatelessWidget {
  const MealAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Analiz sonucu'),
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final analysis = state.selectedAnalysis;
          if (analysis == null) {
            return const EmptyState(
              title: 'Analiz bulunamadı',
              subtitle: 'Önce bir öğün girip analiz et.',
              icon: Icons.receipt_long,
            );
          }

          final isLowConfidence = analysis.confidence == Confidence.low;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              if (analysis.sourceType == MealSourceType.photo) ...[
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF16212B),
                        Color(0xFF4A3620),
                        Color(0xFF101214)
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        right: 16,
                        top: 16,
                        child: _StatusPill(
                          icon: Icons.verified_outlined,
                          text: 'Yüksek doğruluk',
                          background: Color(0xFF101816),
                          foreground: Color(0xFF69F0AE),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: _StatusPill(
                          icon: Icons.photo_camera_outlined,
                          text: analysis.sourceLabel ?? 'Fotoğraf',
                          background: const Color(0xFF16161A),
                          foreground: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF141417),
                    border: Border.all(color: const Color(0xFF2A2A2E)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analysis.sourceType.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFFB794FF),
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        analysis.sourceLabel ?? 'Öğün açıklaması',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2A2A2E)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tahmini değer',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF8A8A93),
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _StatusPill(
                      icon: isLowConfidence
                          ? Icons.warning_amber_rounded
                          : Icons.verified_outlined,
                      text: '${analysis.confidence.title} güven',
                      background: isLowConfidence
                          ? const Color(0xFF2A1D10)
                          : const Color(0xFF101816),
                      foreground: isLowConfidence
                          ? NutriColors.amber
                          : const Color(0xFF69F0AE),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${analysis.totalCalories}',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'kcal',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: const Color(0xFF8A8A93)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: const Color(0xFF2A2A2E)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MacroBlock(
                              label: 'Protein',
                              value: '${analysis.macros.proteinGr}g'),
                        ),
                        Container(
                            width: 1,
                            height: 44,
                            color: const Color(0xFF2A2A2E)),
                        Expanded(
                          child: _MacroBlock(
                              label: 'Karb.',
                              value: '${analysis.macros.carbsGr}g'),
                        ),
                        Container(
                            width: 1,
                            height: 44,
                            color: const Color(0xFF2A2A2E)),
                        Expanded(
                          child: _MacroBlock(
                              label: 'Yağ', value: '${analysis.macros.fatGr}g'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              InlineMessage(
                text: isLowConfidence
                    ? 'Bu tahmin düşük güvenli. Kaydetmeden önce porsiyonları veya öğeleri düzenlemeni öneririz.'
                    : 'Bu sonuç tahminidir. Kaydetmeden önce porsiyonları kontrol edebilirsin.',
                icon: isLowConfidence
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                backgroundColor: const Color(0xFF111826),
                foregroundColor: isLowConfidence
                    ? NutriColors.amber
                    : const Color(0xFFB794FF),
              ),
              const SizedBox(height: 18),
              Text(
                'Belirlenen öğeler',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF8A8A93),
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 12),
              ...analysis.detectedItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MealItemRow(item: item),
                ),
              ),
              if (analysis.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...analysis.warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InlineMessage(
                      text: warning,
                      icon: Icons.info_outline,
                      backgroundColor: const Color(0xFF111826),
                      foregroundColor: const Color(0xFFB794FF),
                    ),
                  ),
                ),
              ],
              if (analysis.correctionNote != null) ...[
                const SizedBox(height: 8),
                InlineMessage(
                  text: analysis.correctionNote!,
                  icon: Icons.edit_note,
                  backgroundColor: const Color(0xFF111826),
                  foregroundColor: const Color(0xFFB794FF),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PortionEditView()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2B2B31)),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Porsiyonu düzenle'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const CorrectionView()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2B2B31)),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Açıklamayla düzelt'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                title: state.isSavingMeal
                    ? 'Kaydediliyor'
                    : isLowConfidence
                        ? 'Önce düzenle veya kontrol et'
                        : 'Kontrol et ve kaydet',
                icon: isLowConfidence ? Icons.edit_note : Icons.save_outlined,
                isBusy: state.isSavingMeal,
                onPressed: () async {
                  await state.saveAnalysis();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MacroBlock extends StatelessWidget {
  const _MacroBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF8A8A93))),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white)),
      ],
    );
  }
}

