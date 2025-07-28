# AirlineConnect - 航空登機證管理系統

## 專案概述

AirlineConnect 是一個航空登機證管理系統，採用 Flutter 框架開發，實現跨平台的移動應用解決方案。系統提供會員認證、登機證管理、QR Code 掃描驗證等核心功能。

## 技術架構

- **前端框架**: Flutter 3.8.1+
- **狀態管理**: Riverpod + Hooks
- **本地資料庫**: ObjectBox
- **架構模式**: Clean Architecture + DDD (Domain-Driven Design)
- **測試策略**: Unit Testing + Integration Testing

## 系統需求

### 開發環境
- Flutter SDK: ^3.8.1
- Dart SDK: ^3.8.1
- Xcode 14+ (iOS 開發)
- Android Studio / VS Code

### 平台支援
- iOS 11.0+
- Android API 21+

## 快速開始

### 1. 環境準備

確保已安裝 Flutter SDK 並配置開發環境：

```bash
# Verify Flutter installation
flutter doctor -v

# Install FVM (Flutter Version Management) if not installed
dart pub global activate fvm

# Install project Flutter version
fvm install 3.8.1
fvm use 3.8.1 --force
```

### 2. 專案設置

```bash
# Clone repository
git clone <repository-url>
cd airline-connect

# Install dependencies and generate models
make install

# Alternative manual installation
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs

# Initialize ObjectBox database
fvm flutter run --debug  # First run to create DB structure
```

### 3. 執行應用程式

```bash
# Run on debug mode
fvm flutter run

# Run with specific device
fvm flutter run -d <device-id>

# Run with verbose logging
fvm flutter run --debug --verbose

# Build for testing
fvm flutter build apk --debug
fvm flutter build ios --debug
```

### 4. 測試執行

```bash
# Run all tests
make test

# Run unit tests only
fvm flutter test test/unit/

# Run integration tests
fvm flutter test test/integration/

# Run with coverage
fvm flutter test --coverage --test-randomize-ordering-seed random
```

## 開發指南

### 專案結構

```
lib/
├── core/                  # Core utilities and base classes
├── features/              # Feature modules
│   ├── boarding_pass/     # Boarding pass management
│   ├── flight/            # Flight information
│   ├── member/            # Member authentication & profile
│   └── shared/            # Shared components
test/                      # Test suites
├── unit/                  # Unit tests
├── integration/           # Integration tests
└── widget/                # Widget tests
```

### 開發工作流程

#### 1. 程式碼生成

當修改 DTO、Entity 或使用 Freezed/JsonSerializable 時：

```bash
# Generate all models and providers
make model-build

# Watch for changes (development)
fvm dart run build_runner watch --delete-conflicting-outputs
```

#### 2. 測試執行

```bash
# Run all tests
make test

# Run specific test suite
fvm flutter test test/unit/features/member/
fvm flutter test test/integration/

# Run with coverage
fvm flutter test --coverage
```


### 測試帳號

開發與測試期間可使用以下測試帳號：

| 項目       | 值         | 說明                     |
| ---------- | ---------- | ------------------------ |
| 會員號碼   | `AA123456` | 符合 2 字母 + 6 數字格式 |
| 姓名後四碼 | `Aoma`     | 用於會員身份驗證         |
| 會員等級   | 金級會員   | 具備完整功能權限         |
| 測試航班   | `BR857`    | 台北-東京航線            |
| 測試座位   | `12A`      | 靠窗座位                 |

## 業務邏輯說明

### Domain 驗證規則

基於 DDD 設計，系統實作了嚴格的業務規則：

#### 會員管理 (Member Domain)
```dart
// 會員號碼驗證: 必須為 2 字母 + 6 數字
MemberNumber.create("AA123456")  // ✓
MemberNumber.create("A123456")   // ✗ 格式錯誤

// 姓名驗證: 支援中英文，2-50 字元
FullName.create("王小明")         // ✓
FullName.create("John Smith")    // ✓
FullName.create("王")            // ✗ 太短

// 會員等級升級規則
member.upgradeTier(MemberTier.gold)    // Bronze -> Silver -> Gold
member.upgradeTier(MemberTier.bronze)  // ✗ 不可降級
```

