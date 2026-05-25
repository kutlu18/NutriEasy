import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_state.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';
import '../food/food_view.dart';
import '../meal/meal_view.dart';
import '../plan/plan_view.dart';

class NuriChatView extends StatefulWidget {
  const NuriChatView({super.key});

  @override
  State<NuriChatView> createState() => _NuriChatViewState();
}

class _NuriChatViewState extends State<NuriChatView> {
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuri'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: state.refreshChatThread,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: NutriColors.leaf,
        foregroundColor: Colors.white,
        onPressed: () => _openShortcutSheet(context),
        child: const Icon(Icons.water_drop_outlined),
      ),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final messages = state.chatMessages;
          final suggestions = state.chatSuggestionChips;
          final recipeCards = state.chatRecipeCards;
          final contextSummary = state.chatThread?.contextSummary ??
              _contextSummaryFallback(state);

          return Column(
            children: [
              _ContextBand(
                summary: contextSummary,
                calorieTarget: state.dashboard.calorieTarget,
                consumedCalories: state.dashboard.consumedCalories,
                remainingCalories: state.dashboard.remainingCalories,
                fastingLabel: state.fastingSnapshot.statusLabel,
              ),
              if (state.isLoadingChat || state.isSendingChat)
                const LinearProgressIndicator(minHeight: 2),
              if (suggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SuggestionRail(
                    chips: suggestions,
                    onChipTap: (chip) {
                      inputController.text = chip.prompt;
                      inputController.selection = TextSelection.collapsed(
                          offset: inputController.text.length);
                      unawaited(state.sendChat(chip.prompt));
                    },
                  ),
                ),
              if (recipeCards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _RecipeRail(
                    cards: recipeCards,
                    onOpen: (card) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                RecipeDetailView(meal: card.toPlannedMeal())),
                      );
                    },
                    onApply: (card) =>
                        unawaited(state.applyPlannedMeal(card.toPlannedMeal())),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MessageBubble(
                        message: message,
                        onOpenRecipe: (card) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => RecipeDetailView(
                                    meal: card.toPlannedMeal())),
                          );
                        },
                        onApplyRecipe: (card) => unawaited(
                            state.applyPlannedMeal(card.toPlannedMeal())),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _ComposerBar(
                    controller: inputController,
                    isSending: state.isSendingChat,
                    onSubmitted: (value) => _sendMessage(state, value),
                    onSend: () => _sendMessage(state, inputController.text),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _contextSummaryFallback(AppState state) {
    final fasting = state.fastingSnapshot;
    return '${state.dashboard.calorieTarget} kcal hedef • ${state.dashboard.consumedCalories} kcal tüketildi • ${fasting.statusLabel}';
  }

  Future<void> _sendMessage(AppState state, String value) async {
    final text = value.trim();
    if (text.isEmpty) return;
    inputController.clear();
    await state.sendChat(text);
    if (scrollController.hasClients) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _openShortcutSheet(BuildContext context) async {
    final state = AppScope.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text('Hızlı aksiyonlar',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Fotoğrafla öğün',
                subtitle: 'Kamera veya galeri ile gir.',
                onTap: () {
                  if (!state.photoMealInputEnabled) {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Fotografla analiz henuz aktif degil.')),
                    );
                    return;
                  }
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PhotoMealInputView()));
                },
              ),
              _ActionTile(
                icon: Icons.chat_bubble_outline,
                title: 'Yazarak öğün',
                subtitle: 'Metinle hızlı analiz başlat.',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const TextMealInputView()));
                },
              ),
              _ActionTile(
                icon: Icons.mic_none,
                title: 'Sesle öğün',
                subtitle: 'Sesli giriş akışını aç.',
                onTap: () {
                  if (!state.voiceMealInputEnabled) {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sesle giris henuz aktif degil.')),
                    );
                    return;
                  }
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const VoiceMealInputView()));
                },
              ),
              _ActionTile(
                icon: Icons.search,
                title: 'Food search',
                subtitle: 'Manuel ürün ekle.',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const FoodSearchView()));
                },
              ),
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await state.sendChat('Bugün ne yemeliyim?');
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Nuri’ye sor'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContextBand extends StatelessWidget {
  const _ContextBand({
    required this.summary,
    required this.calorieTarget,
    required this.consumedCalories,
    required this.remainingCalories,
    required this.fastingLabel,
  });

  final String summary;
  final int calorieTarget;
  final int consumedCalories;
  final int remainingCalories;
  final String fastingLabel;

  @override
  Widget build(BuildContext context) {
    final ratio = calorieTarget == 0
        ? 0.0
        : (consumedCalories / calorieTarget).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Nuri bağlamı',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              MiniPill(text: fastingLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: NutriColors.leaf,
              backgroundColor: const Color(0xFFE4E0DC),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: Text('$consumedCalories / $calorieTarget kcal',
                      style: Theme.of(context).textTheme.labelLarge)),
              Text('Kalan $remainingCalories kcal',
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionRail extends StatelessWidget {
  const _SuggestionRail({
    required this.chips,
    required this.onChipTap,
  });

  final List<ChatSuggestionChip> chips;
  final ValueChanged<ChatSuggestionChip> onChipTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (chip) => ActionChip(
              label: Text(chip.label),
              onPressed: () => onChipTap(chip),
              backgroundColor: const Color(0xFFD0EBD6),
              labelStyle: const TextStyle(color: NutriColors.leaf),
            ),
          )
          .toList(),
    );
  }
}

