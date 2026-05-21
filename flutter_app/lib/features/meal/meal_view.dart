import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

void showMealLoggingSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MealLoggingSheet(),
  );
}

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
                        Text(item.unit, style: Theme.of(context).textTheme.bodySmall),
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
                          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          shape: StadiumBorder(side: BorderSide(color: NutriColors.mint.withOpacity(0.8))),
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
                      Expanded(child: _MealStat(title: 'Kalori', value: '$calories', unit: 'kcal')),
                      Container(width: 1, height: 36, color: const Color(0xFFE6E1EE)),
                      Expanded(child: _MealStat(title: 'Protein', value: '$protein', unit: 'g')),
                      Container(width: 1, height: 36, color: const Color(0xFFE6E1EE)),
                      Expanded(child: _MealStat(title: 'Karb.', value: '$carbs', unit: 'g')),
                      Container(width: 1, height: 36, color: const Color(0xFFE6E1EE)),
                      Expanded(child: _MealStat(title: 'Yag', value: '$fat', unit: 'g')),
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

class _MealLoggingSheet extends StatelessWidget {
  const _MealLoggingSheet();

  @override
  Widget build(BuildContext context) {
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
          Text('Nasıl eklemek istiyorsun?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _EntryModeTile(
            icon: Icons.photo_camera_outlined,
            title: 'Fotoğrafla',
            subtitle: 'Hızlı kamera ya da galeri akışı',
            accent: const Color(0xFFB79AF3),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PhotoMealInputView()));
            },
          ),
          const SizedBox(height: 10),
          _EntryModeTile(
            icon: Icons.chat_bubble_outline,
            title: 'Yazarak',
            subtitle: 'En hızlı test edilebilir akış',
            accent: NutriColors.leaf,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TextMealInputView()));
            },
          ),
          const SizedBox(height: 10),
          _EntryModeTile(
            icon: Icons.mic_none,
            title: 'Sesle',
            subtitle: 'Konuş, biz metne çevirelim',
            accent: const Color(0xFF9B59B6),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VoiceMealInputView()));
            },
          ),
        ],
      ),
    );
  }
}

class _EntryModeTile extends StatelessWidget {
  const _EntryModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
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
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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

class TextMealInputView extends StatefulWidget {
  const TextMealInputView({super.key});

  @override
  State<TextMealInputView> createState() => _TextMealInputViewState();
}

class _TextMealInputViewState extends State<TextMealInputView> {
  final textController = TextEditingController(text: '2 yumurta, 1 dilim tam buğday ekmeği ve domates');
  MealType mealType = MealType.lunch;

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğününü yaz'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showMealLoggingSheet(context),
            icon: const Icon(Icons.bolt_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Yediğin her şeyi kısaca yaz, biz analizini çıkaralım.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2A2A2E)),
            ),
            child: TextField(
              controller: textController,
              minLines: 8,
              maxLines: 10,
              style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.45),
              decoration: const InputDecoration(
                hintText: 'Örn: yarım tabak pilav + kuru fasulye + turşu',
                hintStyle: TextStyle(color: Color(0xFF6D6D72)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MealType.values
                .map(
                  (type) => ChoiceChip(
                    label: Text(type.title),
                    selected: mealType == type,
                    onSelected: (_) => setState(() => mealType = type),
                    selectedColor: const Color(0xFFCDB8FF),
                    backgroundColor: Colors.white,
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mealType == type ? Colors.black : NutriColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          _QuickPillRow(
            onTap: (preset) {
              textController.text = preset;
              setState(() {});
            },
          ),
          const SizedBox(height: 18),
          if (state.isAnalyzingMeal) const LinearProgressIndicator(color: NutriColors.leaf),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            InlineMessage(text: state.errorMessage!, icon: Icons.warning_amber_rounded),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            title: 'Analiz et',
            icon: Icons.auto_awesome,
            isBusy: state.isAnalyzingMeal,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MealProcessingView(
                    mealType: mealType,
                    sourceType: MealSourceType.text,
                    source: textController.text,
                    sourceLabel: textController.text,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const _HowItWorksCard(
            title: 'Nasıl çalışır?',
            subtitle: 'Bu akış Supabase Edge Function üzerinden analiz alır. Auth yoksa demo sonuç gösterilir.',
          ),
        ],
      ),
    );
  }
}

class PhotoMealInputView extends StatefulWidget {
  const PhotoMealInputView({super.key});

  @override
  State<PhotoMealInputView> createState() => _PhotoMealInputViewState();
}