#### 登機證管理 (Boarding Pass Domain)
```dart
// 登機證狀態轉換
boardingPass.activate()  // ISSUED -> ACTIVATED (起飛前24小時內)
boardingPass.use()       // ACTIVATED -> USED (登機時間內)
boardingPass.cancel()    // 任意狀態 -> CANCELLED (除 USED)

// 座位號碼驗證
SeatNumber.create("12A")   // ✓ 靠窗
SeatNumber.create("12C")   // ✓ 靠走道  
SeatNumber.create("12I")   // ✗ I 不是有效座位字母
```

#### 航班管理 (Flight Domain)
```dart
// 航班狀態轉換
flight.updateStatus(FlightStatus.boarding)   // SCHEDULED -> BOARDING
flight.updateStatus(FlightStatus.departed)   // BOARDING -> DEPARTED
flight.cancel()  // 只能取消未起飛的航班

// 時間驗證
FlightSchedule.create(
  departureTime: departure,
  boardingTime: departure.subtract(Duration(hours: 1)),  // 提前1小時登機
)
```

### QR Code 安全機制

系統實作多層安全驗證：

1. **資料加密**: Caesar cipher + Base64 編碼
2. **完整性檢查**: MD5 校驗碼
3. **時效性驗證**: 2 小時有效期
4. **唯一性保證**: UUID-based PassId

```dart
// QR Code 資料結構
{
  "passId": "BP1A2B3C4D",
  "flightNumber": "BR857", 
  "seatNumber": "12A",
  "memberNumber": "AA123456",
  "departureTime": "2025-07-29T14:30:00+08:00",
  "generatedAt": "2025-07-29T12:30:00+08:00"
}
```

### 會員認證模組 (Member Authentication)

- **路徑**: `lib/features/member/`
- **功能**: 會員登入、登出、個人資料管理
- **測試**: `test/unit/features/member/`

主要類別：
- `MemberAuthNotifier`: 會員認證狀態管理
- `MemberApplicationService`: 應用服務層
- `MemberAuthService`: 核心認證邏輯

### 登機證管理模組 (Boarding Pass)

- **路徑**: `lib/features/boarding_pass/`
- **功能**: 登機證CRUD、狀態管理、座位分配
- **測試**: `test/unit/features/boarding_pass/`

核心用例：
- `CreateBoardingPassUseCase`: 建立登機證
- `ActivateBoardingPassUseCase`: 啟動登機證
- `ValidateBoardingEligibilityUseCase`: 驗證登機資格

### QR Code 掃描模組

- **路徑**: `lib/features/boarding_pass/presentation/screens/qr_scanner_screen.dart`
- **功能**: QR Code 掃描、驗證、結果顯示
- **相機權限**: 自動請求相機存取權限

## 資料架構

### 資料庫設計

使用 ObjectBox 作為本地資料庫，主要實體包括：

#### Member Entity
- **會員號碼格式**: 2 字母 + 6 數字 (如: AA123456, BR789012)
- **會員等級**: BRONZE、SILVER、GOLD、SUSPENDED
- **驗證機制**: 姓名後四碼驗證

#### Boarding Pass Entity
- **登機證 ID**: BP + 8 位英數字 (如: BP1A2B3C4D)
- **狀態流程**: ISSUED → ACTIVATED → USED
- **QR Code**: 包含加密負載、校驗碼、時間戳
- **有效期限**: 生成後 2 小時內有效

#### Flight Entity
- **航班號碼**: 2-3 字母 + 3-4 數字 (如: BR857, CI101)
- **機場代碼**: 3 字母 IATA 格式 (如: TPE, NRT, LAX)
- **座位格式**: 1-999 + A-L (如: 1A, 12B, 45F)

```dart
// Boarding Pass 狀態轉換範例
@Entity()
class BoardingPassEntity {
  @Id() int id = 0;
  String passId;           // BP1A2B3C4D
  String memberNumber;     // AA123456
  String flightNumber;     // BR857
  String status;           // ISSUED/ACTIVATED/USED
  String qrEncryptedData;  // 加密的 QR 資料
  DateTime issueTime;
  DateTime? activatedAt;
}
```

### 狀態管理

採用 Riverpod 進行狀態管理：

```dart
// Provider example
final memberAuthNotifierProvider = 
    StateNotifierProvider<MemberAuthNotifier, MemberAuthState>((ref) {
  return MemberAuthNotifier(
    ref.watch(memberApplicationServiceProvider),
    ref.watch(initialAuthStateProvider),
  );
});
```