import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/category.dart';
import '../models/timer_record.dart';

/// データ永続化を担当するサービスクラス
///
/// Hiveデータベースを使って、以下のデータを保存・読み込みします:
/// - タイマーセッションの記録(TimerRecord)
/// - アプリの設定(AppSettings)
/// - カテゴリー(Category)
///
/// このクラスは main.dart で初期化され、Riverpodプロバイダー経由で使用されます。
class StorageService {
  // プライベートコンストラクタ(外部から直接インスタンス化できない)
  StorageService._(this._timerBox, this._settingsBox, this._categoryBox);

  // Hiveのボックス名と定数
  static const _timerRecordsBox = 'timer_records'; // タイマー記録を保存するボックス
  static const _settingsBoxName = 'app_settings'; // 設定を保存するボックス
  static const _categoryBoxName = 'categories'; // カテゴリーを保存するボックス
  static const _settingsKey = 'app_settings_singleton'; // 設定の保存キー
  static final _uuid = Uuid(); // UUID生成器(セッションIDに使用)

  final Box<TimerRecord> _timerBox; // タイマー記録用のHiveボックス
  final Box<AppSettings> _settingsBox; // 設定用のHiveボックス
  final Box<Category> _categoryBox; // カテゴリー用のHiveボックス

  /// StorageServiceを初期化する
  ///
  /// アプリ起動時(main.dart)で一度だけ呼び出されます。
  ///
  /// 処理の流れ:
  /// 1. Hiveを初期化
  /// 2. TimerRecord、AppSettings、Categoryのアダプターを登録
  /// 3. タイマー記録用、設定用、カテゴリー用のボックスを開く
  /// 4. 設定が存在しなければデフォルト値を保存
  /// 5. StorageServiceインスタンスを返す
  static Future<StorageService> initialize() async {
    // Hiveを初期化(Flutterのドキュメントディレクトリに保存)
    await Hive.initFlutter();

    // TimerRecordのアダプターを登録(typeId: 0)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TimerRecordAdapter());
    }
    // AppSettingsのアダプターを登録(typeId: 2に変更、typeId: 1はCategoryが使用)
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    // Categoryのアダプターを登録(typeId: 1)
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryAdapter());
    }

    // ボックスを開く(まだ存在しない場合は作成される)
    final timerBox = await Hive.openBox<TimerRecord>(_timerRecordsBox);
    final settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
    final categoryBox = await Hive.openBox<Category>(_categoryBoxName);

    // 設定が存在しなければデフォルト値を保存
    if (!settingsBox.containsKey(_settingsKey)) {
      await settingsBox.put(_settingsKey, AppSettings.defaults());
    }

    // インスタンスを作成して返す
    return StorageService._(timerBox, settingsBox, categoryBox);
  }

  /// 現在の設定を取得
  ///
  /// 設定は必ず存在するので、! で non-null にしています。
  AppSettings get settings => _settingsBox.get(_settingsKey)!;

  /// 設定を保存
  Future<void> saveSettings(AppSettings value) =>
      _settingsBox.put(_settingsKey, value);

  /// 新しいタイマーセッションを開始
  ///
  /// UUIDを生成して新しいTimerRecordを作成し、DBに保存します。
  /// 最初は経過時間0秒、endedAtはnull(未完了)の状態です。
  /// categoryIdを指定することで、どの項目の記録かを記録します。
  Future<TimerRecord> startNewSession(DateTime startedAt, {String? categoryId}) async {
    final record = TimerRecord(
      id: _uuid.v4(), // ランダムなUUIDを生成
      startedAt: startedAt,
      durationSeconds: 0, // 開始時は0秒
      categoryId: categoryId, // カテゴリーIDを保存
    );
    await _timerBox.put(record.id, record); // IDをキーとして保存
    return record;
  }

  /// 未完了のセッション(endedAtがnull)を取得
  ///
  /// アプリ起動時に未完了のセッションがあれば復元するために使用します。
  /// 通常は1つしかありませんが、複数ある場合は最初に見つかったものを返します。
  TimerRecord? getActiveRecord() {
    for (final record in _timerBox.values) {
      if (record.isActive) { // endedAtがnullかチェック
        return record;
      }
    }
    return null; // 未完了のセッションがない
  }

  /// IDを指定してセッションを取得
  TimerRecord? getRecordById(String id) => _timerBox.get(id);

  /// 実行中のセッションの経過時間を更新
  ///
  /// 30秒ごとに呼ばれて、現在の経過時間をDBに保存します。
  /// endedAtはnullのまま(まだ完了していない)です。
  Future<void> updateRunningSession({
    required String recordId,
    required Duration elapsed,
  }) async {
    final record = _timerBox.get(recordId);
    if (record == null) {
      return; // セッションが見つからない場合は何もしない
    }
    // 経過時間だけを更新した新しいレコードを作成
    final next = record.copyWith(durationSeconds: elapsed.inSeconds);
    await _timerBox.put(recordId, next);
  }

  /// セッションを完了させる
  ///
  /// タイマー停止時に呼ばれて、終了時刻(endedAt)を設定します。
  /// endedAtがnullでなくなることで、このセッションは「完了済み」になります。
  Future<void> completeSession({
    required String recordId,
    required Duration elapsed,
    required DateTime endedAt,
  }) async {
    final record = _timerBox.get(recordId);
    if (record == null) {
      return;
    }
    // 経過時間と終了時刻を設定した新しいレコードを作成
    final next = record.copyWith(
      durationSeconds: elapsed.inSeconds,
      endedAt: endedAt, // これでセッションが完了になる
    );
    await _timerBox.put(recordId, next);
  }

  /// セッションを削除
  ///
  /// リセットボタンを押した時に使用します。
  /// 記録を残さずにセッションを削除します。
  Future<void> deleteRecord(String recordId) => _timerBox.delete(recordId);

  /// 全てのセッションを取得(開始日時順にソート)
  List<TimerRecord> getAllRecords() => _sortedRecords();

  /// セッションの変更をリアルタイムで監視するStream
  ///
  /// 最初に現在の全セッションを返し、その後はHiveボックスに
  /// 変更があるたびに最新の全セッションを返します。
  /// StreamProviderで使用されます。
  Stream<List<TimerRecord>> watchRecords() async* {
    yield _sortedRecords(); // 最初に現在のデータを返す
    await for (final _ in _timerBox.watch()) { // ボックスの変更を監視
      yield _sortedRecords(); // 変更があったら最新のデータを返す
    }
  }

  /// 全セッションを開始日時順にソートして返す
  ///
  /// 古いセッションが先、新しいセッションが後になります。
  List<TimerRecord> _sortedRecords() {
    final records = _timerBox.values.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return records;
  }

  // ========================================
  // カテゴリー関連のメソッド
  // ========================================

  /// 全てのカテゴリーを取得
  ///
  /// 順序(order)でソートして返します。
  Future<List<Category>> loadCategories() async {
    final categories = _categoryBox.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  /// カテゴリーリストを保存
  ///
  /// 既存のカテゴリーを全て削除してから、新しいリストを保存します。
  Future<void> saveCategories(List<Category> categories) async {
    await _categoryBox.clear(); // 既存のデータを削除
    for (final category in categories) {
      await _categoryBox.put(category.id, category); // IDをキーとして保存
    }
  }
}