class _PhotoMealInputViewState extends State<PhotoMealInputView> {
  MealType mealType = MealType.lunch;
  String selectedLabel = 'Tavuk, pilav ve salata';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Öğününü fotoğrafla'),
        actions: [
          IconButton(
            onPressed: () => showMealLoggingSheet(context),
            icon: const Icon(Icons.bolt_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text(
              'Kamerayı aç ya da galeriden bir foto seç. Sonra porsiyonu hızlıca düzenleriz.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9B9BA1)),
            ),
            const SizedBox(height: 18),
            Container(
              height: 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF10141F), Color(0xFF6E5431), Color(0xFF15181D)],
                ),
                border: Border.all(color: const Color(0xFF9B7CF7), width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFB794FF), width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _PhotoBadge(text: 'Yüksek doğruluk', icon: Icons.check_circle_outline),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => selectedLabel = 'Galeriden seçilen yemek'),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeri'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF2B2B31)),
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => selectedLabel = 'Kamera ile çekilen yemek'),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kamera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E51),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealType.values
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type.title),
                      selected: mealType == type,
                      onSelected: (_) => setState(() => mealType = type),
                      selectedColor: const Color(0xFFB794FF),
                      backgroundColor: const Color(0xFF16161A),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mealType == type ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              title: 'Analiz et',
              icon: Icons.auto_awesome,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealProcessingView(
                      mealType: mealType,
                      sourceType: MealSourceType.photo,
                      source: selectedLabel,
                      sourceLabel: selectedLabel,
                    ),
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

class VoiceMealInputView extends StatefulWidget {
  const VoiceMealInputView({super.key});

  @override
  State<VoiceMealInputView> createState() => _VoiceMealInputViewState();
}

class _VoiceMealInputViewState extends State<VoiceMealInputView> {
  MealType mealType = MealType.breakfast;
  final transcriptController = TextEditingController(text: '2 yumurta, bir dilim tam buğday ekmeği ve ...');
  bool isRecording = false;

  @override
  void dispose() {
    transcriptController.dispose();
    super.dispose();
  }

