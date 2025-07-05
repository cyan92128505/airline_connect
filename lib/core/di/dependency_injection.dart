import 'package:app/features/member/infrastructure/repositories/member_repository_impl.dart';
import 'package:app/features/member/repositories/member_repository.dart';
import 'package:app/features/member/services/member_auth_service.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global ObjectBox instance provider
/// Should be initialized in main() before app starts
final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

/// Repository providers using ObjectBox
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return MemberRepositoryImpl(objectBox);
});

/// Service providers
final memberAuthServiceProvider = Provider<MemberAuthService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return MemberAuthService(memberRepository);
});
