.PHONY: model-build l10n-build clean install test

install:
	@echo 'Installing dependencies...'
	@sh ./scripts/install.sh
	@sh ./scripts/notify.sh "進度通知" "Flutter 模型和資源 安裝已完成"

l10n-build:
	@echo 'Building localization...'
	@fvm flutter pub get
	@sh ./scripts/notify.sh "進度通知" "Flutter 模型和資源 語系與套件編譯已完成"

model-build:
	@echo 'Building model...'
	@fvm dart run build_runner build --delete-conflicting-outputs
	@sh ./scripts/notify.sh "進度通知" "Flutter 模型和資源 構建已完成"

clean:
	@echo 'Cleaning project...'
	@sh ./scripts/clean.sh
	@sh ./scripts/notify.sh "進度通知" "Flutter 模型和資源 清理已完成"

test:
	@echo 'Running tests...'
	@fvm flutter test
	@sh ./scripts/notify.sh "進度通知" "Flutter 測試已完成"
