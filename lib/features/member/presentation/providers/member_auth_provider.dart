import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/member/application/services/member_application_service.dart';

part 'member_auth_provider.g.dart';

/// Provider that accesses Riverpod-managed member application service
/// This maintains the existing architecture
@riverpod
MemberApplicationService memberApplicationService(Ref ref) {
  // Access the Riverpod provider instead of GetIt
  return ref.watch(memberApplicationServiceProvider);
}
