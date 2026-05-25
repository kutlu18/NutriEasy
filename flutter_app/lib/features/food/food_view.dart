import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../core/services/nutri_supabase_service.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';
import '../meal/meal_view.dart';

Future<void> showFoodProductSheet(
  BuildContext context,
  FoodSearchResult food, {
  MealType initialMealType = MealType.snack,
}) async {
  final state = AppScope.of(context);
  final servings = food.servings.isNotEmpty
      ? food.servings
      : [
          FoodServingOption(
            description: '1 serving',
            metricAmount: 1,
            metricUnit: 'serving',
            calories: food.calories,
            proteinGr: food.protein,
            carbsGr: food.carbs,
            fatGr: food.fat,
            isDefault: true,
          ),
        ];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      FoodServingOption selectedServing = servings.firstWhere(
        (serving) => serving.isDefault,
        orElse: () => servings.first,
      );
      double quantity = 1;
      MealType mealType = initialMealType;

      return StatefulBuilder(
        builder: (context, setModalState) {
          final totalCalories = (selectedServing.calories * quantity).round();
          final totalProtein = (selectedServing.proteinGr * quantity).round();
          final totalCarbs = (selectedServing.carbsGr * quantity).round();
          final totalFat = (selectedServing.fatGr * quantity).round();

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: NutriColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6D2CD),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDEFE6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.restaurant_outlined,
                              color: NutriColors.leaf),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(food.name,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              if ((food.brand ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(food.brand!,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                selectedServing.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: NutriColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _NutritionGrid(
                      calories: totalCalories,
                      protein: totalProtein,
                      carbs: totalCarbs,
                      fat: totalFat,
                    ),
                    const SizedBox(height: 18),
                    Text('Porsiyon',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: servings
                          .map(
                            (serving) => ChoiceChip(
                              label: Text(serving.label),
                              selected: serving == selectedServing,
                              onSelected: (_) => setModalState(
                                  () => selectedServing = serving),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Text('Miktar',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _QuantityStepper(
                      value: quantity,
                      onChanged: (nextValue) =>
                          setModalState(() => quantity = nextValue),
                    ),
                    const SizedBox(height: 18),
                    Text('Ogun tipi',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _MealTypeSelector(
                      selected: mealType,
                      onChanged: (value) =>
                          setModalState(() => mealType = value),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      title: 'Ogune ekle',
                      icon: Icons.add_circle_outline,
                      isBusy: state.isSavingMeal,
                      onPressed: () async {
                        final ok = await state.addFoodToMeal(
                          food: food,
                          mealType: mealType,
                          quantity: quantity,
                          serving: selectedServing,
                        );
                        if (!sheetContext.mounted) return;
                        if (ok) {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${food.name} added')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class FoodHubView extends StatelessWidget {
  const FoodHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Yemek')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final popular = state.popularFoods;
          final history = state.foodSearchHistory;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Urun ara ve ekle',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Manuel ogun girişi, hizli ekleme ve urun detayi tek alanda.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: NutriColors.muted),
              ),
              const SizedBox(height: 16),
              _ShortcutCard(
                title: 'Food search',
                subtitle: 'Besin veritabaninda ara',
                icon: Icons.search,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodSearchView())),
              ),
              const SizedBox(height: 10),
              _ShortcutCard(
                title: 'Quick add',
                subtitle: 'Populer urunleri tek dokunusla ekle',
                icon: Icons.add_circle_outline,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuickAddView())),
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 18),
                SectionHeader(title: 'Son aramalar'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: history
                      .map(
                        (item) => ActionChip(
                          label: Text(item),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FoodSearchView(initialQuery: item),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Populer urunler',
                actionLabel: 'Gozat',
                onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FoodSearchView())),
              ),
              const SizedBox(height: 10),
              if (popular.isEmpty)
                const EmptyState(
                  title: 'Henuz populer urun yok',
                  subtitle:
                      'Ogunler kaydedildikce sik kullanilan urunler burada gorunur.',
                  icon: Icons.local_fire_department_outlined,
                )
              else
                SizedBox(
                  height: 146,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: popular.take(6).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final food = popular[index];
                      return _PopularFoodCard(
                        food: food,
                        onTap: () => showFoodProductSheet(context, food),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class FoodSearchView extends StatefulWidget {
  const FoodSearchView({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<FoodSearchView> createState() => _FoodSearchViewState();
}

class _FoodSearchViewState extends State<FoodSearchView> {
  final _queryController = TextEditingController();
  final _service = NutriSupabaseService();
  Timer? _debounce;
  bool _isLoading = false;
  String _query = '';
  String? _error;
  List<FoodSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _queryController.text = widget.initialQuery;
    _query = widget.initialQuery;
    if (widget.initialQuery.trim().length >= 2) {
      unawaited(_search(widget.initialQuery, saveHistory: false));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    setState(() {
      _query = value;
      _error = null;
    });

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _results = const [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_search(trimmed));
    });
  }

  Future<void> _search(String query, {bool saveHistory = true}) async {
    try {
      final results = await _service.searchFoods(query: query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
      if (saveHistory) {
        await AppScope.of(context).recordFoodSearch(query);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _isLoading = false;
        _error = 'Arama basarisiz oldu. Lutfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final showDiscovery = _query.trim().length < 2;
    final popular = state.popularFoods;
    final history = state.foodSearchHistory;

    return Scaffold(
      appBar: AppBar(title: const Text('Urun ara')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _queryController,
            onChanged: _scheduleSearch,
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.length < 2) return;
              _debounce?.cancel();
              unawaited(_search(trimmed));
            },
            decoration: InputDecoration(
              labelText: 'Urun ara',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _queryController.clear();
                        _scheduleSearch('');
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            InlineMessage(
              text: _error!,
              icon: Icons.error_outline,
              backgroundColor: const Color(0x1AF04F33),
              foregroundColor: NutriColors.coral,
            ),
            const SizedBox(height: 12),
          ],
          if (_isLoading) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 14),
          ],
          if (showDiscovery) ...[
            if (history.isNotEmpty) ...[
              SectionHeader(title: 'Son aramalar'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: history
                    .map(
                      (item) => ActionChip(
                        label: Text(item),
                        onPressed: () {
                          _queryController.text = item;
                          _scheduleSearch(item);
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
            ],
            SectionHeader(
              title: 'Populer urunler',
              actionLabel: 'Hizli ekle',
              onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuickAddView())),
            ),
            const SizedBox(height: 10),
            if (popular.isEmpty)
              const EmptyState(
                title: 'Henuz urun yok',
                subtitle:
                    'Kaydedilen ogunler burada populer urunlere donusecek.',
                icon: Icons.local_fire_department_outlined,
              )
            else
              SizedBox(
                height: 146,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final food = popular[index];
                    return _PopularFoodCard(
                      food: food,
                      onTap: () => showFoodProductSheet(context, food),
                    );
                  },
                ),
              ),
          ] else ...[
            if (_results.isEmpty && !_isLoading)
              const EmptyState(
                title: 'Sonuc yok',
                subtitle:
                    'Baska bir urun adi deneyin ya da populer urunleri kullanin.',
                icon: Icons.search_off,
              )
            else
              ..._results.map(
                (food) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FoodSearchResultTile(
                    food: food,
                    onTap: () => showFoodProductSheet(context, food),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class QuickAddView extends StatelessWidget {
  const QuickAddView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final popular = state.popularFoods;

    return Scaffold(
      appBar: AppBar(title: const Text('Hizli ekle')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Quick add', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Bir urune dokun, miktari sec ve gunune kaydet.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NutriColors.muted),
          ),
          const SizedBox(height: 16),
          if (popular.isEmpty)
            const EmptyState(
              title: 'Henuz populer urun yok',
              subtitle:
                  'Birkac ogun kaydettikten sonra hizli ekleme onerileri buraya gelir.',
              icon: Icons.add_circle_outline,
            )
          else
            ...popular.take(8).map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuickAddCard(
                      food: food,
                      onTap: () => showFoodProductSheet(context, food,
                          initialMealType: MealType.snack),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _FoodSearchResultTile extends StatelessWidget {
  const _FoodSearchResultTile({
    required this.food,
    required this.onTap,
  });

  final FoodSearchResult food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final serving = food.primaryServing;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDDEFE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.restaurant_outlined,
                  color: NutriColors.leaf),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  if ((food.brand ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(food.brand!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${serving?.calories ?? food.calories} kcal | P ${serving?.proteinGr ?? food.protein} | C ${serving?.carbsGr ?? food.carbs} | F ${serving?.fatGr ?? food.fat}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  serving?.label ?? '1 serving',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: NutriColors.muted),
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 8),
                const Icon(Icons.add_circle_outline, color: NutriColors.leaf),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({
    required this.food,
    required this.onTap,
  });

  final FoodSearchResult food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final serving = food.primaryServing;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD0EBD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.flash_on_outlined, color: NutriColors.leaf),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${serving?.calories ?? food.calories} kcal | quick add',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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

class _PopularFoodCard extends StatelessWidget {
  const _PopularFoodCard({
    required this.food,
    required this.onTap,
  });

  final FoodSearchResult food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final serving = food.primaryServing;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFD0EBD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.restaurant_menu, color: NutriColors.leaf),
            ),
            const SizedBox(height: 14),
            Text(
              food.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '${serving?.calories ?? food.calories} kcal',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: NutriColors.leaf),
            ),
            const SizedBox(height: 4),
            Text(
              serving?.label ?? 'Quick add',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NutritionStat(
            label: 'kcal',
            value: calories.toString(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NutritionStat(
            label: 'Protein',
            value: '$protein g',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NutritionStat(
            label: 'Carbs',
            value: '$carbs g',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _NutritionStat(
            label: 'Fat',
            value: '$fat g',
          ),
        ),
      ],
    );
  }
}

class _NutritionStat extends StatelessWidget {
  const _NutritionStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 0.5
                ? () => onChanged((value - 0.5).clamp(0.5, 20))
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Expanded(
            child: Column(
              children: [
                Text(_formatQuantity(value),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('servings', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onChanged((value + 0.5).clamp(0.5, 20)),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _MealTypeSelector extends StatelessWidget {
  const _MealTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final MealType selected;
  final ValueChanged<MealType> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = MealType.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (mealType) => ChoiceChip(
              label: Text(mealType.title),
              selected: mealType == selected,
              onSelected: (_) => onChanged(mealType),
            ),
          )
          .toList(),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A0D3A2A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFD0EBD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: NutriColors.leaf),
            ),
            const SizedBox(width: 12),
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
