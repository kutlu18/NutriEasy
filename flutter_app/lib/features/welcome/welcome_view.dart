import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NutriEasy', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Beslenme takibini, öğün analizini ve hedeflerini tek yerde topluyoruz.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A0D3A2A), blurRadius: 24, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: NutriColors.mint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.restaurant_outlined, color: NutriColors.leaf),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('İlk öğününü ekle', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                'Yazı, fotoğraf veya ses ile başlayabilirsin.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _WelcomePill(label: 'Yazı'),
                        _WelcomePill(label: 'Fotoğraf'),
                        _WelcomePill(label: 'Ses'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.42,
                        minHeight: 10,
                        color: NutriColors.leaf,
                        backgroundColor: const Color(0xFFE4E0DC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Bugün',
                            value: '610 kcal',
                            subtitle: 'Örnek ilk giriş',
                            tint: NutriColors.mint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricCard(
                            title: 'Kalan',
                            value: '1.390 kcal',
                            subtitle: 'Hedefe yakın',
                            tint: NutriColors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const _WelcomeCard(),
              const SizedBox(height: 16),
              PrimaryButton(
                title: 'Devam et',
                icon: Icons.arrow_forward,
                onPressed: () => unawaited(state.completeWelcome()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePill extends StatelessWidget {
  const _WelcomePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE9DF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: NutriColors.leaf),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NutriColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Başlamadan önce', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Uygulama açıldıktan sonra giriş yapabilir, hedeflerini tanımlayabilir ve öğünlerini yazıyla ekleyebilirsin.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
