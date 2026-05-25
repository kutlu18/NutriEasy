// photo_meal_input_view.dart — placeholder until the photo meal flow ships.
//
// The previous implementation contained mock gallery/camera buttons that only
// mutated a local string ('Galeriden seçilen yemek'), a static 'Yüksek
// doğruluk' badge that promised confidence without analysis, and a hardcoded
// fallback 'Tavuk, pilav ve salata' that would silently reach MealProcessingView
// if the user hit Analyze before tapping anything. With the photo flag still
// gated off in MVP, the entry surfaces (Home hero card + meal logging sheet)
// no longer reach here -- but if the user navigates back into a stale route,
// they get an honest 'not ready yet' screen instead of a mock that lies.
//
// When the real photo flow ships, this file should be replaced with the
// production implementation -- it isn't worth iterating on the mock between
// now and then.

import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class PhotoMealInputView extends StatelessWidget {
  const PhotoMealInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NutriColors.background,
      appBar: AppBar(
        title: const Text('Fotoğrafla ekle'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: NutriColors.mintSoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: NutriColors.leaf,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_camera_outlined,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fotoğrafla öğün ekleme yakında',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Üzerinde çalışıyoruz. Hazır olduğunda tabağının fotoğrafını çekip AI’la '
                      'analiz edebileceksin. Şimdilik öğünlerini yazarak ekleyebilirsin.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: NutriColors.muted),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                title: 'Yazarak eklemeye dön',
                icon: Icons.chat_bubble_outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
