import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';
import '../premium/premium_view.dart' as premium;

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).refreshProgressSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final summary = state.progressSnapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Takip'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: state.refreshProgressSummary,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshProgressSummary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Bu hafta', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              summary.weeklyInsight.isEmpty
                  ? 'Haftan diger ekranlardan daha sessiz baslamis olabilir. Burada trendi birlikte okuruz.'
                  : summary.weeklyInsight,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SummaryHero(summary: summary),
            const SizedBox(height: 14),
            _MetricStrip(summary: summary),
            const SizedBox(height: 16),
            if (state.canAccessAdvancedInsights)
              _AdvancedInsightCard(summary: summary)
            else
              PremiumGateCard(
                title: 'Gelişmiş içgörü',
                subtitle: 'Premium ile trendler daha yorumlayici hale gelir.',
                benefits: const [
                  'Haftalik yorumlar',
                  'Derin makro baglanti',
                  'Daha akilli karar destek',
                ],
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const premium.PremiumView()),
                ),
              ),
            const SizedBox(height: 16),
            _TrendCard(summary: summary),
            const SizedBox(height: 16),
            _MacroCard(summary: summary),
            const SizedBox(height: 16),
            _SupportCard(summary: summary),
            const SizedBox(height: 16),
            _AchievementCard(summary: summary),
            const SizedBox(height: 16),
            if (summary.isEmpty)
              EmptyState(
                title: 'Henuz takip verisi yok',
                subtitle:
                    'Ilk ogun kaydettiginde, kilo tahmini, kalori dengesi ve seri otomatik dolacak.',
                icon: Icons.timeline,
                actionLabel: 'Ogün ekle',
                onAction: () => state.setMainTabIndex(1),
              )
            else
              PrimaryButton(
                title: 'Detaylari ac',
                icon: Icons.arrow_forward,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProgressDetailView(summary: summary),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class ProgressDetailView extends StatelessWidget {
  const ProgressDetailView({super.key, required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final days = summary.weightTrend;

    return Scaffold(
      appBar: AppBar(title: const Text('Takip detayi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Haftalik analiz',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Veriler hedefe gore yorumlanir. Kilo trendi tahminidir; yeme kayitlarindan uretilir.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _SummaryHero(summary: summary),
          const SizedBox(height: 16),
          _TrendCard(summary: summary),
          const SizedBox(height: 16),
          _DetailMetricGrid(summary: summary),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Gunluk iz',
            subtitle: 'Kalori girisleri ve tahmini agirlik etkisi',
            child: Column(
              children: days
                  .map(
                    (point) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: NutriColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: NutriColors.mint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.calendar_today,
                                color: NutriColors.leaf, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_formatDayLabel(point.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 2),
                                Text(
                                  '${point.caloriesConsumed} kcal alinmis',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${point.weightKg.toStringAsFixed(1)} kg',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: NutriColors.leaf),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Ipuclari',
            subtitle: 'Bu hafta neden bu sekilde gorunuyor?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: summary.achievements
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InlineMessage(
                        text: item,
                        icon: Icons.star,
                        backgroundColor: const Color(0x1FE8B949),
                        foregroundColor: NutriColors.leaf,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final positive = summary.calorieBalance >= 0;
    final accent = positive ? NutriColors.mint : const Color(0x1FECA4A4);
    final accentColor = positive ? NutriColors.leaf : NutriColors.coral;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kalori dengesi',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: NutriColors.muted)),
          const SizedBox(height: 6),
          Text(
            summary.calorieBalanceLabel,
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: accentColor),
          ),
          const SizedBox(height: 6),
          Text(
            positive
                ? 'Haftalik hedefe yakin gidiyorsun.'
                : 'Hedefin uzerinde gorunuyor; bu hafta biraz denge gerekebilir.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineStat(
                  label: 'Mevcut',
                  value: '${summary.consumedCalories} kcal',
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'Hedef',
                  value: '${summary.calorieTarget} kcal',
                ),
              ),
              Expanded(
                child: _InlineStat(
                  label: 'Seri',
                  value: '${summary.streakDays} gun',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetric(
            title: 'Kilo',
            value: '${summary.currentWeightKg.toStringAsFixed(1)} kg',
            subtitle: 'Tahmini degisim ${summary.weightDeltaLabel}',
            tint: NutriColors.mint,
            icon: Icons.monitor_weight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniMetric(
            title: 'Su',
            value: '${summary.hydrationCurrent}/${summary.hydrationTarget}',
            subtitle: 'Tahmini bardak',
            tint: NutriColors.amber,
            icon: Icons.water_drop,
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Agirlik trendi',
      subtitle: 'Son 7 gunun kalori dengesi ile uretilen tahmini hat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: ProgressTrendChart(points: summary.weightTrend),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Tahmini degisim',
                  value: summary.weightDeltaLabel,
                  subtitle: 'Bu haftanin etkisi',
                  tint: NutriColors.leaf,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  title: 'Kalori farki',
                  value: summary.calorieBalanceLabel,
                  subtitle: 'Haftalik hedefe gore',
                  tint: NutriColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Makro trendleri',
      subtitle: 'Protein, karbonhidrat ve yag dengesi',
      child: Column(
        children: [
          _MacroRow(
            label: 'Protein',
            current: summary.consumedMacros.proteinGr,
            target: summary.macroTargets.proteinGr,
            tint: NutriColors.leaf,
          ),
          const SizedBox(height: 10),
          _MacroRow(
            label: 'Karbonhidrat',
            current: summary.consumedMacros.carbsGr,
            target: summary.macroTargets.carbsGr,
            tint: NutriColors.amber,
          ),
          const SizedBox(height: 10),
          _MacroRow(
            label: 'Yag',
            current: summary.consumedMacros.fatGr,
            target: summary.macroTargets.fatGr,
            tint: NutriColors.coral,
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: 'Adim',
            value: '${summary.stepsCurrent}',
            subtitle: 'Hedef ${summary.stepsTarget} - tahmini',
            tint: NutriColors.mint,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MetricCard(
            title: 'Seri',
            value: '${summary.streakDays} gun',
            subtitle: 'Kayit devam ediyor',
            tint: NutriColors.amber,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Haftalik oduller',
      subtitle: 'Kucuk kazanclarin toplami',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: summary.achievements
            .map(
              (item) => Chip(
                label: Text(item),
                backgroundColor: NutriColors.mint,
                labelStyle: const TextStyle(color: NutriColors.leaf),
                side: const BorderSide(color: Colors.transparent),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailMetricGrid extends StatelessWidget {
  const _DetailMetricGrid({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                title: 'Protein',
                value:
                    '${summary.consumedMacros.proteinGr}/${summary.macroTargets.proteinGr}',
                subtitle: 'g / hafta',
                tint: NutriColors.leaf,
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(
                title: 'Karb.',
                value:
                    '${summary.consumedMacros.carbsGr}/${summary.macroTargets.carbsGr}',
                subtitle: 'g / hafta',
                tint: NutriColors.amber,
                icon: Icons.bolt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                title: 'Yag',
                value:
                    '${summary.consumedMacros.fatGr}/${summary.macroTargets.fatGr}',
                subtitle: 'g / hafta',
                tint: NutriColors.coral,
                icon: Icons.opacity,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(
                title: 'Ogun',
                value: '${summary.mealCount}',
                subtitle: 'toplam kayit',
                tint: NutriColors.mint,
                icon: Icons.restaurant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tint,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.titleMedium)),
              Text('$current / $target g',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(tint),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedInsightCard extends StatelessWidget {
  const _AdvancedInsightCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final balance = summary.calorieBalance;
    final isPositive = balance >= 0;

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
          Text('Gelişmiş yorum', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? 'Hafta dengeli ilerliyor. Bu ritim korunursa hedefe daha kontrollü yaklaşırsın.'
                : 'Kalori dengesi biraz yukarıda. Bir sonraki iki öğünü sadeleştirmek iyi olabilir.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  label: 'Kalori farkı',
                  value: summary.calorieBalanceLabel,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightTile(
                  label: 'Haftalık trend',
                  value: summary.weightDeltaLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class ProgressTrendChart extends StatelessWidget {
  const ProgressTrendChart({super.key, required this.points});

  final List<ProgressTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('Trend verisi yok'));
    }

    return LayoutBuilder(
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 110,
              child: CustomPaint(
                painter: _TrendPainter(points: points),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: points
                  .map((point) => Text(_shortDayLabel(point.date),
                      style: Theme.of(context).textTheme.bodySmall))
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points});

  final List<ProgressTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = NutriColors.leaf
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = NutriColors.leaf.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final minWeight = points.map((point) => point.weightKg).reduce(math.min);
    final maxWeight = points.map((point) => point.weightKg).reduce(math.max);
    final minY = minWeight - 0.4;
    final maxY = maxWeight + 0.4;
    final range = math.max(0.1, maxY - minY);
    final stepX = points.length <= 1 ? 0.0 : size.width / (points.length - 1);

    final path = Path();
    final fillPath = Path()..moveTo(0, size.height);

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = points.length <= 1 ? size.width / 2 : stepX * i;
      final normalized = (point.weightKg - minY) / range;
      final y = size.height - (normalized * (size.height - 16));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = NutriColors.coral);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

String _shortDayLabel(DateTime date) {
  const names = <String>['Pzt', 'Sal', 'Car', 'Per', 'Cum', 'Cmt', 'Paz'];
  return names[date.weekday - 1];
}

String _formatDayLabel(DateTime date) {
  const months = <String>[
    'Oca',
    'Sub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Agu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara'
  ];
  return '${date.day} ${months[date.month - 1]}';
}
