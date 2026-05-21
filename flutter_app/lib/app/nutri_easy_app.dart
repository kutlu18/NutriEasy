import 'package:flutter/material.dart';
import '../core/config/app_config.dart';
import '../features/root/root_view.dart';
import '../shared/design_system.dart';
import 'app_scope.dart';
import 'app_state.dart';

class NutriEasyApp extends StatefulWidget {
  const NutriEasyApp({
    super.key,
    this.bootstrapOnStart = true,
  });

  final bool bootstrapOnStart;

  @override
  State<NutriEasyApp> createState() => _NutriEasyAppState();
}

class _NutriEasyAppState extends State<NutriEasyApp> {
  late final AppState state = AppState();

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapOnStart) {
      state.initialize();
    }
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConfig.appName,
        theme: NutriTheme.light(),
        home: RootView(autoBootstrapSplash: widget.bootstrapOnStart),
      ),
    );
  }
}
