import 'package:app/di/dependency_injection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/boarding_pass/application/services/boarding_pass_application_service.dart';

part 'boarding_pass_provider.g.dart';

/// Provider that accesses Riverpod-managed boarding pass application service
@riverpod
BoardingPassApplicationService boardingPassApplicationServiceRef(Ref ref) {
  // Access the Riverpod provider instead of GetIt
  return ref.watch(boardingPassApplicationServiceProvider);
}
