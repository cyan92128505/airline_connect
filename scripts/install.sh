
# Clean existing lock file
rm -rfv ./pubspec.lock

# Install all required packages
fvm flutter pub add \
  hooks_riverpod \
  flutter_hooks \
  riverpod_annotation \
  freezed_annotation \
  json_annotation \
  timezone \
  uuid \
  dartz \
  http \
  objectbox \
  objectbox_flutter_libs \
  shared_preferences \
  qr_code_scanner \
  qr_flutter \
  permission_handler \
  connectivity_plus \
  device_info_plus \
  package_info_plus \
  path_provider \
  crypto \
  logger \
  cached_network_image \
  go_router \
  flutter_secure_storage \
  intl \
  collection \
  meta \
  equatable \
  gap \
  flutter_screenutil \
  dev:riverpod_generator \
  dev:build_runner \
  dev:custom_lint \
  dev:riverpod_lint \
  dev:freezed \
  dev:json_serializable \
  dev:objectbox_generator \
  dev:mockito