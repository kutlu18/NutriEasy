import 'package:flutter/material.dart';
import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: NutriColors.mint,
                    child: Icon(Icons.person, color: NutriColors.leaf),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.user.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(state.user.email, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Hedefler', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _RowItem(title: 'Hedef', value: state.user.selectedGoal.title),
              _RowItem(title: 'Aktivite', value: state.user.activityLevel.title),
              _RowItem(title: 'Öğün girişi', value: state.user.preferredLoggingMethod.title),
              const SizedBox(height: 16),
              Text('Ayarlar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _ActionItem(
                title: 'Bildirimler',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsView())),
              ),
              _ActionItem(
                title: 'Premium',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumView())),
              ),
              _ActionItem(
                title: 'Çıkış yap',
                onTap: () {
                  state.signOut();
                },
                trailing: const Icon(Icons.logout),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  bool mealReminder = true;
  bool waterReminder = true;
  bool dailySummary = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile.adaptive(
            title: const Text('Öğün hatırlatıcıları'),
            value: mealReminder,
            onChanged: (value) => setState(() => mealReminder = value),
          ),
          SwitchListTile.adaptive(
            title: const Text('Su hatırlatıcıları'),
            value: waterReminder,
            onChanged: (value) => setState(() => waterReminder = value),
          ),
          SwitchListTile.adaptive(
            title: const Text('Gün sonu özeti'),
            value: dailySummary,
            onChanged: (value) => setState(() => dailySummary = value),
          ),
        ],
      ),
    );
  }
}

class PremiumView extends StatelessWidget {
  const PremiumView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 56, color: NutriColors.amber),
              SizedBox(height: 16),
              Text('Premium ekranı mock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Ödeme entegrasyonu MVP dışında bırakıldı.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.title, required this.onTap, this.trailing});

  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
