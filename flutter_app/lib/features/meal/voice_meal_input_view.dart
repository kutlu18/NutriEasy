// voice_meal_input_view.dart — split from meal_view.dart for clarity.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../shared/widgets.dart';

import 'meal_processing_view.dart';

class VoiceMealInputView extends StatefulWidget {
  const VoiceMealInputView({super.key});

  @override
  State<VoiceMealInputView> createState() => _VoiceMealInputViewState();
}

class _VoiceMealInputViewState extends State<VoiceMealInputView> {
  MealType mealType = MealType.breakfast;
  final transcriptController = TextEditingController(
      text: '2 yumurta, bir dilim tam buğday ekmeği ve ...');
  bool isRecording = false;

  @override
  void dispose() {
    transcriptController.dispose();
    super.dispose();
  }

  Future<void> _simulateRecord() async {
    setState(() => isRecording = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    transcriptController.text =
        '2 yumurta, 1 dilim tam buğday ekmeği, biraz peynir ve domates';
    if (!mounted) return;
    setState(() => isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Öğününü anlat'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: const Color(0xFF15151A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2B2B31)),
                ),
                child: Icon(
                  isRecording ? Icons.mic : Icons.mic_none,
                  size: 72,
                  color: const Color(0xFFB794FF),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                isRecording ? 'Kayıt alınıyor...' : 'Kayıt için hazır',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A2A2E)),
              ),
              child: TextField(
                controller: transcriptController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(color: Colors.white, height: 1.4),
                decoration: const InputDecoration(
                  labelText: 'Transkript',
                  labelStyle: TextStyle(color: Color(0xFFB794FF)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MealType.values
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type.title),
                      selected: mealType == type,
                      onSelected: (_) => setState(() => mealType = type),
                      selectedColor: const Color(0xFFB794FF),
                      backgroundColor: const Color(0xFF16161A),
                      labelStyle: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color:
                                mealType == type ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(99)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              title: isRecording ? 'Kaydediliyor' : 'Kayda başla',
              icon: Icons.mic,
              isBusy: isRecording,
              onPressed: isRecording
                  ? null
                  : () async {
                      await _simulateRecord();
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealProcessingView(
                      mealType: mealType,
                      sourceType: MealSourceType.voice,
                      source: transcriptController.text,
                      sourceLabel: transcriptController.text,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2B2B31)),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Analize gönder'),
            ),
          ],
        ),
      ),
    );
  }
}

