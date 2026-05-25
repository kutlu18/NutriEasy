// text_meal_input_view.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

import 'meal_logging_sheet.dart';
import 'meal_processing_view.dart';

class TextMealInputView extends StatefulWidget {
  const TextMealInputView({super.key});

  @override
  State<TextMealInputView> createState() => _TextMealInputViewState();
}

class _TextMealInputViewState extends State<TextMealInputView> {
  final textController = TextEditingController();
  MealType mealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    textController.addListener(() => setState(() {}));
  }

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted),
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
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, height: 1.45),
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
                    labelStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color:
                              mealType == type ? Colors.black : NutriColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99)),
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
          if (state.isAnalyzingMeal)
            const LinearProgressIndicator(color: NutriColors.leaf),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            InlineMessage(
                text: state.errorMessage!, icon: Icons.warning_amber_rounded),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            title: textController.text.trim().isEmpty
                ? 'Once ogununu yaz'
                : 'Tahmini analiz et',
            icon: Icons.auto_awesome,
            isBusy: state.isAnalyzingMeal,
            onPressed: textController.text.trim().isEmpty
                ? null
                : () {
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
            title: 'Guven notu',
            subtitle:
                'Bu akis canli analiz alir. Sonuc tahminidir; kaydetmeden once porsiyonu ve ogeleri kontrol edebilirsin.',
          ),
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
            labelStyle: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            shape: StadiumBorder(
                side: BorderSide(color: NutriColors.mint.withOpacity(0.8))),
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
          BoxShadow(
              color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 10)),
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

