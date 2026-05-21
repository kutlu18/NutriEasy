import 'package:flutter/material.dart';
import '../../app/app_scope.dart';
import '../../shared/design_system.dart';

class SplashView extends StatefulWidget {
  const SplashView({
    super.key,
    this.autoBootstrap = true,
  });

  final bool autoBootstrap;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  bool didBootstrap = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autoBootstrap) return;
    if (didBootstrap) return;
    didBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).bootstrapApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, size: 56, color: NutriColors.leaf),
            SizedBox(height: 16),
            Text('NutriEasy', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: NutriColors.ink)),
            SizedBox(height: 8),
            Text('Beslenme takibi, akıllı öğün girişi ve Nuri desteği.'),
            SizedBox(height: 16),
            CircularProgressIndicator(color: NutriColors.leaf),
          ],
        ),
      ),
    );
  }
}
