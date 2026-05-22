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
          padding: const EdgeInsets.fromLTRB(36, 34, 36, 28),
          child: Column(
            children: [
              Text(
                'AID CORE SOLUTIONS',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: NutriColors.muted.withOpacity(0.72),
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(flex: 3),
              const NutriLogoMark(size: 104),
              const SizedBox(height: 30),
              Text(
                'NutriEasy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: NutriColors.leaf,
                      fontSize: 48,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 22),
              Text(
                'Takibi kolaylaştır. Kendini daha iyi hisset.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: NutriColors.muted,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
              ),
              const Spacer(flex: 4),
              PrimaryButton(
                title: 'Başlayalım',
                icon: Icons.arrow_forward,
                onPressed: () => unawaited(state.completeWelcome()),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => unawaited(state.completeWelcome()),
                child: Text(
                  'Hesabım var',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: NutriColors.leafDark,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Ücretsiz başla  •  Temel takip her zaman erişilebilir',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NutriColors.muted.withOpacity(0.72),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
