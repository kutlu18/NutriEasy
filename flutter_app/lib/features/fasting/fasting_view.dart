import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class FastingView extends StatefulWidget {
  const FastingView({super.key});

  @override
  State<FastingView> createState() => _FastingViewState();
}

class _FastingViewState extends State<FastingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).refreshFastingState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final summary = state.fastingSnapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fasting'),
        actions: [
          IconButton(
            tooltip: 'Planı düzenle',
            onPressed: () => _openPlanEditor(context, summary.plan),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: state.refreshFastingState,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refreshFastingState,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Oruç durumu', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              summary.weeklyInsight,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _CurrentStateCard(summary: summary),
            const SizedBox(height: 16),
            _PlanCard(summary: summary),
            const SizedBox(height: 16),
            _ActionRow(summary: summary),
            const SizedBox(height: 16),
            _PhaseCard(summary: summary),
            const SizedBox(height: 16),
            _HistoryCard(summary: summary, onOpenPlanEditor: () => _openPlanEditor(context, summary.plan)),
            const SizedBox(height: 16),
            _InsightCard(summary: summary),
            const SizedBox(height: 16),
            if (summary.isEmpty)
              EmptyState(
                title: 'Fasting planı hazır',
                subtitle: 'Başlangıç ve bitiş kararını verdikten sonra burada süre, faz ve geçmiş birlikte görünür.',
                icon: Icons.nightlight_outlined,
                actionLabel: 'Plan oluştur',
                onAction: () => _openPlanEditor(context, summary.plan),
              )
            else
              _AchievementCard(summary: summary),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlanEditor(BuildContext context, FastingPlan plan) async {
    final result = await showModalBottomSheet<FastingPlan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FastingPlanEditorSheet(initialPlan: plan),
    );

    if (!mounted || result == null) return;
    await AppScope.of(context).updateFastingPlan(plan: result);
  }
}

class FastingPlanEditorSheet extends StatefulWidget {
  const FastingPlanEditorSheet({super.key, required this.initialPlan});

  final FastingPlan initialPlan;

  @override
  State<FastingPlanEditorSheet> createState() => _FastingPlanEditorSheetState();
}

