import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';

/// 週間・月間目標時間を設定する画面
///
/// ユーザーが目標時間を入力・保存できます。
/// Hiveには分単位で保存されますが、画面では時間単位で表示・入力します。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>(); // フォームのバリデーション用
  late final TextEditingController _weeklyController; // 週間目標の入力欄
  late final TextEditingController _monthlyController; // 月間目標の入力欄
  bool _isSaving = false; // 保存中かどうか

  /// 画面の初期化
  ///
  /// 現在の設定値を読み込んで、入力欄に表示します。
  /// Hiveには分単位で保存されているので、時間単位に変換します。
  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);

    // 分単位を時間単位に変換して入力欄に設定
    _weeklyController = TextEditingController(
      text: _minutesToHours(settings.weeklyGoalMinutes).toString(),
    );
    _monthlyController = TextEditingController(
      text: _minutesToHours(settings.monthlyGoalMinutes).toString(),
    );
  }

  /// 画面破棄時のクリーンアップ
  ///
  /// メモリリークを防ぐため、コントローラーを破棄します。
  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        // タブバーで画面を切り替えるため、戻るボタンは不要
        // 自動的に戻るボタンは表示されません
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      // 目標時間設定セクション
                      Text(
                        '目標時間',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '週間・月間の目標時間を設定できます。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _NumberField(
                        controller: _weeklyController,
                        label: '週間目標 (時間)',
                        helper: '1〜168時間のあいだで入力してください',
                        validator: (value) => _validateRange(
                          value: value,
                          min: 1,
                          max: 168,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _NumberField(
                        controller: _monthlyController,
                        label: '月間目標 (時間)',
                        helper: '1〜744時間のあいだで入力してください',
                        validator: (value) => _validateRange(
                          value: value,
                          min: 1,
                          max: 744,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // カテゴリー管理セクション
                      Text(
                        '項目設定',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最大3つまで項目を管理できます。',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // カテゴリーリスト
                      ...categories.map((category) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              category.icon,
                              color: category.color,
                              size: 28,
                            ),
                            title: Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showEditCategoryDialog(category);
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving ? '保存中...' : '目標時間を保存'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 入力値の範囲をチェックする
  ///
  /// 数字以外が入力されていたり、範囲外の値の場合はエラーメッセージを返します。
  /// 問題なければnullを返します。
  String? _validateRange({
    required String? value,
    required int min,
    required int max,
  }) {
    // 数字に変換できるかチェック
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      return '数字で入力してください';
    }
    // 範囲内かチェック
    if (parsed < min || parsed > max) {
      return '$min〜$maxの範囲で入力してください';
    }
    return null; // バリデーションOK
  }

  /// 保存ボタンが押された時の処理
  ///
  /// 処理の流れ:
  /// 1. バリデーションチェック
  /// 2. 保存中状態に変更(ボタンを無効化)
  /// 3. 時間単位の入力値を分単位に変換
  /// 4. Hiveに保存
  /// 5. 成功メッセージを表示
  Future<void> _handleSave() async {
    // バリデーションエラーがあれば何もしない
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 保存中フラグをON(ボタンが無効化される)
    setState(() => _isSaving = true);

    // 設定を更新するNotifierを取得
    final notifier = ref.read(appSettingsProvider.notifier);

    // 入力値を時間単位の整数に変換
    final weeklyHours = int.parse(_weeklyController.text);
    final monthlyHours = int.parse(_monthlyController.text);

    // 時間単位から分単位に変換してHiveに保存
    await notifier.updateGoals(
      weeklyGoalMinutes: weeklyHours * 60,
      monthlyGoalMinutes: monthlyHours * 60,
    );

    // 画面が既に閉じられている場合は何もしない
    if (!mounted) {
      return;
    }

    // 保存中フラグをOFF
    setState(() => _isSaving = false);

    // 保存成功メッセージを表示(タブバーで切り替えるため画面は閉じない)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('目標設定を更新しました')),
    );
  }

  /// 分単位を時間単位に変換
  ///
  /// 整数除算(~/)を使って、端数を切り捨てます。
  int _minutesToHours(int minutes) => minutes ~/ 60;

  /// カテゴリー編集ダイアログを表示
  ///
  /// カテゴリー名を変更できます。
  Future<void> _showEditCategoryDialog(dynamic category) async {
    final controller = TextEditingController(text: category.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('項目名を変更'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '項目名',
              hintText: '例: 勉強、仕事、趣味',
            ),
            autofocus: true,
            maxLength: 10, // 項目名は10文字まで
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(context, newName);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null && result != category.name) {
      // カテゴリー名を更新
      await ref.read(categoryListProvider.notifier).updateCategory(
            id: category.id,
            name: result,
            colorValue: category.colorValue,
            iconCodePoint: category.iconCodePoint,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('項目名を更新しました')),
      );
    }
  }
}

/// 数字入力欄のウィジェット
///
/// 週間目標と月間目標で同じデザインの入力欄を使うため、
/// 共通化しています。
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller, // 入力値を管理するコントローラー
    required this.label, // ラベル(例: "週間目標 (時間)")
    required this.helper, // ヘルプテキスト(例: "1〜168時間のあいだで...")
    required this.validator, // バリデーション関数
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: TextInputType.number, // 数字キーボードを表示
      validator: validator, // バリデーション関数を設定
      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 数字のみ入力可能
    );
  }
}
