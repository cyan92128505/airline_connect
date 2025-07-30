# GitHub Secrets 設定手冊

## 概述

本手冊說明 Flutter App CI/CD 所需的 GitHub Secrets 設定步驟。這些設定用於自動化 iOS 和 Android 應用程式的建置、簽署和部署流程。

## 必要 Secrets 清單

### iOS 部署相關
- `BUILD_CERTIFICATE_BASE64` - iOS 建置憑證
- `P12_PASSWORD` - P12 憑證密碼
- `BUILD_PROVISION_PROFILE_BASE64` - iOS 配置檔案
- `KEYCHAIN_PASSWORD` - 鑰匙圈密碼
- `APPLE_ID_EMAIL` - Apple ID 電子郵件
- `APPLE_ID_APP_PASSWORD` - App-specific 密碼

### Android 部署相關
- `RELEASE_KEY_PROPERTIES` - Android 簽署配置
- `RELEASE_KEYSTORE` - Android Keystore 檔案

---

## iOS Secrets 設定

### BUILD_CERTIFICATE_BASE64

**用途**: iOS 應用程式簽署憑證

**取得步驟**:
1. 開啟 Keychain Access (鑰匙圈存取)
2. 在左側選擇 login 鑰匙圈
3. 找到您的 iOS 開發/發布憑證 (例如: "iPhone Distribution: Your Company Name")
4. 右鍵點擊憑證，選擇 Export "Your Certificate"
5. 選擇格式: Personal Information Exchange (.p12)
6. 設定密碼並儲存為 certificate.p12
7. 轉換為 Base64:
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```
8. 將結果貼到 GitHub Secret

**驗證方法**:
```bash
security find-identity -v -p codesigning
```

### P12_PASSWORD

**用途**: 上述 P12 憑證的密碼

**設定**: 直接輸入您在匯出 P12 檔案時設定的密碼。建議使用強密碼，包含大小寫字母、數字和符號。

### BUILD_PROVISION_PROFILE_BASE64

**用途**: iOS 應用程式配置檔案

**取得步驟**:
1. 登入 Apple Developer Portal (https://developer.apple.com/)
2. 前往 Certificates, Identifiers & Profiles
3. 選擇 Profiles → Distribution
4. 找到您的 App Store 或 Ad Hoc 配置檔案
5. 點擊 Download 下載 .mobileprovision 檔案
6. 轉換為 Base64:
   ```bash
   base64 -i YourApp.mobileprovision | pbcopy
   ```
7. 將結果貼到 GitHub Secret

**注意事項**:
- 確保配置檔案包含正確的 App ID
- 確保配置檔案未過期
- 配置檔案必須包含建置憑證

### KEYCHAIN_PASSWORD

**用途**: CI 環境中臨時鑰匙圈的密碼

**設定**: 可以設定任意強密碼，例如 SecurePass123!@#。此密碼僅在 CI 過程中使用，不影響您的本地開發。

### APPLE_ID_EMAIL

**用途**: 上傳到 TestFlight 的 Apple ID

**設定**: 輸入您的 Apple Developer 帳號電子郵件，必須是有權限上傳到 App Store Connect 的帳號。

### APPLE_ID_APP_PASSWORD

**用途**: App-specific 密碼用於 TestFlight 上傳

**取得步驟**:
1. 前往 Apple ID 管理頁面 (https://appleid.apple.com/)
2. 登入您的 Apple ID
3. 在 Security 區段找到 App-Specific Passwords
4. 點擊 Generate an app-specific password
5. 輸入標籤 (例如: "GitHub Actions CI")
6. 複製生成的密碼 (格式類似: abcd-efgh-ijkl-mnop)
7. 將密碼貼到 GitHub Secret

**重要**: 如果您的 Apple ID 啟用了雙重認證，必須使用 App-specific 密碼。密碼只會顯示一次，請立即複製保存。

---

## Android Secrets 設定

### RELEASE_KEY_PROPERTIES

**用途**: Android 簽署配置檔案

**建立步驟**:
1. 建立 key.properties 檔案:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=your_key_alias
   storeFile=key.jks
   ```

2. 轉換為 Base64:
   ```bash
   base64 -i key.properties | pbcopy
   ```

3. 將結果貼到 GitHub Secret

**範例內容**:
```properties
storePassword=MySecureStorePass123
keyPassword=MySecureKeyPass123
keyAlias=aoma-app
storeFile=key.jks
```

### RELEASE_KEYSTORE

**用途**: Android 簽署用的 Keystore 檔案

**建立新 Keystore** (如果還沒有):
```bash
keytool -genkey -v -keystore key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aoma-app
```

