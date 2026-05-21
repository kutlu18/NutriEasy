import 'package:flutter/foundation.dart';

class AppAnalytics {
  AppAnalytics._();

  static final AppAnalytics instance = AppAnalytics._();
  final List<String> _recentEvents = [];

  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    if (!kDebugMode) return;

    final payload = parameters.isEmpty ? name : '$name ${parameters.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}';
    _recentEvents.add(payload);
    debugPrint('[analytics] $payload');
  }

  void logScreen(String screenName, {String? routeName}) {
    logEvent(
      'screen_view',
      parameters: {
        'screen': screenName,
        if (routeName != null) 'route': routeName,
      },
    );
  }

  List<String> get recentEvents => List.unmodifiable(_recentEvents);
}
