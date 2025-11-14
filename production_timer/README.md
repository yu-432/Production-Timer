# 実稼働タイマー (Production Timer)

実際にアプリを開いている時間だけを計測する、シンプルな稼働時間記録アプリケーションです。

## 概要

このアプリは、アプリを開いている間だけタイマーが動作し、実際の稼働時間を正確に記録します。
作業時間の可視化や、実際の活動時間を把握するのに最適なツールです。

### 主な特徴

- **正確な稼働時間計測**: アプリを開いている時間だけをカウント
- **シンプルなUI**: タイマー表示と操作のみに集中したデザイン
- **共有機能**: リンクをコピーして、あなたのユーザー名と当日の稼働時間を共有
- **ローカル動作**: 各スマートフォンで独立して動作

## 技術スタック

- **フレームワーク**: Flutter 3.9.2+
- **言語**: Dart
- **対応プラットフォーム**: iOS, Android, Web, macOS, Windows, Linux
- **状態管理**: Flutter標準のStatefulWidget(初期実装)

## 現在の機能

### ✅ 実装済み

現在、プロジェクトはFlutterの初期テンプレート状態です。これから以下の機能を実装していきます。

### 🚧 実装予定(Phase 1 - 基本機能)

1. **タイマー機能**
   - アプリを開いている時間を自動計測
   - バックグラウンドに移行すると自動停止
   - フォアグラウンドに戻ると自動再開

2. **共有機能**
   - リンクコピーボタン
   - ユーザー名と当日の稼働時間を共有

3. **データ保存**
   - ローカルストレージに稼働時間を保存
   - アプリを再起動しても累積時間を保持

### 🔮 将来的な拡張(Phase 2)

- **グループ機能**: 知り合いとグループを作成して稼働時間を共有
- **リアルタイム同期**: グループメンバーの稼働状況をリアルタイムで確認
- **統計・レポート**: 週次・月次の稼働時間レポート
- **バックエンド統合**: Firebase/Supabaseを使用したデータ同期

## セットアップ手順

このプロジェクトに初めて参加する方向けの手順です。

### 前提条件

- Flutter SDK 3.9.2以上がインストールされていること
- お好みのIDE(VS Code, Android Studio, IntelliJ IDEAなど)
- iOS開発の場合: Xcode
- Android開発の場合: Android Studio

### インストール

1. **リポジトリのクローン**
   ```bash
   git clone [リポジトリURL]
   cd production_timer
   ```

2. **依存関係のインストール**
   ```bash
   cd production_timer
   flutter pub get
   ```

3. **動作確認**
   ```bash
   # 利用可能なデバイスを確認
   flutter devices

   # アプリを起動(デバイスを選択してください)
   flutter run
   ```

### ディレクトリ構成

```
production_timer/
├── lib/                    # Dartソースコード
│   └── main.dart          # アプリのエントリーポイント
├── android/               # Android固有の設定
├── ios/                   # iOS固有の設定
├── web/                   # Web固有の設定
├── macos/                 # macOS固有の設定
├── windows/               # Windows固有の設定
├── linux/                 # Linux固有の設定
├── test/                  # テストコード
├── pubspec.yaml           # 依存関係とプロジェクト設定
└── README.md              # このファイル
```

## 開発ガイド

### 開発の流れ

1. **ブランチを作成**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **コードを書く**
   - `lib/`ディレクトリ内で開発
   - ホットリロード機能を活用: `r`キーで即座に変更を反映

3. **動作確認**
   ```bash
   flutter run
   ```

4. **コードの品質チェック**
   ```bash
   # コードの静的解析
   flutter analyze

   # フォーマット
   flutter format .
   ```

5. **テスト実行**
   ```bash
   flutter test
   ```

### よく使うコマンド

```bash
# ホットリロード(アプリ起動中)
r

# ホットリスタート(アプリ起動中)
R

# デバッグコンソールを開く(アプリ起動中)
d

# 依存関係の更新
flutter pub upgrade

# ビルド(各プラットフォーム)
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

## トラブルシューティング

### よくある問題と解決方法

1. **`flutter pub get`が失敗する**
   - ネットワーク接続を確認
   - `flutter clean`を実行後、再度`flutter pub get`

2. **iOS/Androidエミュレータが起動しない**
   - Xcode/Android Studioが正しくインストールされているか確認
   - `flutter doctor`で環境をチェック

3. **ホットリロードが効かない**
   - ホットリスタート(`R`)を試す
   - それでも直らない場合はアプリを再起動

## コントリビューション

このプロジェクトに貢献していただける方へ:

1. 機能追加やバグ修正は新しいブランチで作業
2. コードは`flutter analyze`でエラーが出ないことを確認
3. コミットメッセージは英語で10単語以内
4. プルリクエストを作成

## ライセンス

このプロジェクトはプライベートプロジェクトです(`publish_to: 'none'`)。

## 参考リンク

- [Flutter公式ドキュメント](https://docs.flutter.dev/)
- [Dart言語ツアー](https://dart.dev/guides/language/language-tour)
- [Flutter Widget カタログ](https://docs.flutter.dev/ui/widgets)

---

**プロジェクトに関する質問がある場合は、チームメンバーに気軽に聞いてください!**
