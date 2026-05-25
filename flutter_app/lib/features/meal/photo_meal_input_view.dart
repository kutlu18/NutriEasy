// photo_meal_input_view.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../shared/widgets.dart';

import 'meal_logging_sheet.dart';
import 'meal_processing_view.dart';

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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF9B9BA1)),
            ),
            const SizedBox(height: 18),
            Container(
              height: 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10141F),
                    Color(0xFF6E5431),
                    Color(0xFF15181D)
                  ],
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
                        border: Border.all(
                            color: const Color(0xFFB794FF), width: 3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _PhotoBadge(
                        text: 'Yüksek doğruluk',
                        icon: Icons.check_circle_outline),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() =>
                                selectedLabel = 'Galeriden seçilen yemek'),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeri'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF2B2B31)),
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() =>
                                selectedLabel = 'Kamera ile çekilen yemek'),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kamera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B5E51),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
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
                      labelStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                mealType == type ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99)),
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
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF69F0AE))),
        ],
      ),
    );
  }
}

