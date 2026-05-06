import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../supabase/supabase_config.dart';

String? firstSignedInUserId({
  String? authProviderUserId,
  String? supabaseUserId,
}) {
  final providerUserId = authProviderUserId?.trim() ?? '';
  if (providerUserId.isNotEmpty) return providerUserId;

  final fallbackUserId = supabaseUserId?.trim() ?? '';
  if (fallbackUserId.isNotEmpty) return fallbackUserId;

  return null;
}

String? resolveSignedInUserId(BuildContext context) {
  String? authProviderUserId;
  try {
    authProviderUserId = context.read<AuthProvider?>()?.user?.id;
  } catch (_) {
    // Isolated widget tests may not provide AuthProvider.
  }

  String? supabaseUserId;
  try {
    supabaseUserId = SupabaseConfig.client.auth.currentUser?.id;
  } catch (_) {
    // Supabase may not be initialized in tests or before bootstrap completes.
  }

  return firstSignedInUserId(
    authProviderUserId: authProviderUserId,
    supabaseUserId: supabaseUserId,
  );
}
