import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class PremiumView extends StatefulWidget {
  const PremiumView({super.key});

  @override
  State<PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<PremiumView> {
  SubscriptionPlan _selectedPlan = SubscriptionPlan.monthly;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        actions: [
          if (state.isPremiumUser)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  state.subscriptionState.plan.title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: NutriColors.leaf),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _HeroCard(
                isPremiumUser: state.isPremiumUser,
                currentPlan: state.subscriptionState.plan,
                activeSince: state.subscriptionState.purchasedAt,
              ),
              const SizedBox(height: 16),
              Text('Premium ile açılanlar',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _BenefitChip(text: 'Haftalik plan'),
                  _BenefitChip(text: 'Derin AI yorumlar'),
                  _BenefitChip(text: 'Daha akilli alternatifler'),
                  _BenefitChip(text: 'Gelişmiş insight katmani'),
                  _BenefitChip(text: 'Reklamsiz deneyim'),
                ],
              ),
              const SizedBox(height: 18),
              SectionTitle(title: 'Plan secimi'),
              const SizedBox(height: 10),
              _PlanCard(
                plan: SubscriptionPlan.monthly,
                selected: _selectedPlan == SubscriptionPlan.monthly,
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.monthly),
              ),
              const SizedBox(height: 10),
              _PlanCard(
                plan: SubscriptionPlan.yearly,
                selected: _selectedPlan == SubscriptionPlan.yearly,
                onTap: () =>
                    setState(() => _selectedPlan = SubscriptionPlan.yearly),
              ),
              const SizedBox(height: 18),
              SectionTitle(title: 'Neden degiyor?'),
              const SizedBox(height: 10),
              const _ValueList(),
              const SizedBox(height: 18),
              if (state.isPremiumUser)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF0E6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Premium aktif',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Plan: ${state.subscriptionState.plan.title}  •  Kaynak: ${state.subscriptionState.source}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (state.subscriptionState.renewsAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Yenileme: ${state.subscriptionState.renewsAt}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                )
              else
                PrimaryButton(
                  title: state.premiumCheckoutEnabled
                      ? 'Devam et'
                      : 'Ciktiginda haber ver',
                  icon: state.premiumCheckoutEnabled
                      ? Icons.arrow_forward
                      : Icons.notifications_active_outlined,
                  onPressed: () {
                    if (!state.premiumCheckoutEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Odeme henuz aktif degil. Premium su an on izleme modunda.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PremiumPaymentView(selectedPlan: _selectedPlan),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class PremiumPaymentView extends StatelessWidget {
  const PremiumPaymentView({super.key, required this.selectedPlan});

  final SubscriptionPlan selectedPlan;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Odeme ozeti')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          SectionTitle(title: 'Seçilen plan'),
          const SizedBox(height: 10),
          _PlanCard(plan: selectedPlan, selected: true, onTap: null),
          const SizedBox(height: 18),
          SectionTitle(title: 'Neleri acacaksin'),
          const SizedBox(height: 10),
          const _ValueList(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NutriColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Toplam',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  selectedPlan.priceLabel,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            title: state.premiumCheckoutEnabled
                ? 'Satin al'
                : 'Odeme henuz aktif degil',
            icon: Icons.workspace_premium_outlined,
            onPressed: () async {
              if (!state.premiumCheckoutEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Odeme henuz aktif degil. Premium su an on izleme modunda.'),
                  ),
                );
                return;
              }
              await state.purchasePremium(selectedPlan);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selectedPlan.title} aktif edildi.'),
                ),
              );
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Bu akış MVP icin mock odeme olarak calisir. Gercek odeme altyapisi sonra baglanacak.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: NutriColors.muted),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isPremiumUser,
    required this.currentPlan,
    required this.activeSince,
  });

  final bool isPremiumUser;
  final SubscriptionPlan currentPlan;
  final String? activeSince;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            isPremiumUser ? const Color(0xFFDFF0E6) : const Color(0xFFF4F1EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPremiumUser ? 'Premium aktif' : 'Premium ile daha akilli kullan',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: NutriColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            isPremiumUser
                ? 'Planin hazir.'
                : 'NutriEasy’i karar destek araci haline getir.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            isPremiumUser
                ? 'Açık plan: ${currentPlan.title}.'
                : 'Haftalik plan, derin yorumlar ve daha akilli alternatiflerle devam et.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (activeSince != null) ...[
            const SizedBox(height: 6),
            Text(
              'Aktivasyon: $activeSince',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDFF0E6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: selected ? NutriColors.leaf : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? NutriColors.leaf : NutriColors.mint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                plan == SubscriptionPlan.yearly
                    ? Icons.workspace_premium
                    : Icons.star_outline,
                color: selected ? Colors.white : NutriColors.leaf,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    plan == SubscriptionPlan.monthly
                        ? 'Aylik denge isteyenler icin.'
                        : 'Yillik tasarruf ve daha az dusunme.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.priceLabel,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                if (selected)
                  const Icon(Icons.check_circle, color: NutriColors.leaf)
                else
                  Text('Sec', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: NutriColors.mint,
      side: const BorderSide(color: Colors.transparent),
      labelStyle: const TextStyle(color: NutriColors.leaf),
    );
  }
}

class _ValueList extends StatelessWidget {
  const _ValueList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ValueRow(
          title: 'Haftalik plan',
          subtitle: 'Gunun ritmini takip eden rehber akisi.',
        ),
        SizedBox(height: 10),
        _ValueRow(
          title: 'Gelişmiş AI yorumlari',
          subtitle: 'Sadece sayi degil, karar ciktisi verir.',
        ),
        SizedBox(height: 10),
        _ValueRow(
          title: 'Akilli alternatifler',
          subtitle: 'Daha iyi uyumlayan besin ve ogun onerileri.',
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: NutriColors.leaf),
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
        ],
      ),
    );
  }
}
