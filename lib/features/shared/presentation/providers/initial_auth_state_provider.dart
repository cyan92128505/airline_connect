import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';

/// Provider for pre-initialized authentication state
/// This will be overridden in main.dart with the actual restored state
final initialAuthStateProvider = Provider<MemberAuthState>((ref) {
  throw UnimplementedError(
    'Initial auth state must be provided via override in main.dart',
  );
});
