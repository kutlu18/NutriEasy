import 'package:flutter/material.dart';
import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';

class NuriChatView extends StatefulWidget {
  const NuriChatView({super.key});

  @override
  State<NuriChatView> createState() => _NuriChatViewState();
}

class _NuriChatViewState extends State<NuriChatView> {
  final inputController = TextEditingController();

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuri')),
      body: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: state,
              builder: (context, _) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = state.chatMessages[index];
                    final align = message.role == ChatRole.user ? Alignment.centerRight : Alignment.centerLeft;
                    final color = message.role == ChatRole.user ? NutriColors.leaf : NutriColors.surface;
                    final textColor = message.role == ChatRole.user ? Colors.white : NutriColors.ink;
                    return Align(
                      alignment: align,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(message.text, style: TextStyle(color: textColor)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: const InputDecoration(labelText: 'Nuri’ye sor'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () {
                    state.sendChat(inputController.text);
                    inputController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: NutriColors.leaf,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
