import 'package:supabase_flutter/supabase_flutter.dart';

class AppErrorParser {
  static String message(Object error) {
    if (error is AuthException) {
      return error.message;
    }

    if (error is AuthSessionMissingException) {
      return 'Oturum bulunamadi. Lutfen yeniden giris yap.';
    }

    if (error is PostgrestException) {
      return error.message;
    }

    return error.toString();
  }
}
