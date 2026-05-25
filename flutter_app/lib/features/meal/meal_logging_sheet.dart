// meal_logging_sheet.dart — split from meal_view.dart for clarity.
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

import 'text_meal_input_view.dart';
import 'photo_meal_input_view.dart';
import 'voice_meal_input_view.dart';

/// Açar meal-logging seçim bottom sheet'i.
/// [initialMealType] verilirse text/photo/voice ekranlarına ön-seçili mealType
/// olarak iletilir (Home'daki meal-slot'lardan açılışlar için kullanılır).
void showMealLoggingSheet(BuildContext context, {MealType? initialMealType}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MealLoggingSheet(initialMealType: initialMealType),
  );
}

class _MealLoggingSheet extends StatelessWidget {
  const _MealLoggingSheet({this.initialMealType});

  final MealType? initialMealType;

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
          Text('Öğününü nasıl ekleyelim?',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const InlineMessage(
            text:
                'Şimdilik en güvenilir yol yazarak eklemek. Fotoğraf ve ses çok yakında beta olarak açılacak.',
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
                MaterialPageRoute(
                  builder: (_) =>
                      TextMealInputView(initialMealType: initialMealType),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _EntryModeTile(
            icon: Icons.photo_camera_outlined,
            title: 'Fotoğrafla',
            subtitle: state.photoMealInputEnabled
                ? 'Hızlı kamera ya da galeri akışı'
                : 'Beta hazır olunca açılacak',
            accent: const Color(0xFFB79AF3),
            disabled: !state.photoMealInputEnabled,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PhotoMealInputView()));
            },
          ),
          const SizedBox(height: 10),
          _EntryModeTile(
            icon: Icons.mic_none,
            title: 'Sesle',
            subtitle: state.voiceMealInputEnabled
                ? 'Konuş, biz metne çevirelim'
                : 'Beta hazır olunca açılacak',
            accent: const Color(0xFF9B59B6),
            disabled: !state.voiceMealInputEnabled,
            onTap: () {
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
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
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
              if (disabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NutriColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Yakında',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: NutriColors.muted,
                        fontWeight: FontWeight.w700),
                  ),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
