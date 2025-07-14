import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/presentation/providers/member_auth_provider.dart';

part 'member_auth_notifier.freezed.dart';
part 'member_auth_notifier.g.dart';

/// State for member authentication
@freezed
abstract class MemberAuthState with _$MemberAuthState {
  const factory MemberAuthState({
    @Default(false) bool isLoading,
    @Default(false) bool isAuthenticated,
    MemberDTO? member,
    String? errorMessage,
    @Default(false) bool isOffline,
  }) = _MemberAuthState;

  const MemberAuthState._();

  /// Whether user is logged in with valid member data
  bool get hasValidMember => isAuthenticated && member != null;

  /// Whether there's an authentication error
  bool get hasError => errorMessage != null;

  /// Member display name for UI
  String get memberDisplayName => member?.fullName ?? '';

  /// Member tier display
  String get memberTierDisplay => member?.tier.displayName ?? '';
}

/// Provider for MemberAuthNotifier
@riverpod
class MemberAuthNotifier extends _$MemberAuthNotifier {
  @override
  MemberAuthState build() {
    return const MemberAuthState();
  }

  /// Authenticate member with credentials
  Future<void> authenticateMember({
    required String memberNumber,
    required String nameSuffix,
  }) async {
    if (memberNumber.trim().isEmpty || nameSuffix.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: '會員號碼和姓名後四碼不能為空',
        isAuthenticated: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final memberService = ref.read(memberApplicationServiceRefProvider);
      final result = await memberService.authenticateMember(
        memberNumber: memberNumber.trim(),
        nameSuffix: nameSuffix.trim(),
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            member: null,
            errorMessage: _mapFailureToMessage(failure.message),
          );
        },
        (response) {
          if (response.isAuthenticated && response.member != null) {
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: true,
              member: response.member,
              errorMessage: null,
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              isAuthenticated: false,
              member: null,
              errorMessage: response.errorMessage ?? '認證失敗',
            );
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        member: null,
        errorMessage: '網路連線異常，請稍後再試',
      );
    }
  }

  /// Logout member
  void logout() {
    state = const MemberAuthState(isAuthenticated: false, member: null);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Set offline status
  void setOfflineStatus(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  /// Refresh member profile
  Future<void> refreshMemberProfile() async {
    if (!state.isAuthenticated || state.member == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final memberService = ref.read(memberApplicationServiceRefProvider);
      final result = await memberService.getMemberProfile(
        state.member!.memberNumber,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: '無法更新會員資料: ${failure.message}',
          );
        },
        (updatedMember) {
          state = state.copyWith(
            isLoading: false,
            member: updatedMember,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '更新會員資料時發生錯誤');
    }
  }

  /// Map failure messages to user-friendly Chinese messages
  String _mapFailureToMessage(String failureMessage) {
    final message = failureMessage.toLowerCase();

    if (message.contains('not found') || message.contains('不存在')) {
      return '會員號碼或姓名後四碼錯誤';
    }

    if (message.contains('invalid') || message.contains('格式')) {
      return '會員號碼格式不正確';
    }

    if (message.contains('network') || message.contains('connection')) {
      return '網路連線異常，請檢查網路設定';
    }

    if (message.contains('timeout')) {
      return '連線逾時，請稍後再試';
    }

    return '登入失敗，請確認會員號碼和姓名後四碼';
  }
}
