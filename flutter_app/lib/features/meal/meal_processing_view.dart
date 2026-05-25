// meal_processing_view.dart — split from meal_view.dart for clarity.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

import 'meal_analysis_view.dart';

class MealProcessingView extends StatefulWidget {
  const MealProcessingView({
    super.key,
    required this.mealType,
    required this.sourceType,
    required this.source,
    required this.sourceLabel,
  });

  final MealType mealType;
  final MealSourceType sourceType;
  final String source;
  final String sourceLabel;

  @override
  State<MealProcessingView> createState() => _MealProcessingViewState();
}


class _MealProcessingViewState extends State<MealProcessingView> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  Future<void> _runAnalysis() async {
    final state = AppScope.of(context);
    switch (widget.sourceType) {
      case MealSourceType.text:
        await state.analyzeMeal(
          source: widget.source,
          mealType: widget.mealType,
          sourceType: widget.sourceType,
          sourceLabel: widget.sourceLabel,
        );
        break;
      case MealSourceType.photo:
        await state.analyzePhoto(
          sourceLabel: widget.sourceLabel,
          mealType: widget.mealType,
        );
        break;
      case MealSourceType.voice:
        await state.analyzeVoice(
          transcript: widget.source,
          mealType: widget.mealType,
        );
        break;
    }

    if (!mounted) return;
    if (state.selectedAnalysis == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MealAnalysisView()));
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.sourceType) {
      MealSourceType.text => Icons.chat_bubble_outline,
      MealSourceType.photo => Icons.photo_camera_outlined,
      MealSourceType.voice => Icons.mic_none,
    };

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Analiz ediliyor'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2E2E36)),
                ),
                child: Icon(icon, size: 64, color: const Color(0xFFB794FF)),
              ),
              const SizedBox(height: 24),
              Text(
                'Nuri analiz yapıyor',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Kaynak: ${widget.sourceType.title}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: const Color(0xFF9B9BA1)),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 220,
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: Color(0xFFB794FF),
                  backgroundColor: Color(0xFF26262B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


