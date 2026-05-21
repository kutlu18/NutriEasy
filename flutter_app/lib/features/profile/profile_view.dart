import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/models.dart';
import '../../shared/design_system.dart';
import '../fasting/fasting_view.dart';
import '../premium/premium_view.dart' as premium;

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
          final preferences = state.notificationPreferences;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileHeader(user: state.user),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Hesap'),
              const SizedBox(height: 10),
              _ActionItem(
                title: 'Hesap ayarları',
                subtitle: 'İsim, boy, kilo ve hedef bilgilerini düzenle',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AccountSettingsView()),
                ),
              ),
              _RowItem(title: 'Hedef', value: state.user.selectedGoal.title),
              _RowItem(
                  title: 'Aktivite', value: state.user.activityLevel.title),
              _RowItem(
                  title: 'Öğün girişi',
                  value: state.user.preferredLoggingMethod.title),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Hatırlatmalar'),
              const SizedBox(height: 10),
              _StatusCard(
                title: 'Bildirim durumu',
                subtitle: preferences.permissionGranted
                    ? 'Bildirim izni verilmiş.'
                    : 'Bildirim izni henüz verilmedi.',
                trailing: preferences.permissionGranted
                    ? const Icon(Icons.notifications_active_outlined,
                        color: NutriColors.leaf)
                    : const Icon(Icons.notifications_off_outlined,
                        color: NutriColors.coral),
              ),
              const SizedBox(height: 10),
              _RowItem(
                title: 'Su hatırlatma',
                value: preferences.waterReminders ? 'Açık' : 'Kapalı',
              ),
              _RowItem(
                title: 'Öğün hatırlatma',
                value: preferences.mealReminders ? 'Açık' : 'Kapalı',
              ),
              _RowItem(
                title: 'Fasting başlangıç / bitiş',
                value: preferences.fastingNotifications ? 'Açık' : 'Kapalı',
              ),
              _RowItem(
                title: 'Günlük özet',
                value: preferences.dailySummary ? 'Açık' : 'Kapalı',
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Ayarlar'),
              const SizedBox(height: 10),
              _ActionItem(
                title: 'Hesap ayarları',
                subtitle: 'İsim, boy, kilo, hedef ve logging tercihleri',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AccountSettingsView()),
                ),
              ),
              _ActionItem(
                title: 'Bildirimler',
                subtitle: 'Hatırlatma tercihlerini ve izin durumunu yönet',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const NotificationSettingsView()),
                ),
              ),
              _ActionItem(
                title: 'Premium',
                subtitle: 'Gelecek ödeme katmanı için mock alan',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const premium.PremiumView()),
                ),
              ),
              _ActionItem(
                title: 'Fasting',
                subtitle: 'Oruç planını ve geçmişini gör',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FastingView()),
                ),
              ),
              const SizedBox(height: 8),
              _ActionItem(
                title: 'Çıkış yap',
                subtitle: 'Oturumu kapat ve giriş ekranına dön',
                onTap: () async {
                  final confirmed = await _confirmLogout(context);
                  if (confirmed != true || !context.mounted) return;
                  await state.signOut();
                },
                trailing: const Icon(Icons.logout, color: NutriColors.coral),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Çıkış yap'),
          content:
              const Text('Bu cihazda oturumu kapatmak istediğine emin misin?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Çıkış yap'),
            ),
          ],
        );
      },
    );
  }
}

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _targetWeightController;
  late Goal _goal;
  late ActivityLevel _activityLevel;
  late LoggingMethod _loggingMethod;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final state = AppScope.of(context);
    _nameController = TextEditingController(text: state.user.name);
    _ageController = TextEditingController(text: state.user.age.toString());
    _heightController =
        TextEditingController(text: state.user.heightCm.toString());
    _weightController =
        TextEditingController(text: state.user.weightKg.toString());
    _targetWeightController = TextEditingController(
        text: state.user.targetWeightKg?.toString() ?? '');
    _goal = state.user.selectedGoal;
    _activityLevel = state.user.activityLevel;
    _loggingMethod = state.user.preferredLoggingMethod;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap ayarları')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionTitle(title: 'Profil bilgileri'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'İsim'),
              validator: (value) =>
                  value == null || value.trim().length < 2 ? 'İsim gir' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yaş'),
              validator: _positiveIntValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Boy (cm)'),
              validator: _positiveIntValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilo (kg)'),
              validator: _positiveIntValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetWeightController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Hedef kilo (opsiyonel)'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return int.tryParse(value.trim()) == null
                    ? 'Geçerli bir sayı gir'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Goal>(
              value: _goal,
              decoration: const InputDecoration(labelText: 'Hedef'),
              items: Goal.values
                  .map((goal) =>
                      DropdownMenuItem(value: goal, child: Text(goal.title)))
                  .toList(),
              onChanged: (value) => setState(() => _goal = value ?? _goal),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityLevel>(
              value: _activityLevel,
              decoration: const InputDecoration(labelText: 'Aktivite seviyesi'),
              items: ActivityLevel.values
                  .map((level) =>
                      DropdownMenuItem(value: level, child: Text(level.title)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _activityLevel = value ?? _activityLevel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LoggingMethod>(
              value: _loggingMethod,
              decoration:
                  const InputDecoration(labelText: 'Öğün girişi tercihi'),
              items: LoggingMethod.values
                  .map((method) => DropdownMenuItem(
                      value: method, child: Text(method.title)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _loggingMethod = value ?? _loggingMethod),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;

                      setState(() => _saving = true);
                      final updated = state.user.copyWith(
                        name: _nameController.text.trim(),
                        age: int.parse(_ageController.text.trim()),
                        heightCm: int.parse(_heightController.text.trim()),
                        weightKg: int.parse(_weightController.text.trim()),
                        targetWeightKg: _targetWeightController.text
                                .trim()
                                .isEmpty
                            ? null
                            : int.parse(_targetWeightController.text.trim()),
                        selectedGoal: _goal,
                        activityLevel: _activityLevel,
                        preferredLoggingMethod: _loggingMethod,
                      );

                      await state.saveAccountSettings(updated);
                      if (!context.mounted) return;
                      setState(() => _saving = false);
                      Navigator.of(context).pop();
                    },
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  String? _positiveIntValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Geçerli bir sayı gir';
    }
    return null;
  }
}

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  late NotificationPreferences _preferences;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _preferences = AppScope.of(context).notificationPreferences;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StatusCard(
            title: 'İzin durumu',
            subtitle: _preferences.permissionGranted
                ? 'Cihaz bildirimi izni verilmiş.'
                : 'İzin verilmedi, hatırlatmalar mock modda tutuluyor.',
            trailing: FilledButton(
              onPressed: _preferences.permissionGranted
                  ? null
                  : () async {
                      await state.requestNotificationPermission();
                      setState(() {
                        _preferences = state.notificationPreferences;
                      });
                    },
              child:
                  Text(_preferences.permissionGranted ? 'Verildi' : 'İzin ver'),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            title: const Text('Su hatırlatma'),
            subtitle: const Text('Gün içinde su içmeyi hatırlat'),
            value: _preferences.waterReminders,
            onChanged: (value) => setState(() =>
                _preferences = _preferences.copyWith(waterReminders: value)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Öğün hatırlatma'),
            subtitle: const Text('Kayıt zamanı yaklaşınca uyar'),
            value: _preferences.mealReminders,
            onChanged: (value) => setState(() =>
                _preferences = _preferences.copyWith(mealReminders: value)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Fasting başlangıç / bitiş'),
            subtitle: const Text('Oruç penceresini hatırlat'),
            value: _preferences.fastingNotifications,
            onChanged: (value) => setState(() => _preferences =
                _preferences.copyWith(fastingNotifications: value)),
          ),
          SwitchListTile.adaptive(
            title: const Text('Günlük özet'),
            subtitle: const Text('Günün sonunda kısa özet gönder'),
            value: _preferences.dailySummary,
            onChanged: (value) => setState(() =>
                _preferences = _preferences.copyWith(dailySummary: value)),
          ),
          const SizedBox(height: 16),
          _StatusCard(
            title: 'Push hedefleri',
            subtitle:
                'MVP aşamasında sistem bildirimi entegrasyonu yok, ama tercihlerin hazır tutuluyor.',
            trailing: const Icon(Icons.notifications_active_outlined,
                color: NutriColors.leaf),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await state.updateNotificationPreferences(_preferences);
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    Navigator.of(context).pop();
                  },
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Kaydediliyor...' : 'Tercihleri kaydet'),
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
              Text('Premium ekranı mock',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Ödeme entegrasyonu MVP dışında bırakıldı.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: NutriColors.mint,
            child: Icon(Icons.person, color: NutriColors.leaf),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill(text: user.selectedGoal.title),
                    _MiniPill(text: user.activityLevel.title),
                    _MiniPill(text: user.preferredLoggingMethod.title),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD0EBD6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: NutriColors.leaf, fontWeight: FontWeight.w700),
      ),
    );
  }
}
