
# Clean existing lock file
rm -rfv ./pubspec.lock

# Install all required packages
fvm flutter pub add \
  cached_network_image \
  collection \
  connectivity_plus \
  crypto \
  dartz \
  device_info_plus \
  equatable \
  flutter_hooks \
  flutter_riverpod \
  flutter_secure_storage \
  flutter_svg \
  freezed_annotation \
  gap \
  go_router \
  hooks_riverpod \
  http \
  injectable \
  intl \
  json_annotation \
  logger \
  mobile_scanner \
  objectbox \
  objectbox_flutter_libs \
  package_info_plus \
  path_provider \
  path \
  permission_handler \
  qr_flutter \
  riverpod_annotation \
  shared_preferences \
  timezone \
  uuid \
  dev:build_runner \
  dev:custom_lint \
  dev:freezed \
  dev:json_serializable \
  dev:mockito \
  dev:mocktail \
  dev:objectbox_generator \
  dev:riverpod_generator \
  dev:riverpod_lint \