**轉換現有 Keystore**:
```bash
base64 -i key.jks | pbcopy
```

**重要提醒**:
- Keystore 是發布 Android 應用程式的唯一憑證
- 請務必備份原始 Keystore 檔案
- 遺失 Keystore 將無法更新已發布的應用程式

---

## 設定 GitHub Secrets

### 步驟 1: 前往 Repository Settings
1. 在 GitHub Repository 中點擊 Settings
2. 在左側選單選擇 Secrets and variables → Actions

### 步驟 2: 新增 Secrets
1. 點擊 New repository secret
2. 輸入 Secret 名稱 (必須完全符合上述清單)
3. 貼上對應的值
4. 點擊 Add secret

### 步驟 3: 驗證設定
確保所有 8 個 Secrets 都已正確設定:

| Secret 名稱                    | 用途             |
| ------------------------------ | ---------------- |
| BUILD_CERTIFICATE_BASE64       | iOS 憑證         |
| P12_PASSWORD                   | iOS 憑證密碼     |
| BUILD_PROVISION_PROFILE_BASE64 | iOS 配置檔案     |
| KEYCHAIN_PASSWORD              | 鑰匙圈密碼       |
| APPLE_ID_EMAIL                 | Apple ID         |
| APPLE_ID_APP_PASSWORD          | App 專用密碼     |
| RELEASE_KEY_PROPERTIES         | Android 配置     |
| RELEASE_KEYSTORE               | Android Keystore |

---

## 安全性注意事項

### 密碼安全
- 使用強密碼 (至少 12 字符，包含大小寫、數字、符號)
- 不要在程式碼或其他地方暴露密碼
- 定期更新 App-specific 密碼

### 憑證管理
- 定期檢查憑證過期日期
- 備份所有憑證和 Keystore 檔案
- 使用 Apple Developer 企業帳號時，確保權限正確設定

### GitHub Secrets
- 只有必要的人員才能存取 Repository Settings
- 定期檢查 Secrets 的使用情況
- 不要在日誌中輸出 Secret 內容

---

## 常見問題排除

### iOS 相關問題

**問題**: security: SecKeychainSearchCopyNext: The specified item could not be found in the keychain.

**解決方法**: 
- 檢查 BUILD_CERTIFICATE_BASE64 是否正確
- 確認 P12_PASSWORD 是否正確
- 驗證憑證是否包含私鑰

**問題**: No profiles for 'com.yourapp.bundle' were found

**解決方法**:
- 檢查 BUILD_PROVISION_PROFILE_BASE64 是否正確
- 確認 Bundle ID 是否匹配
- 檢查配置檔案是否過期

### Android 相關問題

**問題**: Keystore file not found

**解決方法**:
- 檢查 RELEASE_KEYSTORE Base64 編碼是否正確
- 確認 key.properties 中的 storeFile 路徑

**問題**: Wrong password for keystore

**解決方法**:
- 檢查 RELEASE_KEY_PROPERTIES 中的密碼設定
- 確認 storePassword 和 keyPassword 是否正確

---

## 檢核清單

設定完成後，請確認以下項目:

### iOS 檢核
- [ ] BUILD_CERTIFICATE_BASE64 已設定
- [ ] P12_PASSWORD 已設定  
- [ ] BUILD_PROVISION_PROFILE_BASE64 已設定
- [ ] KEYCHAIN_PASSWORD 已設定
- [ ] APPLE_ID_EMAIL 已設定
- [ ] APPLE_ID_APP_PASSWORD 已設定
- [ ] iOS 憑證未過期
- [ ] 配置檔案未過期

### Android 檢核
- [ ] RELEASE_KEY_PROPERTIES 已設定
- [ ] RELEASE_KEYSTORE 已設定
- [ ] Keystore 密碼正確
- [ ] Key alias 正確

### GitHub 檢核
- [ ] 所有 8 個 Secrets 已在 GitHub 設定
- [ ] Secret 名稱完全正確 (區分大小寫)
- [ ] 有權限的人員已確認設定

---

## 後續步驟

完成 Secrets 設定後:

1. **測試 CI/CD Pipeline**:
   ```bash
   git push origin main
   ```

2. **監控 GitHub Actions**:
   - 前往 Repository → Actions
   - 檢查 workflow 執行狀況

3. **手動觸發部署**:
   - 前往 Actions → 選擇對應的 workflow
   - 點擊 "Run workflow"

4. **驗證部署結果**:
   - iOS: 檢查 TestFlight
   - Android: 檢查 GitHub Releases

---

**重要提醒**: 所有憑證和密碼都是敏感資訊，請妥善保管。遺失或洩露可能導致安全風險或無法更新應用程式。