  Future<void> _simulateRecord() async {
    setState(() => isRecording = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    transcriptController.text = '2 yumurta, 1 dilim tam buğday ekmeği, biraz peynir ve domates';
    if (!mounted) return;
    setState(() => isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Öğününü anlat'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFF15151A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2B2B31)),
                ),
                child: Icon(
                  isRecording ? Icons.mic : Icons.mic_none,
                  size: 72,
                  color: const Color(0xFFB794FF),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                isRecording ? 'Kayıt alınıyor...' : 'Kayıt için hazır',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A2A2E)),
              ),
              child: TextField(
                controller: transcriptController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(color: Colors.white, height: 1.4),
                decoration: const InputDecoration(
                  labelText: 'Transkript',
                  labelStyle: TextStyle(color: Color(0xFFB794FF)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealType.values
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type.title),
                      selected: mealType == type,
                      onSelected: (_) => setState(() => mealType = type),
                      selectedColor: const Color(0xFFB794FF),
                      backgroundColor: const Color(0xFF16161A),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mealType == type ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              title: isRecording ? 'Kaydediliyor' : 'Kayda başla',
              icon: Icons.mic,
              isBusy: isRecording,
              onPressed: isRecording
                  ? null
                  : () async {
                      await _simulateRecord();
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealProcessingView(
                      mealType: mealType,
                      sourceType: MealSourceType.voice,
                      source: transcriptController.text,
                      sourceLabel: transcriptController.text,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2B2B31)),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Analize gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

class MealProcessingView extends StatefulWidget {
  const MealProcessingView({
    super.key,
    required this.mealType,
    required this.sourceType,
    required this.source,
    required this.sourceLabel,
  });

  final MealType mealType;
  final MealSourceType sourceType;
  final String source;
  final String sourceLabel;

  @override
  State<MealProcessingView> createState() => _MealProcessingViewState();
}

class _MealProcessingViewState extends State<MealProcessingView> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  Future<void> _runAnalysis() async {
    final state = AppScope.of(context);
    switch (widget.sourceType) {
      case MealSourceType.text:
        await state.analyzeMeal(
          source: widget.source,
          mealType: widget.mealType,
          sourceType: widget.sourceType,
          sourceLabel: widget.sourceLabel,
        );
        break;
      case MealSourceType.photo:
        await state.analyzePhoto(
          sourceLabel: widget.sourceLabel,
          mealType: widget.mealType,
        );
        break;
      case MealSourceType.voice:
        await state.analyzeVoice(
          transcript: widget.source,
          mealType: widget.mealType,
        );
        break;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MealAnalysisView()));
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.sourceType) {
      MealSourceType.text => Icons.chat_bubble_outline,
      MealSourceType.photo => Icons.photo_camera_outlined,
      MealSourceType.voice => Icons.mic_none,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Analiz ediliyor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2E2E36)),
                ),
                child: Icon(icon, size: 64, color: const Color(0xFFB794FF)),
              ),
              const SizedBox(height: 24),
              Text(
                'Nuri analiz yapıyor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Kaynak: ${widget.sourceType.title}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9B9BA1)),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: Color(0xFFB794FF),
                  backgroundColor: Color(0xFF26262B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                      colors: [Color(0xFF16212B), Color(0xFF4A3620), Color(0xFF101214)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 16,
                        top: 16,
                        child: _StatusPill(
                          icon: Icons.verified_outlined,
                          text: 'Yüksek doğruluk',
                          background: const Color(0xFF101816),
                          foreground: const Color(0xFF69F0AE),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
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
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${analysis.totalCalories}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'kcal',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF8A8A93)),
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
                          child: _MacroBlock(label: 'Protein', value: '${analysis.macros.proteinGr}g'),
                        ),
                        Container(width: 1, height: 44, color: const Color(0xFF2A2A2E)),
                        Expanded(
                          child: _MacroBlock(label: 'Karb.', value: '${analysis.macros.carbsGr}g'),
                        ),
                        Container(width: 1, height: 44, color: const Color(0xFF2A2A2E)),
                        Expanded(
                          child: _MacroBlock(label: 'Yağ', value: '${analysis.macros.fatGr}g'),
                        ),
                      ],
                    ),
                  ],
                ),
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
                          MaterialPageRoute(builder: (_) => const PortionEditView()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2B2B31)),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Porsiyonu düzenle'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CorrectionView()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2B2B31)),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Açıklamayla düzelt'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                title: state.isSavingMeal ? 'Kaydediliyor' : 'Kaydet',
                icon: Icons.save_outlined,
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Porsiyon tahmini. Gerekirse hızlıca değiştir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9B9BA1)),
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
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: (multiplier - entry.value).abs() < 0.01 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF8A8A93)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundStepButton(
                      icon: Icons.remove,
                      onTap: () => setState(() => multiplier = (multiplier - 0.1).clamp(0.5, 2.0)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          multiplier.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'kat',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9B9BA1)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _RoundStepButton(
                      icon: Icons.add,
                      onTap: () => setState(() => multiplier = (multiplier + 0.1).clamp(0.5, 2.0)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '200 ml / 1 bardak gibi önceden bilinen birimlere göre ölçeklenir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9B9BA1)),
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

class CorrectionView extends StatefulWidget {
  const CorrectionView({super.key});

  @override
  State<CorrectionView> createState() => _CorrectionViewState();
}

class _CorrectionViewState extends State<CorrectionView> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Açıklamayla düzelt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'AI yanıtını küçük bir notla iyileştir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF9B9BA1)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16161A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2E)),
            ),
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Örn: tavuk daha azdı, pilav biraz daha fazlaydı.',
                hintStyle: TextStyle(color: Color(0xFF6D6D72)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              'Daha az yağlı',
              'Protein daha yüksek',
              'Porsiyon küçük',
              'Pilav yerine bulgur',
            ]
                .map(
                  (label) => ActionChip(
                    label: Text(label),
                    onPressed: () => controller.text = label,
                    backgroundColor: const Color(0xFF16161A),
                    labelStyle: TextStyle(color: Colors.white),
                    shape: StadiumBorder(side: BorderSide(color: Color(0xFF2A2A2E))),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            title: state.isCorrectingAnalysis ? 'Kaydediliyor' : 'Düzeltmeyi kaydet',
            icon: Icons.send_outlined,
            isBusy: state.isCorrectingAnalysis,
            onPressed: () async {
              await state.applySelectedAnalysisCorrection(controller.text);
              if (!context.mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

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
          Text(meal.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            meal.mealType.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB794FF)),
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
                  child: _MealStat(title: 'Kalori', value: '${meal.totalCalories}', unit: 'kcal'),
                ),
                Container(width: 1, height: 42, color: const Color(0xFF2A2A2E)),
                Expanded(
                  child: _MealStat(title: 'Protein', value: '${meal.macros.proteinGr}', unit: 'g'),
                ),
                Container(width: 1, height: 42, color: const Color(0xFF2A2A2E)),
                Expanded(
                  child: _MealStat(title: 'Karb.', value: '${meal.macros.carbsGr}', unit: 'g'),
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
            child: const Icon(Icons.restaurant_outlined, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity.toStringAsFixed(1)} ${item.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9B9BA1)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.calories} kcal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
              Text(
                'P ${item.proteinGr}  C ${item.carbsGr}  F ${item.fatGr}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9B9BA1)),
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

class _QuickPillRow extends StatelessWidget {
  const _QuickPillRow({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      'Sabah kahvaltısı',
      'Öğle yemeği',
      'Ara öğün',
      'Protein odaklı',
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final text = items[index];
          return ActionChip(
            label: Text(text),
            onPressed: () => onTap(text),
            backgroundColor: Colors.white,
            labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            shape: StadiumBorder(side: BorderSide(color: NutriColors.mint.withOpacity(0.8))),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: items.length,
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101816),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2A6F61)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF69F0AE)),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF69F0AE))),
        ],
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
        border: Border.all(color: foreground.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
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
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8A8A93))),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _MealStat extends StatelessWidget {
  const _MealStat({required this.title, required this.value, required this.unit});

  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF8A8A93))),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              TextSpan(text: unit, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF8A8A93))),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2A2A2E)),
        ),
        child: Icon(icon, color: Colors.white),
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
                Text(item.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '$quantity ${item.unit}  •  ${item.proteinGr}P ${item.carbsGr}C ${item.fatGr}F',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9B9BA1)),
                ),
              ],
            ),
          ),
          Text('$calories kcal', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: const Color(0xFFB794FF))),
        ],
      ),
    );
  }
}
