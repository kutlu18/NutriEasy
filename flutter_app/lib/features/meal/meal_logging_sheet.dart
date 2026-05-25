// meal_logging_sheet.dart — split from meal_view.dart for clarity.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

import 'text_meal_input_view.dart';
import 'photo_meal_input_view.dart';
import 'voice_meal_input_view.dart';

void showMealLoggingSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MealLoggingSheet(),
  );
}


class _MealLoggingSheet extends StatelessWidget {
  const _MealLoggingSheet();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

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
          Text('Nasıl eklemek istiyorsun?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          InlineMessage(
            text:
                'MVP icin en guvenilir akis yazarak eklemedir. Fotograf ve ses hazir olunca beta olarak acilacak.',
            icon: Icons.info_outline,
            backgroundColor: NutriColors.mintSoft,
            foregroundColor: NutriColors.leaf,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            title: 'Yazarak ekle',
            icon: Icons.chat_bubble_outline,
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TextMealInputView()));
            },
          ),
          const SizedBox(height: 12),
          _EntryModeTile(
            icon: Icons.photo_camera_outlined,
            title: 'Fotoğrafla',
            subtitle: 'Hızlı kamera ya da galeri akışı',
            accent: const Color(0xFFB79AF3),
            onTap: () {
              if (!state.photoMealInputEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Fotografla analiz henuz aktif degil. Simdilik yazarak ekle.')),
                );
                return;
              }
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PhotoMealInputView()));
            },
          ),
          const SizedBox(height: 10),
          _EntryModeTile(
            icon: Icons.mic_none,
            title: 'Sesle',
            subtitle: 'Konuş, biz metne çevirelim',
            accent: const Color(0xFF9B59B6),
            onTap: () {
              if (!state.voiceMealInputEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Sesle ogun girisi henuz aktif degil. Simdilik yazarak ekle.')),
                );
                return;
              }
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const VoiceMealInputView()));
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


