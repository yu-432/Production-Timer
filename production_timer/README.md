# ProductionTimer

デスクワークを行う人の実稼働時間を記録し、その時間をグラフや累計で可視化することで、自己肯定感を高めるためのタイマーアプリです。

## 目次

- [概要](#概要)
- [主な機能](#主な機能)
- [技術スタック](#技術スタック)
- [環境要件](#環境要件)
- [プロジェクト構成](#プロジェクト構成)
- [セットアップ手順](#セットアップ手順)
- [アーキテクチャ](#アーキテクチャ)
- [開発ガイド](#開発ガイド)
- [仕様詳細](#仕様詳細)

---

## 概要

### コンセプト
作業時間の記録と可視化を通じて、デスクワーカーの日々の努力を見える化し、自己肯定感を高めます。

### ターゲットユーザー
- デスクワークを行うすべての人
- 自分の実稼働時間を把握したい人
- 作業記録をシンプルに管理したい人

---

## 主な機能

### 1. タイマー機能
- **開始/停止ボタン**: シンプルな2ボタン操作
- **秒単位計測**: 正確な時間トラッキング
- **リアルタイム表示**: 現在の経過時間を常時表示
- **Wake Lock**: タイマー実行中は画面スリープを防止

### 2. 自動停止機能
アプリからフォーカスが外れた場合(ホーム画面に戻る、別アプリを起動など)、タイマーを自動的に停止します。

**動作詳細:**
- ✅ **継続**: アプリ画面表示中
- ✅ **継続**: 画面をスリープさせた状態(Wake Lock有効)
- ❌ **停止**: ホーム画面に戻った時
- ❌ **停止**: 別のアプリを起動した時
- ❌ **停止**: アプリを完全終了した時

### 3. データ可視化
- **日次記録**: 1日の合計稼働時間を自動集計
- **週間グラフ**: 過去7日間の稼働時間を棒グラフで表示
- **月間グラフ**: 過去30日間の稼働時間を棒グラフで表示
- **累計表示**: これまでの総稼働時間を表示

### 4. 目標設定
- **週間目標**: 週の目標時間を設定(例: 40時間)
- **月間目標**: 月の目標時間を設定
- **達成度表示**: 目標に対する進捗をパーセンテージで表示

### 5. データ管理
- **ローカル保存**: すべてのデータはスマートフォン本体に保存
- **自動保存**: 定期的にタイマーデータを自動保存
- **アカウント不要**: サインアップやログイン不要

---

## 技術スタック

### フレームワーク
- **Flutter**: 3.35.4 (stable)
- **Dart**: 3.9.2

### 主要パッケージ

| パッケージ名 | バージョン | 用途 |
|------------|----------|------|
| `flutter_riverpod` | 最新 | 状態管理 |
| `hive` | 最新 | ローカルデータベース |
| `hive_flutter` | 最新 | HiveのFlutter統合 |
| `wakelock_plus` | 最新 | 画面スリープ防止 |
| `fl_chart` | 最新 | グラフ描画 |
| `intl` | 最新 | 日時フォーマット・国際化 |

### 選定理由

#### **Riverpod (状態管理)**
- Providerパターンのモダンな実装
- コンパイル時の型安全性
- テストが容易
- 公式ドキュメントが充実
- Flutterコミュニティで広く採用

#### **Hive (ローカルストレージ)**
- 高速な読み書き(SharedPreferencesの約10倍高速)
- NoSQL型でスキーマ変更が柔軟
- 型安全なデータアクセス
- 自動保存機能に最適
- iOSとAndroidで安定動作

#### **wakelock_plus (Wake Lock)**
- 画面スリープを制御
- iOS/Android両対応
- バッテリー消費を最小限に抑える実装
- `wakelock`パッケージの後継(より活発にメンテナンス)

#### **fl_chart (グラフ描画)**
- Flutterで最も人気のあるグラフライブラリ
- 棒グラフ、折れ線グラフなど多彩
- カスタマイズ性が高い
- アニメーション対応

#### **intl (国際化・日時処理)**
- Googleが提供する公式パッケージ
- 日時のフォーマット
- 週の開始日(日曜/月曜)の制御
- 多言語対応(将来の拡張性)

---

## 環境要件

### 開発環境
- Flutter 3.35.4以上
- Dart 3.9.2以上
- Android Studio / Xcode (iOS開発の場合)
- VS Code (推奨エディタ)

### サポートプラットフォーム
- **iOS**: 12.0以上
- **Android**: 6.0 (API Level 23) 以上

---

## プロジェクト構成

```
production_timer/
├── lib/
│   ├── main.dart                    # アプリのエントリーポイント
│   ├── models/                      # データモデル
│   │   ├── timer_record.dart        # タイマー記録のデータモデル
│   │   └── app_settings.dart        # アプリ設定のデータモデル
│   ├── providers/                   # Riverpodプロバイダー
│   │   ├── timer_provider.dart      # タイマー状態管理
│   │   ├── record_provider.dart     # 記録データ管理
│   │   └── settings_provider.dart   # 設定管理
│   ├── services/                    # ビジネスロジック
│   │   ├── storage_service.dart     # Hiveによるデータ保存
│   │   ├── timer_service.dart       # タイマーロジック
│   │   └── statistics_service.dart  # 統計計算
│   ├── screens/                     # 画面
│   │   ├── timer_screen.dart        # タイマー画面
│   │   ├── statistics_screen.dart   # 統計・グラフ画面
│   │   └── settings_screen.dart     # 設定画面
│   ├── widgets/                     # 再利用可能なウィジェット
│   │   ├── timer_display.dart       # タイマー表示
│   │   ├── weekly_chart.dart        # 週間グラフ
│   │   └── monthly_chart.dart       # 月間グラフ
│   └── utils/                       # ユーティリティ
│       ├── time_formatter.dart      # 時間フォーマット
│       └── date_helper.dart         # 日付計算
├── test/                            # テストコード
├── android/                         # Androidプロジェクト
├── ios/                             # iOSプロジェクト
└── pubspec.yaml                     # 依存関係定義
```

---

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd production_timer
```

### 2. 依存関係のインストール

```bash
flutter pub get
```

### 3. Hiveのコード生成(必要な場合)

```bash
flutter packages pub run build_runner build
```

### 4. アプリの実行

```bash
# デバイス/エミュレータを起動してから
flutter run
```

### 5. ビルド

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

---

## アーキテクチャ

### 状態管理パターン

このアプリは**Riverpod**を使用した状態管理を採用しています。

```
┌─────────────────┐
│   UI (Screens)  │  ← ユーザーインターフェース
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Providers     │  ← 状態管理(Riverpod)
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│    Services     │  ← ビジネスロジック
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  Local Storage  │  ← データ永続化(Hive)
└─────────────────┘
```

### データフロー

#### 1. タイマー開始
```
[UI] Start Button Pressed
  ↓
[TimerProvider] タイマー開始状態に変更
  ↓
[WakeLockService] Wake Lockを有効化
  ↓
[TimerService] 秒単位でカウントアップ開始
  ↓
[UI] リアルタイム表示を更新
```

#### 2. 自動保存
```
[TimerService] 30秒ごとにトリガー
  ↓
[StorageService] 現在の経過時間をHiveに保存
  ↓
[RecordProvider] 記録データを更新
```

#### 3. アプリフォーカス喪失
```
[AppLifecycleObserver] paused/inactive状態を検知
  ↓
[TimerProvider] タイマーを自動停止
  ↓
[StorageService] 最終データを保存
  ↓
[WakeLockService] Wake Lockを解除
```

### Wake Lock実装詳細

```dart
import 'package:wakelock_plus/wakelock_plus.dart';

class WakeLockService {
  // タイマー開始時
  Future<void> enable() async {
    await WakelockPlus.enable();
  }

  // タイマー停止時
  Future<void> disable() async {
    await WakelockPlus.disable();
  }
}
```

### AppLifecycle監視実装

```dart
class TimerScreen extends StatefulWidget with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリがバックグラウンドに移行
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // タイマーが実行中なら自動停止
      if (timerIsRunning) {
        stopTimer();
      }
    }
  }
}
```

---

## 開発ガイド

### 新しい機能を追加する手順

#### 1. モデルの作成
`lib/models/` に新しいデータモデルを作成

#### 2. プロバイダーの作成
`lib/providers/` に状態管理用のプロバイダーを作成

#### 3. サービスの実装
`lib/services/` にビジネスロジックを実装

#### 4. UIの実装
`lib/screens/` または `lib/widgets/` にUIコンポーネントを実装

#### 5. テストの作成
`test/` に対応するテストを作成

### コーディング規約

- **命名規則**: Dartの公式スタイルガイドに従う
  - クラス名: `PascalCase`
  - ファイル名: `snake_case.dart`
  - 変数名: `camelCase`

- **フォーマット**: `flutter format` を使用

- **Lint**: `flutter analyze` でコード品質をチェック

### デバッグ方法

#### タイマー動作の確認
```dart
print('Timer started: ${DateTime.now()}');
print('Elapsed seconds: $elapsedSeconds');
```

#### Wake Lock状態の確認
```dart
bool isEnabled = await WakelockPlus.enabled;
print('Wake Lock enabled: $isEnabled');
```

#### Hiveデータの確認
```dart
var box = await Hive.openBox('timer_records');
print('Saved records: ${box.values.toList()}');
```

---

## 仕様詳細

### タイマー仕様

#### 計測単位
- **最小単位**: 1秒
- **表示形式**: `HH:MM:SS` (例: 01:23:45)

#### タイマーの状態遷移

```
[停止中] ──Start──> [実行中] ──Stop──> [停止中]
                        │
                        │ (自動)
                        ↓
                [バックグラウンド移行]
                        │
                        ↓
                    [停止中]
```

#### 自動停止トリガー
- `AppLifecycleState.paused`: アプリがバックグラウンドに移行
- `AppLifecycleState.inactive`: アプリが非アクティブ(通知センター開くなど)
- `AppLifecycleState.detached`: アプリが終了

### データモデル

#### TimerRecord (タイマー記録)
```dart
class TimerRecord {
  String id;              // UUID
  DateTime date;          // 記録日
  int durationSeconds;    // 稼働時間(秒)
  DateTime startedAt;     // 開始時刻
  DateTime? endedAt;      // 終了時刻(null = 実行中)
}
```

#### AppSettings (アプリ設定)
```dart
class AppSettings {
  int weeklyGoalMinutes;   // 週間目標(分)
  int monthlyGoalMinutes;  // 月間目標(分)
  bool isDarkMode;         // ダークモード
}
```

### データ保存仕様

#### 保存タイミング
1. **定期保存**: タイマー実行中、30秒ごと
2. **停止時保存**: タイマー停止ボタン押下時
3. **自動停止時保存**: バックグラウンド移行時

#### 保存データ
- 日次の合計稼働時間
- タイマーのセッション情報(開始時刻、終了時刻)
- アプリ設定(目標時間など)

#### ストレージ容量見積もり
- 1日あたり: 約200バイト
- 1年分: 約73KB
- 10年分: 約730KB (1MB未満)

### グラフ仕様

#### 週間グラフ
- **表示期間**: 過去7日間(今日を含む)
- **週の開始**: 日曜日(Googleカレンダーと同じ)
- **グラフタイプ**: 棒グラフ
- **Y軸**: 稼働時間(時間単位)
- **X軸**: 曜日(日、月、火、水、木、金、土)

#### 月間グラフ
- **表示期間**: 過去30日間(今日を含む)
- **グラフタイプ**: 棒グラフ
- **Y軸**: 稼働時間(時間単位)
- **X軸**: 日付(1-30/31)

### 目標設定仕様

#### 週間目標
- デフォルト値: 40時間
- 設定範囲: 1時間 〜 168時間(1週間)
- 達成度計算: `(実績時間 / 目標時間) × 100`

#### 月間目標
- デフォルト値: 160時間
- 設定範囲: 1時間 〜 744時間(31日)
- 達成度計算: `(実績時間 / 目標時間) × 100`

### パフォーマンス要件

- **タイマー更新**: 毎秒(1000ms間隔)
- **自動保存**: 30秒間隔
- **グラフ描画**: 500ms以内
- **アプリ起動**: 2秒以内

### セキュリティ・プライバシー

- **データ保存先**: デバイスローカルのみ
- **ネットワーク通信**: なし
- **個人情報収集**: なし
- **広告表示**: なし
- **外部サービス連携**: なし

---

## トラブルシューティング

### Wake Lockが動作しない

#### iOS
`ios/Runner/Info.plist` に以下を追加:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

#### Android
`android/app/src/main/AndroidManifest.xml` に以下を追加:
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Hiveが開けない
```bash
# キャッシュをクリア
flutter clean
flutter pub get
```

### ビルドエラー
```bash
# 依存関係を再取得
rm pubspec.lock
flutter pub get
```

---

## 今後の拡張可能性

### Phase 2 (将来的な追加機能)
- 作業カテゴリー分類(プロジェクトA、会議など)
- データエクスポート(CSV形式)
- ウィジェット対応(ホーム画面にタイマー表示)
- 通知機能(目標達成時)

### Phase 3 (長期的な拡張)
- クラウド同期(オプション)
- 複数デバイス対応
- チーム機能
- レポート機能

---

## ライセンス

このプロジェクトは私的利用を目的としています。

---

## サポート・問い合わせ

プロジェクトに関する質問や不具合報告は、GitHubのIssueで受け付けています。

---

## 変更履歴

### v1.0.0 (未リリース)
- 初回リリース準備中
- 基本的なタイマー機能
- グラフ表示機能
- 目標設定機能
