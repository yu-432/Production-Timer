import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weeklyController;
  late final TextEditingController _monthlyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    // Hiveには分単位で保持しているので、画面では時間単位に揃えて表示する。
    _weeklyController = TextEditingController(
      text: _minutesToHours(settings.weeklyGoalMinutes).toString(),
    );
    _monthlyController = TextEditingController(
      text: _minutesToHours(settings.monthlyGoalMinutes).toString(),
    );
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
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
                      Text(
                        '週間・月間の目標時間を設定できます。', // シンプルでユーザ向けの説明に変更
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                      const SizedBox(height: 20),
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
                    label: Text(_isSaving ? '保存中...' : '保存する'),
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

  String? _validateRange({
    required String? value,
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) {
      return '数字で入力してください';
    }
    if (parsed < min || parsed > max) {
      return '$min〜$maxの範囲で入力してください';
    }
    return null;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final notifier = ref.read(appSettingsProvider.notifier);
    final weeklyHours = int.parse(_weeklyController.text);
    final monthlyHours = int.parse(_monthlyController.text);

    // Hive保存時に再び分単位へ変換して永続化する。
    await notifier.updateGoals(
      weeklyGoalMinutes: weeklyHours * 60,
      monthlyGoalMinutes: monthlyHours * 60,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  int _minutesToHours(int minutes) => minutes ~/ 60;
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.helper,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    // 同じ見た目の入力欄を量産せずに済むよう共有化。
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: TextInputType.number,
      validator: validator,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}
