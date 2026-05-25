import 'package:flutter/material.dart';
import '../../app/app_scope.dart';
import '../../app/app_state.dart';
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

  bool get _canAdvance {
    final state = AppScope.of(context);
    // _NameStep is index 1; ad zorunlu, default 'Umut' kabul edilmez.
    if (step == 1) {
      final name = state.user.name.trim();
      return name.isNotEmpty && name.toLowerCase() != 'umut';
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final pages = <Widget>[
      _GoalStep(
        value: state.user.selectedGoal,
        onChanged: (goal) => setState(
            () => state.user = state.user.copyWith(selectedGoal: goal)),
      ),
      _NameStep(
        user: state.user,
        onChanged: (updated) => setState(() => state.user = updated),
      ),
      _BodyStep(
        user: state.user,
        onChanged: (updated) => setState(() => state.user = updated),
      ),
      _TargetStep(
        user: state.user,
        onChanged: (updated) => setState(() => state.user = updated),
      ),
      _ActivityStep(
        value: state.user.activityLevel,
        onChanged: (level) => setState(
            () => state.user = state.user.copyWith(activityLevel: level)),
      ),
      _LoggingStep(
        value: state.user.preferredLoggingMethod,
        photoEnabled: state.photoMealInputEnabled,
        voiceEnabled: state.voiceMealInputEnabled,
        onChanged: (method) => setState(() => state.user =
            state.user.copyWith(preferredLoggingMethod: method)),
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
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                        value: (step + 1) / pages.length,
                        color: NutriColors.leaf),
                  ),
                  const SizedBox(width: 12),
                  Text('${step + 1}/${pages.length}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: NutriColors.muted)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: pages[step])),
              const SizedBox(height: 12),
              PrimaryButton(
                title: step == pages.length - 1
                    ? 'Hadi başlayalım'
                    : 'Devam et',
                icon: step == pages.length - 1
                    ? Icons.arrow_forward
                    : Icons.arrow_forward,
                onPressed: !_canAdvance
                    ? null
                    : () {
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

// ---------------------------------------------------------------------------
// Step 1: Goal
// ---------------------------------------------------------------------------

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
        Text('Hedefin ne?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text('Günlük hedeflerini buna göre hesaplayacağız.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted)),
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

// ---------------------------------------------------------------------------
// Step 2: Name (extracted from Profile — single focused decision)
// ---------------------------------------------------------------------------

class _NameStep extends StatefulWidget {
  const _NameStep({required this.user, required this.onChanged});

  final UserProfile user;
  final ValueChanged<UserProfile> onChanged;

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    // Default 'Umut' constructor değerini kullanıcının kendi adını yazmaya
    // teşvik etmek için boş gösteriyoruz.
    final initial = widget.user.name == 'Umut' ? '' : widget.user.name;
    nameController = TextEditingController(text: initial);
    nameController.addListener(_push);
  }

  void _push() {
    widget.onChanged(widget.user.copyWith(name: nameController.text));
    setState(() {}); // button enable/disable yeniden değerlendirilsin
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('name'),
      children: [
        Text('Sana nasıl hitap edelim?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text('Bu, hatırlatma ve Nuri mesajlarında kullanılacak.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: Theme.of(context).textTheme.headlineSmall,
          decoration: const InputDecoration(
            labelText: 'Adın',
            hintText: 'Örn: Ayşe',
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Body (gender + age + height + current weight)
// ---------------------------------------------------------------------------

class _BodyStep extends StatefulWidget {
  const _BodyStep({required this.user, required this.onChanged});

  final UserProfile user;
  final ValueChanged<UserProfile> onChanged;

  @override
  State<_BodyStep> createState() => _BodyStepState();
}

class _BodyStepState extends State<_BodyStep> {
  late int age;
  late int height;
  late int weight;
  late Gender gender;

  @override
  void initState() {
    super.initState();
    age = widget.user.age;
    height = widget.user.heightCm;
    weight = widget.user.weightKg;
    gender = widget.user.gender;
  }

  void _push() {
    widget.onChanged(widget.user.copyWith(
      age: age,
      heightCm: height,
      weightKg: weight,
      gender: gender,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('body'),
      children: [
        Text('Vücudunu tanıyalım',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
            'Bu bilgiler günlük kalori ve makro hedefini hesaplamak için kullanılır. App içinde kalır.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 20),
        DropdownButtonFormField<Gender>(
          initialValue: gender,
          items: Gender.values
              .map((g) => DropdownMenuItem(value: g, child: Text(g.title)))
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => gender = value);
            _push();
          },
          decoration: const InputDecoration(labelText: 'Cinsiyet'),
        ),
        const SizedBox(height: 18),
        Text('Yaş: $age'),
        Slider(
          value: age.toDouble(),
          min: 16,
          max: 80,
          divisions: 64,
          onChanged: (value) {
            setState(() => age = value.round());
            _push();
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
            _push();
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
            _push();
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4: Target weight (own decision; default depends on goal)
// ---------------------------------------------------------------------------

class _TargetStep extends StatefulWidget {
  const _TargetStep({required this.user, required this.onChanged});

  final UserProfile user;
  final ValueChanged<UserProfile> onChanged;

  @override
  State<_TargetStep> createState() => _TargetStepState();
}

class _TargetStepState extends State<_TargetStep> {
  late int target;

  @override
  void initState() {
    super.initState();
    target = widget.user.targetWeightKg ?? _defaultForGoal(widget.user);
    // İlk defa girildiğinde parent state'i de bilgilendir
    if (widget.user.targetWeightKg == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(widget.user.copyWith(targetWeightKg: target));
      });
    }
  }

  int _defaultForGoal(UserProfile user) {
    return switch (user.selectedGoal) {
      Goal.weightLoss => (user.weightKg - 5).clamp(35, 180),
      Goal.gainMuscle => (user.weightKg + 3).clamp(35, 180),
      Goal.maintain => user.weightKg,
      Goal.fasting => user.weightKg,
    };
  }

  @override
  Widget build(BuildContext context) {
    final delta = target - widget.user.weightKg;
    final deltaText = delta == 0
        ? 'Aynı kiloda kalmak istiyorsun.'
        : delta > 0
            ? '+$delta kg almak istiyorsun.'
            : '$delta kg vermek istiyorsun.';

    return ListView(
      key: const ValueKey('target'),
      children: [
        Text('Hedef kilon nedir?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(deltaText,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 24),
        Text('Hedef kilo: $target kg',
            style: Theme.of(context).textTheme.titleMedium),
        Slider(
          value: target.toDouble(),
          min: 35,
          max: 180,
          divisions: 145,
          onChanged: (value) {
            setState(() => target = value.round());
            widget.onChanged(
                widget.user.copyWith(targetWeightKg: target));
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5: Activity
// ---------------------------------------------------------------------------

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.value, required this.onChanged});

  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;

  String _subtitleFor(ActivityLevel level) => switch (level) {
        ActivityLevel.sedentary => 'Günde ~5.000 adımdan az',
        ActivityLevel.light => 'Günde 5–8 bin adım',
        ActivityLevel.moderate => 'Günde 8–12 bin adım veya haftada 2-3 egzersiz',
        ActivityLevel.active => 'Günde 12 bin adım üstü veya düzenli antrenman',
      };

  IconData _iconFor(ActivityLevel level) => switch (level) {
        ActivityLevel.sedentary => Icons.chair_outlined,
        ActivityLevel.light => Icons.directions_walk,
        ActivityLevel.moderate => Icons.directions_run,
        ActivityLevel.active => Icons.fitness_center,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('activity'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Günün nasıl geçiyor?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 16),
        ...ActivityLevel.values.map(
          (level) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(level),
              child: SelectionTile(
                title: level.title,
                subtitle: _subtitleFor(level),
                icon: _iconFor(level),
                selected: value == level,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 6: Logging preference
// Photo/voice flag kapalıysa "Yakında" rozetiyle gösterip seçilemez yapıyoruz.
// Mixed seçeneği, photo ve voice ikisi de açıksa anlamlı; aksi halde gizli.
// ---------------------------------------------------------------------------

class _LoggingStep extends StatelessWidget {
  const _LoggingStep({
    required this.value,
    required this.photoEnabled,
    required this.voiceEnabled,
    required this.onChanged,
  });

  final LoggingMethod value;
  final bool photoEnabled;
  final bool voiceEnabled;
  final ValueChanged<LoggingMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final methods = <LoggingMethod>[
      LoggingMethod.text,
      LoggingMethod.photo,
      LoggingMethod.voice,
      // Mixed sadece her ikisi de gerçekten kullanılabilir hâle gelince anlam taşır.
      if (photoEnabled && voiceEnabled) LoggingMethod.mixed,
    ];

    bool _isComingSoon(LoggingMethod method) => switch (method) {
          LoggingMethod.text => false,
          LoggingMethod.photo => !photoEnabled,
          LoggingMethod.voice => !voiceEnabled,
          LoggingMethod.mixed => false,
        };

    return Column(
      key: const ValueKey('logging'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sana en kolay gelen yol hangisi?',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
            'İlk sürümde yazıyla başlıyoruz; fotoğraf ve ses çok yakında açılacak.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 16),
        ...methods.map(
          (method) {
            final comingSoon = _isComingSoon(method);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: comingSoon ? null : () => onChanged(method),
                child: SelectionTile(
                  title: method.title,
                  icon: switch (method) {
                    LoggingMethod.photo => Icons.photo_camera,
                    LoggingMethod.text => Icons.chat_bubble_outline,
                    LoggingMethod.voice => Icons.mic_none,
                    LoggingMethod.mixed => Icons.auto_awesome,
                  },
                  selected: value == method && !comingSoon,
                  comingSoon: comingSoon,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 7: Summary
// Her metriğin altında neden bu değerin hesaplandığına dair tek satır not.
// ---------------------------------------------------------------------------

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.user,
    required this.calorieTarget,
    required this.macroTargets,
  });

  final UserProfile user;
  final int calorieTarget;
  final MacroTargets macroTargets;

  String _calorieRationale() {
    final goalPart = switch (user.selectedGoal) {
      Goal.weightLoss => 'kilo verme hedefin',
      Goal.gainMuscle => 'kas kazanma hedefin',
      Goal.maintain => 'kilonu koruma tercihin',
      Goal.fasting => 'aralıklı oruç planın',
    };
    final activityPart = switch (user.activityLevel) {
      ActivityLevel.sedentary => 'düşük hareket düzeyin',
      ActivityLevel.light => 'hafif aktivite düzeyin',
      ActivityLevel.moderate => 'orta aktivite düzeyin',
      ActivityLevel.active => 'yüksek aktivite düzeyin',
    };
    return '$goalPart ve $activityPart üzerinden hesaplandı.';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('summary'),
      children: [
        Text('Hedeflerin hazır',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
            'Ana ekran doğrudan bu hedeflere göre açılacak. İstediğin zaman Profil > Hesap üzerinden güncelleyebilirsin.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted)),
        const SizedBox(height: 20),
        MetricCard(
          title: 'Günlük kalori',
          value: '$calorieTarget kcal',
          subtitle: _calorieRationale(),
          tint: NutriColors.mint,
        ),
        const SizedBox(height: 10),
        MetricCard(
          title: 'Makro hedefi',
          value:
              '${macroTargets.proteinGr}g · ${macroTargets.carbsGr}g · ${macroTargets.fatGr}g',
          subtitle: 'Protein · Karbonhidrat · Yağ',
          tint: NutriColors.amber,
        ),
        const SizedBox(height: 10),
        MetricCard(
          title: 'Hedef kilo',
          value: user.targetWeightKg == null
              ? '${user.weightKg} kg (değişiklik yok)'
              : '${user.targetWeightKg} kg',
          subtitle: _targetSubtitle(),
          tint: NutriColors.leaf,
        ),
      ],
    );
  }

  String _targetSubtitle() {
    final target = user.targetWeightKg;
    if (target == null) return 'Profile kaydedildi';
    final delta = target - user.weightKg;
    if (delta == 0) return 'Aynı kiloda kalmayı seçtin';
    if (delta > 0) return '+$delta kg almayı hedefliyorsun';
    return '$delta kg vermeyi hedefliyorsun';
  }
}
