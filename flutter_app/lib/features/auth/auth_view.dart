import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_scope.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets.dart';

class AuthFlowView extends StatefulWidget {
  const AuthFlowView({super.key});

  @override
  State<AuthFlowView> createState() => _AuthFlowViewState();
}

class _AuthFlowViewState extends State<AuthFlowView> {
  AuthPanel panel = AuthPanel.choice;

  void showPanel(AuthPanel next) {
    final state = AppScope.of(context);
    state.clearErrorMessage();
    setState(() => panel = next);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (panel) {
        AuthPanel.choice => _AuthChoiceScreen(
            onLogin: () => showPanel(AuthPanel.login),
            onRegister: () => showPanel(AuthPanel.register),
            onForgotPassword: () => showPanel(AuthPanel.forgotPassword),
          ),
        AuthPanel.login => _LoginScreen(
            key: const ValueKey('login'),
            state: state,
            onBack: () => showPanel(AuthPanel.choice),
          ),
        AuthPanel.register => _RegisterScreen(
            key: const ValueKey('register'),
            state: state,
            onBack: () => showPanel(AuthPanel.choice),
          ),
        AuthPanel.forgotPassword => _ForgotPasswordScreen(
            key: const ValueKey('forgot'),
            state: state,
            onBack: () => showPanel(AuthPanel.choice),
          ),
      },
    );
  }
}

class _AuthChoiceScreen extends StatelessWidget {
  const _AuthChoiceScreen({
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text('Hoş geldin', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Hesabına eriş, hedefini devam ettir ve onboarding tamamlandıktan sonra ana ekrana geç.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: onLogin,
              child: const SelectionTile(
                title: 'Giriş yap',
                subtitle: 'Mevcut hesabınla devam et',
                icon: Icons.login,
                selected: false,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onRegister,
              child: const SelectionTile(
                title: 'Hesap oluştur',
                subtitle: 'Yeni kullanıcı akışını başlat',
                icon: Icons.person_add_alt_1,
                selected: false,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onForgotPassword,
              child: const SelectionTile(
                title: 'Şifremi unuttum',
                subtitle: 'Reset e-postası al',
                icon: Icons.lock_reset,
                selected: false,
              ),
            ),
            const SizedBox(height: 24),
            const InlineMessage(
              text: 'Giriş ve kayıt Supabase Auth üzerinden çalışıyor. Token, uygulama yeniden açıldığında korunur.',
              icon: Icons.verified_user_outlined,
              backgroundColor: Color(0xFFE8F4EA),
              foregroundColor: NutriColors.leaf,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({
    super.key,
    required this.state,
    required this.onBack,
  });

  final AppState state;
  final VoidCallback onBack;

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final emailController = TextEditingController(text: 'umut@example.com');
  final passwordController = TextEditingController(text: '12345678');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text('Giriş yap', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Hesabın varsa e-posta ve şifreyle devam et.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onBack,
                child: const Text('Geri dön'),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              title: 'Giriş yap',
              icon: Icons.login,
              isBusy: state.isAuthenticating,
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      await state.signInWithEmail(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                    },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: state.isAuthenticating
                  ? null
                  : () {
                      widget.onBack();
                    },
              child: const Text('Hesap oluşturmaya geç'),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              InlineMessage(
                text: state.errorMessage!,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegisterScreen extends StatefulWidget {
  const _RegisterScreen({
    super.key,
    required this.state,
    required this.onBack,
  });

  final AppState state;
  final VoidCallback onBack;

  @override
  State<_RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<_RegisterScreen> {
  final emailController = TextEditingController(text: 'umut@example.com');
  final passwordController = TextEditingController(text: '12345678');
  final confirmPasswordController = TextEditingController(text: '12345678');

  String? localError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text('Hesap oluştur', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Onboarding bittikten sonra profilini backend’e kaydedeceğiz.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre tekrar'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onBack,
                child: const Text('Geri dön'),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              title: 'Hesap oluştur',
              icon: Icons.person_add_alt_1,
              isBusy: state.isAuthenticating,
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      final password = passwordController.text;
                      final confirmPassword = confirmPasswordController.text;
                      if (password != confirmPassword) {
                        setState(() => localError = 'Şifreler eşleşmiyor.');
                        return;
                      }

                      setState(() => localError = null);
                      await state.signUpWithEmail(
                        email: emailController.text,
                        password: password,
                      );
                    },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onBack,
              child: const Text('Zaten hesabım var'),
            ),
            if (localError != null) ...[
              const SizedBox(height: 12),
              InlineMessage(
                text: localError!,
                icon: Icons.warning_amber_rounded,
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              InlineMessage(
                text: state.errorMessage!,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen({
    super.key,
    required this.state,
    required this.onBack,
  });

  final AppState state;
  final VoidCallback onBack;

  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final emailController = TextEditingController(text: 'umut@example.com');
  bool sent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text('Şifre sıfırla', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'E-posta adresine sıfırlama bağlantısı göndereceğiz.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onBack,
                child: const Text('Geri dön'),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              title: 'Sıfırlama e-postası gönder',
              icon: Icons.mail_outline,
              isBusy: state.isAuthenticating,
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      await state.requestPasswordReset(email: emailController.text);
                      if (!mounted) return;
                      if (state.errorMessage == null) {
                        setState(() => sent = true);
                      }
                    },
            ),
            const SizedBox(height: 12),
            if (sent)
              const InlineMessage(
                text: 'Sıfırlama bağlantısı gönderildi. E-postanı kontrol et ve geri dönerek yeni şifreni belirle.',
                icon: Icons.check_circle_outline,
                backgroundColor: Color(0xFFE8F4EA),
                foregroundColor: NutriColors.leaf,
              ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              InlineMessage(
                text: state.errorMessage!,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? localError;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text('Yeni şifre oluştur', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Sıfırlama bağlantısıyla geldin. Yeni şifreni buradan belirle.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: NutriColors.muted),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni şifre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni şifre tekrar'),
            ),
            const SizedBox(height: 12),
            if (!state.isAuthenticated)
              const InlineMessage(
                text: 'Sıfırlama oturumu bulunamadı. E-postadaki linkle açtığından emin ol.',
                icon: Icons.info_outline,
                backgroundColor: Color(0xFFEAF0F7),
                foregroundColor: Color(0xFF3E5E7B),
              ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              InlineMessage(
                text: state.errorMessage!,
                icon: Icons.warning_amber_rounded,
              ),
            ],
            if (localError != null) ...[
              const SizedBox(height: 12),
              InlineMessage(
                text: localError!,
                icon: Icons.warning_amber_rounded,
              ),
            ],
            const SizedBox(height: 4),
            PrimaryButton(
              title: 'Yeni şifreyi kaydet',
              icon: Icons.lock_reset,
              isBusy: state.isAuthenticating,
              onPressed: state.isAuthenticating
                  ? null
                  : () async {
                      final password = passwordController.text;
                      final confirmPassword = confirmPasswordController.text;
                      if (password != confirmPassword) {
                        setState(() => localError = 'Şifreler eşleşmiyor.');
                        return;
                      }

                      setState(() => localError = null);
                      await state.updatePassword(password: password);
                    },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => state.showAuthFlow(),
              child: const Text('Giriş ekranına dön'),
            ),
          ],
        ),
      ),
    );
  }
}

enum AuthPanel { choice, login, register, forgotPassword }
