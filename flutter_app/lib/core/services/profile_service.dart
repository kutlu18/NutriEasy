import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';

class ProfileService {
  SupabaseClient get client => Supabase.instance.client;

  Future<UserProfile?> loadProfile({
    required String userId,
    String email = '',
  }) async {
    final row = await client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row is Map<String, dynamic>) {
      return UserProfile.fromSupabase(row, email: email);
    }

    return null;
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final row = await client
        .from('user_profiles')
        .upsert(
          profile.toSupabaseMap(),
          onConflict: 'id',
        )
        .select()
        .maybeSingle();

    if (row is Map<String, dynamic>) {
      return UserProfile.fromSupabase(row, email: profile.email);
    }

    return profile;
  }
}
