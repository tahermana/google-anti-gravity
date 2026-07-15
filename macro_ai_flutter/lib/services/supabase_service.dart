import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_state.dart';

class SupabaseService {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const redirectUrl = 'macroai://login-callback';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;

  static User? get currentUser => client?.auth.currentUser;

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  static Future<void> signInWithGoogle() async {
    final supabase = client;
    if (supabase == null) {
      throw const SupabaseConfigException();
    }

    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : redirectUrl,
    );
  }

  static Future<void> signOut() async {
    await client?.auth.signOut();
  }

  static Future<AppState?> loadStateForCurrentUser() async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) return null;

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile == null) return null;

    final meals = await supabase
        .from('meals')
        .select()
        .eq('user_id', user.id)
        .order('logged_at');

    final weightEntries = await supabase
        .from('weight_entries')
        .select('weight_kg')
        .eq('user_id', user.id)
        .order('logged_on');

    final summaries = await supabase
        .from('daily_summaries')
        .select('calories')
        .eq('user_id', user.id)
        .order('summary_on')
        .limit(7);

    return AppState.fromSupabase(
      profile: Map<String, dynamic>.from(profile),
      meals: List<Map<String, dynamic>>.from(meals),
      weeklyCalories: List<Map<String, dynamic>>.from(summaries),
      weightEntries: List<Map<String, dynamic>>.from(weightEntries),
    );
  }

  static Future<void> saveProfile(AppState state) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) return;

    await supabase.from('profiles').upsert(state.toProfileRow(user.id));
  }

  static Future<void> saveMeal(Meal meal) async {
    final supabase = client;
    final user = currentUser;
    if (supabase == null || user == null) return;

    await supabase.from('meals').insert(meal.toSupabaseRow(user.id));
  }
}

class SupabaseConfigException implements Exception {
  const SupabaseConfigException();

  @override
  String toString() =>
      'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.';
}
