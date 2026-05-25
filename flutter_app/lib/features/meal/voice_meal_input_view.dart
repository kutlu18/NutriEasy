// voice_meal_input_view.dart — placeholder until the voice meal flow ships.
//
// The previous implementation simulated a recording by waiting 1200ms and then
// writing a hardcoded transcript ('2 yumurta, 1 dilim tam buğday ekmeği, biraz
// peynir ve domates') to a TextField, regardless of what the user said. With
// the voice flag still gated off in MVP, the entry surfaces no longer reach
// here -- but if the user navigates back into a stale route, they get an
// honest 'not ready yet' screen instead of a mock that fakes recording.
//
// When the real voice flow ships, this file should be replaced with the
// production implementation.

import 'package:flutter/material.dart';

import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class VoiceMealInputView extends StatelessWidget {
  const VoiceMealInputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NutriColors.background,
      appBar: AppBar(
        title: const Text('Sesle ekle'),
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
                      child: const Icon(Icons.mic_none,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sesle öğün ekleme yakında',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Üzerinde çalışıyoruz. Hazır olduğunda öğününü anlatıp AI’ya '
                      'döktürebileceksin. Şimdilik öğünlerini yazarak ekleyebilirsin.',
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