class _FastingPlanEditorSheetState extends State<FastingPlanEditorSheet> {
  late bool enabled = widget.initialPlan.enabled;
  late double targetHours = widget.initialPlan.targetHours.toDouble();
  late final TextEditingController startController = TextEditingController(text: widget.initialPlan.windowStart);
  late final TextEditingController endController = TextEditingController(text: widget.initialPlan.windowEnd);
  late final TextEditingController noteController = TextEditingController(text: widget.initialPlan.notes ?? '');

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Fasting plan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Plan aktif'),
              value: enabled,
              onChanged: (value) => setState(() => enabled = value),
            ),
            const SizedBox(height: 8),
            Text('Hedef süre: ${targetHours.round()} saat'),
            Slider(
              min: 12,
              max: 24,
              divisions: 12,
              value: targetHours,
              onChanged: (value) => setState(() => targetHours = value),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: 'Başlangıç zamanı',
                hintText: '20:00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'Bitiş zamanı',
                hintText: '12:00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Not',
                hintText: 'Örn. akşam 8 sonrası su ve çay serbest',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              title: 'Kaydet',
              icon: Icons.check,
              onPressed: () {
                Navigator.of(context).pop(
                  FastingPlan(
                    enabled: enabled,
                    targetHours: targetHours.round(),
                    windowStart: startController.text.trim().isEmpty ? '20:00' : startController.text.trim(),
                    windowEnd: endController.text.trim().isEmpty ? '12:00' : endController.text.trim(),
                    label: '${targetHours.round()}:${(24 - targetHours.round()).clamp(0, 24)}',
                    notes: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
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

class _CurrentStateCard extends StatelessWidget {
  const _CurrentStateCard({required this.summary});

  final FastingSummary summary;

  @override
  Widget build(BuildContext context) {
    final active = summary.currentState == FastingStateLabel.active;
    final broken = summary.currentState == FastingStateLabel.broken;
    final tint = broken
        ? const Color(0x1FECA4A4)
        : active
            ? const Color(0xFFD0EBD6)
            : const Color(0xFFF4F1EE);
    final accent = broken ? NutriColors.coral : active ? NutriColors.leaf : NutriColors.muted;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
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
                    Text(summary.statusLabel, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(summary.statusDetail, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title: 'Süre',
                  value: summary.timerLabel,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  title: 'Faz',
                  value: summary.metabolicPhaseLabel,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  title: 'Kalan',
                  value: summary.remainingMinutes <= 0
                      ? '0dk'
                      : '${summary.remainingMinutes ~/ 60}s ${summary.remainingMinutes.remainder(60)}dk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: summary.progress,
              minHeight: 10,
              backgroundColor: Colors.white,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.summary});

  final FastingSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Aktif plan',
      subtitle: 'Zaman penceresi ve hedef süre',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(summary.plan.label, style: Theme.of(context).textTheme.headlineSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: summary.plan.enabled ? const Color(0xFFD0EBD6) : const Color(0xFFF4F1EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.plan.enabled ? 'Açık' : 'Kapalı',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NutriColors.leaf),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${summary.plan.windowStart} - ${summary.plan.windowEnd}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('${summary.plan.targetHours} saat hedef', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.summary});

  final FastingSummary summary;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final canStart = summary.currentState == FastingStateLabel.ready || summary.currentState == FastingStateLabel.idle || summary.currentState == FastingStateLabel.completed;
    final canEnd = summary.currentState == FastingStateLabel.active || summary.currentState == FastingStateLabel.broken;

    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            title: canStart ? 'Başlat' : 'Planı düzenle',
            icon: canStart ? Icons.play_arrow : Icons.edit,
            onPressed: canStart ? () => state.startFastingSession() : () => _openPlanEditor(context, summary.plan),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canEnd ? () => state.endFastingSession() : null,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Bitir'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openPlanEditor(BuildContext context, FastingPlan plan) async {
    final result = await showModalBottomSheet<FastingPlan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FastingPlanEditorSheet(initialPlan: plan),
    );

    if (result == null || !context.mounted) return;
    await AppScope.of(context).updateFastingPlan(plan: result);
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.summary});

  final FastingSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Metabolik faz',
      subtitle: summary.metabolicPhaseLabel,
      child: Text(summary.metabolicPhaseDetail, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.summary,
    required this.onOpenPlanEditor,
  });

  final FastingSummary summary;
  final VoidCallback onOpenPlanEditor;

  @override
  Widget build(BuildContext context) {
    if (summary.history.isEmpty) {
      return _SectionCard(
        title: 'Geçmiş',
        subtitle: 'Henüz kayıt yok',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('İlk oturum başladığında burada süreler ve kapanışlar görünür.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onOpenPlanEditor,
              icon: const Icon(Icons.edit),
              label: const Text('Plan düzenle'),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      title: 'Geçmiş',
      subtitle: 'Son fasting oturumları',
      child: Column(
        children: summary.history
            .take(4)
            .map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0EBD6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          session.status == FastingSessionStatus.completed ? Icons.check_circle_outline : Icons.cancel_outlined,
                          color: NutriColors.leaf,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session.durationLabel, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(session.metabolicPhase.title, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(session.status.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NutriColors.muted)),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.summary});

  final FastingSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'İçgörü',
      subtitle: 'Bu ekran yalnızca sayaç değil',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.weeklyInsight, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: summary.achievements
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: NutriColors.mint,
                    labelStyle: const TextStyle(color: NutriColors.leaf),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.summary});

  final FastingSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ödüller',
      subtitle: 'Küçük ama anlamlı kazanımlar',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: summary.achievements
            .map(
              (item) => Chip(
                label: Text(item),
                backgroundColor: NutriColors.amber.withOpacity(0.18),
                labelStyle: const TextStyle(color: NutriColors.ink),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
