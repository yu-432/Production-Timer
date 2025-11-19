import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import 'storage_provider.dart';

/// カテゴリーリストを管理するプロバイダー
///
/// ユーザーが作成した項目(カテゴリー)のリストを提供します。
/// 初回起動時はデフォルトの3つのカテゴリー(勉強、仕事、趣味)が作成されます。
final categoryListProvider =
    StateNotifierProvider<CategoryListNotifier, List<Category>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CategoryListNotifier(storage);
});

/// カテゴリーリストの状態を管理するNotifier
///
/// カテゴリーの追加、編集、削除、並び替えを行います。
/// 最大3つまでのカテゴリーを管理できます。
class CategoryListNotifier extends StateNotifier<List<Category>> {
  CategoryListNotifier(this._storage) : super([]) {
    _loadCategories();
  }

  final dynamic _storage; // StorageServiceのインスタンス
  final _uuid = const Uuid();

  /// ストレージからカテゴリーリストを読み込み
  ///
  /// 初回起動時はデフォルトカテゴリーを作成して保存します。
  Future<void> _loadCategories() async {
    final categories = await _storage.loadCategories();
    if (categories.isEmpty) {
      // 初回起動時: デフォルトカテゴリーを作成
      final defaultCategories = Category.defaultCategories();
      await _storage.saveCategories(defaultCategories);
      state = defaultCategories;
    } else {
      // 既存のカテゴリーを読み込み(表示順序でソート)
      state = List<Category>.from(categories)
        ..sort((a, b) => a.order.compareTo(b.order));
    }
  }

  /// カテゴリーを追加
  ///
  /// 最大3つまで追加できます。上限に達している場合は何もしません。
  Future<void> addCategory({
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    if (state.length >= 3) {
      // 上限に達している場合は追加しない
      return;
    }

    final newCategory = Category(
      id: _uuid.v4(), // ランダムなUUIDを生成
      name: name,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      order: state.length, // 現在の個数を順序番号にする(0, 1, 2)
    );

    final newList = [...state, newCategory];
    await _storage.saveCategories(newList);
    state = newList;
  }

  /// カテゴリーを編集
  ///
  /// 指定されたIDのカテゴリーの内容を変更します。
  Future<void> updateCategory({
    required String id,
    required String name,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index == -1) return; // 見つからない場合は何もしない

    final updatedCategory = state[index].copyWith(
      name: name,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
    );

    final newList = [...state];
    newList[index] = updatedCategory;
    await _storage.saveCategories(newList);
    state = newList;
  }

  /// カテゴリーを削除
  ///
  /// 指定されたIDのカテゴリーを削除し、残りのカテゴリーの順序を詰めます。
  Future<void> deleteCategory(String id) async {
    final newList = state.where((c) => c.id != id).toList();

    // 順序を詰め直す(0, 1, 2の連番に)
    for (var i = 0; i < newList.length; i++) {
      newList[i] = newList[i].copyWith(order: i);
    }

    await _storage.saveCategories(newList);
    state = newList;
  }

  /// カテゴリーの順序を変更
  ///
  /// ドラッグ&ドロップなどで並び替えた際に使用します。
  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final newList = [...state];
    final category = newList.removeAt(oldIndex);
    newList.insert(newIndex, category);

    // 順序を更新
    for (var i = 0; i < newList.length; i++) {
      newList[i] = newList[i].copyWith(order: i);
    }

    await _storage.saveCategories(newList);
    state = newList;
  }
}

/// 現在選択中のカテゴリーIDを管理するプロバイダー
///
/// タイマー開始時に、どの項目に時間を記録するかを決定します。
/// デフォルトでは一番上のカテゴリー(order=0)が選択されます。
final selectedCategoryIdProvider = StateProvider<String?>((ref) {
  final categories = ref.watch(categoryListProvider);
  // 一番上のカテゴリー(order=0)を選択
  return categories.isNotEmpty ? categories.first.id : null;
});
