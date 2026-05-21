import 'package:flutter/material.dart';
import 'dart:async';
import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../auth/auth_view.dart';
import '../chat/chat_view.dart';
import '../food/food_view.dart';
import '../home/home_view.dart';
import '../onboarding/onboarding_view.dart';
import '../plan/plan_view.dart';
import '../progress/progress_view.dart';
import '../profile/profile_view.dart';
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

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: state.mainTabIndex,
        onTap: (value) => unawaited(state.setMainTabIndex(value)),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Bugün'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Yemek'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Takip'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
      floatingActionButton: state.mainTabIndex == 0
          ? FloatingActionButton(
              backgroundColor: NutriColors.leaf,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NuriChatView()));
              },
              child: const Icon(Icons.auto_awesome),
            )
          : null,
    );
  }
}
