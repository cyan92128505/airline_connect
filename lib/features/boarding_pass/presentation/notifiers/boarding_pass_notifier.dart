import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/presentation/providers/boarding_pass_provider.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';

part 'boarding_pass_notifier.freezed.dart';
part 'boarding_pass_notifier.g.dart';

/// State for boarding pass management
@freezed
abstract class BoardingPassState with _$BoardingPassState {
  const factory BoardingPassState({
    @Default(false) bool isLoading,
    @Default([]) List<BoardingPassDTO> boardingPasses,
    BoardingPassDTO? selectedPass,
    String? errorMessage,
    @Default(false) bool isOffline,
    @Default(false) bool isActivating,
    @Default(false) bool isScanning,
    QRCodeValidationResponseDTO? scanResult,
  }) = _BoardingPassState;

  const BoardingPassState._();

  /// Whether has any boarding passes
  bool get hasBoardingPasses => boardingPasses.isNotEmpty;

  /// Active boarding passes only
  List<BoardingPassDTO> get activePasses =>
      boardingPasses.where((pass) => pass.isActive == true).toList();

  /// Whether has active boarding passes
  bool get hasActivePasses => activePasses.isNotEmpty;

  /// Today's boarding passes
  List<BoardingPassDTO> get todayPasses {
    final today = DateTime.now();
    return boardingPasses.where((pass) {
      final departureTime = DateTime.parse(pass.scheduleSnapshot.departureTime);
      return departureTime.year == today.year &&
          departureTime.month == today.month &&
          departureTime.day == today.day;
    }).toList();
  }

  /// Whether has error
  bool get hasError => errorMessage != null;

  /// Next departure pass
  BoardingPassDTO? get nextDeparture {
    if (activePasses.isEmpty) return null;

    final now = DateTime.now();
    final futurePasses = activePasses.where((pass) {
      final departureTime = DateTime.parse(pass.scheduleSnapshot.departureTime);
      return departureTime.isAfter(now);
    }).toList();

    if (futurePasses.isEmpty) return null;

    futurePasses.sort((a, b) {
      final timeA = DateTime.parse(a.scheduleSnapshot.departureTime);
      final timeB = DateTime.parse(b.scheduleSnapshot.departureTime);
      return timeA.compareTo(timeB);
    });

    return futurePasses.first;
  }
}

/// Provider for BoardingPassNotifier
@riverpod
class BoardingPassNotifier extends _$BoardingPassNotifier {
  @override
  BoardingPassState build() {
    return const BoardingPassState();
  }

  /// Load boarding passes using Riverpod-managed application service
  Future<void> loadBoardingPasses() async {
    final memberAuthState = ref.read(memberAuthNotifierProvider);

    if (!memberAuthState.isAuthenticated || memberAuthState.member == null) {
      state = state.copyWith(errorMessage: '請先登入會員', boardingPasses: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Access Riverpod-managed service
      final boardingPassService = ref.read(
        boardingPassApplicationServiceRefProvider,
      );

      final result = await boardingPassService.getBoardingPassesForMember(
        memberAuthState.member!.memberNumber,
        activeOnly: false,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure.message),
          );
        },
        (passes) {
          state = state.copyWith(
            isLoading: false,
            boardingPasses: passes,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入登機證時發生錯誤');
    }
  }

  /// Activate boarding pass using Riverpod-managed application service
  Future<void> activateBoardingPass(String passId) async {
    state = state.copyWith(isActivating: true, errorMessage: null);

    try {
      final boardingPassService = ref.read(
        boardingPassApplicationServiceRefProvider,
      );
      final result = await boardingPassService.activateBoardingPass(passId);

      result.fold(
        (failure) {
          state = state.copyWith(
            isActivating: false,
            errorMessage: _mapFailureToMessage(failure.message),
          );
        },
        (response) {
          if (response.success && response.boardingPass != null) {
            final updatedPasses = state.boardingPasses.map((pass) {
              return pass.passId == passId ? response.boardingPass! : pass;
            }).toList();

            state = state.copyWith(
              isActivating: false,
              boardingPasses: updatedPasses,
              selectedPass: response.boardingPass,
              errorMessage: null,
            );
          } else {
            state = state.copyWith(
              isActivating: false,
              errorMessage: response.errorMessage ?? '啟用登機證失敗',
            );
          }
        },
      );
    } catch (e) {
      state = state.copyWith(isActivating: false, errorMessage: '啟用登機證時發生錯誤');
    }
  }

  void selectBoardingPass(BoardingPassDTO pass) {
    state = state.copyWith(selectedPass: pass);
  }

  void clearSelection() {
    state = state.copyWith(selectedPass: null);
  }

  Future<void> validateQRCode({
    required String encryptedPayload,
    required String checksum,
    required String generatedAt,
    required int version,
  }) async {
    state = state.copyWith(
      isScanning: true,
      scanResult: null,
      errorMessage: null,
    );

    try {
      final boardingPassService = ref.read(
        boardingPassApplicationServiceRefProvider,
      );
      final result = await boardingPassService.validateQRCode(
        encryptedPayload: encryptedPayload,
        checksum: checksum,
        generatedAt: generatedAt,
        version: version,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isScanning: false,
            errorMessage: _mapFailureToMessage(failure.message),
          );
        },
        (validationResult) {
          state = state.copyWith(
            isScanning: false,
            scanResult: validationResult,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'QR Code 驗證時發生錯誤',
      );
    }
  }

  void clearScanResult() {
    state = state.copyWith(scanResult: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void setOfflineStatus(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
  }

  Future<void> refresh() async {
    await loadBoardingPasses();
  }

  BoardingPassDTO? getBoardingPassById(String passId) {
    try {
      return state.boardingPasses.firstWhere((pass) => pass.passId == passId);
    } catch (e) {
      return null;
    }
  }

  String _mapFailureToMessage(String failureMessage) {
    final message = failureMessage.toLowerCase();

    if (message.contains('not found') || message.contains('不存在')) {
      return '找不到登機證';
    }

    if (message.contains('expired') || message.contains('已過期')) {
      return '登機證已過期';
    }

    if (message.contains('used') || message.contains('已使用')) {
      return '登機證已使用';
    }

    if (message.contains('invalid') || message.contains('無效')) {
      return '登機證資料無效';
    }

    if (message.contains('network') || message.contains('connection')) {
      return '網路連線異常，請檢查網路設定';
    }

    if (message.contains('timeout')) {
      return '連線逾時，請稍後再試';
    }

    return failureMessage;
  }
}