class _RecipeRail extends StatelessWidget {
  const _RecipeRail({
    required this.cards,
    required this.onOpen,
    required this.onApply,
  });

  final List<ChatRecipeCard> cards;
  final ValueChanged<ChatRecipeCard> onOpen;
  final ValueChanged<ChatRecipeCard> onApply;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _RecipeCard(
            card: card,
            onOpen: () => onOpen(card),
            onApply: () => onApply(card),
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.card,
    required this.onOpen,
    required this.onApply,
  });

  final ChatRecipeCard card;
  final VoidCallback onOpen;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.title,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(card.subtitle,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  MiniPill(
                      text: card.mealType == MealType.dinner
                          ? 'Akşam'
                          : card.mealType.title),
                ],
              ),
              const SizedBox(height: 10),
              Text(card.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TinyStat(label: 'kcal', value: card.calories.toString()),
                  _TinyStat(label: 'P', value: card.proteinGr.toString()),
                  _TinyStat(label: 'C', value: card.carbsGr.toString()),
                  _TinyStat(label: 'Y', value: card.fatGr.toString()),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpen,
                      child: const Text('Tarifi aç'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onApply,
                      child: const Text('Öğüne ekle'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onOpenRecipe,
    required this.onApplyRecipe,
  });

  final ChatMessage message;
  final ValueChanged<ChatRecipeCard> onOpenRecipe;
  final ValueChanged<ChatRecipeCard> onApplyRecipe;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final bg = isUser ? NutriColors.leaf : Colors.white;
    final fg = isUser ? Colors.white : NutriColors.ink;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
                border: isUser ? null : Border.all(color: Colors.black12),
              ),
              child: Text(
                message.text,
                style:
                    Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
            if (message.contextSummary != null) ...[
              const SizedBox(height: 6),
              Text(
                message.contextSummary!,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: NutriColors.muted),
              ),
            ],
            if (message.recipeCards.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: message.recipeCards.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final card = message.recipeCards[index];
                    return _MiniRecipeCard(
                      card: card,
                      onOpen: () => onOpenRecipe(card),
                      onApply: () => onApplyRecipe(card),
                    );
                  },
                ),
              ),
            ],
            if (message.quickActions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.quickActions
                    .map(
                      (action) => MiniPill(text: _quickActionLabel(action)),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniRecipeCard extends StatelessWidget {
  const _MiniRecipeCard({
    required this.card,
    required this.onOpen,
    required this.onApply,
  });

  final ChatRecipeCard card;
  final VoidCallback onOpen;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F1EE),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(card.subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(card.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onOpen,
                    child: const Text('Aç'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onApply,
                    child: const Text('Ekle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.isSending,
    required this.onSubmitted,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.send,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              labelText: 'Nuri’ye sor',
              hintText: 'Bugün ne yemeliyim?',
              suffixIcon: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      onPressed: onSend,
                      icon: const Icon(Icons.send),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: NutriColors.leaf),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child:
          Text('$label $value', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

String _quickActionLabel(String action) {
  return switch (action) {
    'camera' => 'Fotoğraf',
    'voice' => 'Ses',
    'food-search' => 'Food search',
    _ => action,
  };
}
