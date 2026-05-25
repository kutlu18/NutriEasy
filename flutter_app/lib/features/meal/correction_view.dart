// correction_view.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../shared/widgets.dart';

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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF9B9BA1)),
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
                    shape: StadiumBorder(
                        side: BorderSide(color: Color(0xFF2A2A2E))),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            title: state.isCorrectingAnalysis
                ? 'Kaydediliyor'
                : 'Düzeltmeyi kaydet',
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

