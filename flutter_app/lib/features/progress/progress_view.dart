import 'package:flutter/material.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takip')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('İlerleme', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricCard(title: 'Seri', value: '5 gün', subtitle: 'Kayıt tutuldu', tint: NutriColors.mint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(title: 'Ortalama', value: '1780 kcal', subtitle: '7 gün', tint: NutriColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MetricCard(
            title: 'Nuri içgörüsü',
            value: 'Protein iyi gidiyor',
            subtitle: 'Akşam karbonhidrat porsiyonlarını biraz küçültmek hedefe yaklaştırır.',
            tint: NutriColors.coral,
          ),
        ],
      ),
    );
  }
}
