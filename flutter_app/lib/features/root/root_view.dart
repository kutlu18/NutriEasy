import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../auth/auth_view.dart';
import '../food/food_view.dart';
import '../home/home_view.dart';
import '../onboarding/onboarding_view.dart';
import '../plan/plan_view.dart';
import '../profile/profile_view.dart';
import '../progress/progress_view.dart';
import '../splash/splash_view.dart';
import '../welcome/welcome_view.dart';

class RootView extends StatelessWidget {
  const RootView({
    super.key,
    this.autoBootstrapSplash = true,
  });

  final bool autoBootstrapSplash;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return switch (state.shellState) {
          ShellState.splash => SplashView(autoBootstrap: autoBootstrapSplash),
          ShellState.welcome => const WelcomeView(),
          ShellState.auth => const AuthFlowView(),
          ShellState.onboarding => const OnboardingFlowView(),
          ShellState.resetPassword => const ResetPasswordView(),
          ShellState.main => const MainShellView(),
        };
      },
    );
  }
}

class MainShellView extends StatelessWidget {
  const MainShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tabs = [
      const HomeView(),
      const FoodHubView(),
      const DailyPlanView(),
      const ProgressView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: IndexedStack(index: state.mainTabIndex, children: tabs),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: NutriColors.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [NutriColors.cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            selectedIndex: state.mainTabIndex,
            onDestinationSelected: (value) =>
                unawaited(state.setMainTabIndex(value)),
            height: 78,
            elevation: 0,
            backgroundColor: Colors.transparent,
            indicatorColor: NutriColors.mintSoft,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Ana Sayfa'),
              NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu),
                  label: 'Yemek'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'Planlarım'),
              NavigationDestination(
                  icon: Icon(Icons.stacked_line_chart),
                  selectedIcon: Icon(Icons.show_chart),
                  label: 'Takip'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }
}
