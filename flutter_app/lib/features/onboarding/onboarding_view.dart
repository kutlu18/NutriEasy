import 'package:flutter/material.dart';
import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class OnboardingFlowView extends StatefulWidget {
  const OnboardingFlowView({super.key});

  @override
  State<OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends State<OnboardingFlowView> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final pages = [
      _GoalStep(
        value: state.user.selectedGoal,
        onChanged: (goal) => setState(() => state.user = state.user.copyWith(selectedGoal: goal)),
      ),
      _ProfileStep(
        user: state.user,
        onChanged: (updated) => setState(() => state.user = updated),
      ),
      _ActivityStep(
        value: state.user.activityLevel,
        onChanged: (level) => setState(() => state.user = state.user.copyWith(activityLevel: level)),
      ),
      _LoggingStep(
        value: state.user.preferredLoggingMethod,
        onChanged: (method) => setState(() => state.user = state.user.copyWith(preferredLoggingMethod: method)),
      ),
      _SummaryStep(
        user: state.user,
        calorieTarget: state.calorieTargetForProfile,
        macroTargets: state.macroTargetsForProfile,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(value: (step + 1) / pages.length, color: NutriColors.leaf),
              const SizedBox(height: 20),
              Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: pages[step])),
              const SizedBox(height: 12),
              PrimaryButton(
                title: step == pages.length - 1 ? 'NutriEasy’e başla' : 'Devam et',
                icon: step == pages.length - 1 ? Icons.rocket_launch : Icons.arrow_forward,
                onPressed: () {
                  if (step == pages.length - 1) {
                    state.completeOnboarding();
                  } else {
                    setState(() => step += 1);
                  }
                },
              ),
              if (step > 0)
                TextButton(
                  onPressed: () => setState(() => step -= 1),
                  child: const Text('Geri'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({required this.value, required this.onChanged});

  final Goal value;
  final ValueChanged<Goal> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('goal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hedefin ne?', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text('Günlük hedeflerini buna göre hesaplayacağız.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 16),
        ...Goal.values.map(
          (goal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(goal),
              child: SelectionTile(
                title: goal.title,
                icon: switch (goal) {
                  Goal.weightLoss => Icons.local_fire_department,
                  Goal.gainMuscle => Icons.fitness_center,
                  Goal.maintain => Icons.eco,
                  Goal.fasting => Icons.nightlight,
                },
                selected: value == goal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({required this.user, required this.onChanged});

  final UserProfile user;
  final ValueChanged<UserProfile> onChanged;

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late int age;
  late int height;
  late int weight;
  late int target;
  late Gender gender;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    emailController = TextEditingController(text: widget.user.email);
    age = widget.user.age;
    height = widget.user.heightCm;
    weight = widget.user.weightKg;
    target = widget.user.targetWeightKg ?? widget.user.weightKg;
    gender = widget.user.gender;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void pushUpdate() {
    widget.onChanged(
      widget.user.copyWith(
        name: nameController.text,
        email: emailController.text,
        age: age,
        heightCm: height,
        weightKg: weight,
        targetWeightKg: target,
        gender: gender,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('profile'),
      children: [
        Text('Seni biraz tanıyalım', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 12),
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Adın')),
        const SizedBox(height: 10),
        TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-posta')),
        const SizedBox(height: 10),
        DropdownButtonFormField<Gender>(
          value: gender,
          items: Gender.values
              .map((g) => DropdownMenuItem(value: g, child: Text(g.title)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => gender = value);
            pushUpdate();
          },
          decoration: const InputDecoration(labelText: 'Cinsiyet'),
        ),
        const SizedBox(height: 10),
        Text('Yaş: $age'),
        Slider(
          value: age.toDouble(),
          min: 16,
          max: 80,
          divisions: 64,
          onChanged: (value) {
            setState(() => age = value.round());
            pushUpdate();
          },
        ),
        Text('Boy: $height cm'),
        Slider(
          value: height.toDouble(),
          min: 130,
          max: 220,
          divisions: 90,
          onChanged: (value) {
            setState(() => height = value.round());
            pushUpdate();
          },
        ),
        Text('Kilo: $weight kg'),
        Slider(
          value: weight.toDouble(),
          min: 35,
          max: 180,
          divisions: 145,
          onChanged: (value) {
            setState(() => weight = value.round());
            pushUpdate();
          },
        ),
        Text('Hedef kilo: $target kg'),
        Slider(
          value: target.toDouble(),
          min: 35,
          max: 180,
          divisions: 145,
          onChanged: (value) {
            setState(() => target = value.round());
            pushUpdate();
          },
        ),
      ],
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.value, required this.onChanged});

  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('activity'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Günün nasıl geçiyor?', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        ...ActivityLevel.values.map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(level),
              child: SelectionTile(
                title: level.title,
                icon: Icons.directions_walk,
                selected: value == level,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoggingStep extends StatelessWidget {
  const _LoggingStep({required this.value, required this.onChanged});

  final LoggingMethod value;
  final ValueChanged<LoggingMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('logging'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sana en kolay gelen yol hangisi?', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        ...LoggingMethod.values.map(
          (method) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(method),
              child: SelectionTile(
                title: method.title,
                icon: switch (method) {
                  LoggingMethod.photo => Icons.photo_camera,
                  LoggingMethod.text => Icons.chat_bubble_outline,
                  LoggingMethod.mixed => Icons.auto_awesome,
                },
                selected: value == method,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.user,
    required this.calorieTarget,
    required this.macroTargets,
  });

  final UserProfile user;
  final int calorieTarget;
  final MacroTargets macroTargets;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('summary'),
      children: [
        Text('Hedeflerin hazır', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Bu özetle ana ekrana geçeceğiz ve ilk dashboard doğrudan buna göre açılacak.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
        ),
        const SizedBox(height: 16),
        MetricCard(
          title: 'Günlük kalori',
          value: '$calorieTarget kcal',
          subtitle: user.selectedGoal.title,
          tint: NutriColors.mint,
        ),
        const SizedBox(height: 10),
        MetricCard(
          title: 'Makro hedefi',
          value: '${macroTargets.proteinGr}P / ${macroTargets.carbsGr}C / ${macroTargets.fatGr}F',
          subtitle: 'Protein, karbonhidrat ve yağ hedefleri',
          tint: NutriColors.amber,
        ),
        const SizedBox(height: 10),
        MetricCard(
          title: 'Giriş tercihi',
          value: user.preferredLoggingMethod.title,
          subtitle: 'Ana ekranda öne çıkarılacak',
          tint: NutriColors.coral,
        ),
        const SizedBox(height: 10),
        MetricCard(
          title: 'Hedef kilo',
          value: user.targetWeightKg == null ? 'Belirlenmedi' : '${user.targetWeightKg} kg',
          subtitle: 'Profilde saklanacak',
          tint: NutriColors.leaf,
        ),
      ],
    );
  }
}
