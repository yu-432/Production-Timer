import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// 作業項目(カテゴリー)を表すモデルクラス
///
/// 「勉強」「仕事」などの項目を管理します。
/// ユーザーは最大3つまでカテゴリーを作成できます。
/// 各カテゴリーには名前、色、アイコンを設定できます。
class Category {
  const Category({
    required this.id, // 一意な識別子(UUID)
    required this.name, // カテゴリー名(例: "勉強", "仕事")
    required this.colorValue, // 色を数値として保存(例: 0xFFFF5733)
    required this.iconCodePoint, // アイコンのコードポイント
    required this.order, // 表示順序(0が一番上)
  });

  final String id; // カテゴリーの一意なID
  final String name; // カテゴリー名
  final int colorValue; // 色(Color.valueをint型で保存)
  final int iconCodePoint; // アイコン(IconData.codePointをint型で保存)
  final int order; // 表示順序(0, 1, 2)

  /// 色をColor型で取得
  Color get color => Color(colorValue);

  /// アイコンをIconData型で取得
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  /// 一部のフィールドだけを変更した新しいインスタンスを作成
  ///
  /// カテゴリー名や色を編集する際に使用します。
  Category copyWith({
    String? name,
    int? colorValue,
    int? iconCodePoint,
    int? order,
  }) {
    return Category(
      id: id, // IDは変更不可
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      order: order ?? this.order,
    );
  }

  /// デフォルトのカテゴリーリストを生成
  ///
  /// 初回起動時に「勉強」「仕事」「趣味」の3つのカテゴリーを作成します。
  static List<Category> defaultCategories() {
    return [
      const Category(
        id: 'default-study',
        name: '勉強',
        colorValue: 0xFF42A5F5, // Colors.blue.shade400
        iconCodePoint: 0xe0be, // Icons.book_rounded
        order: 0,
      ),
      const Category(
        id: 'default-work',
        name: '仕事',
        colorValue: 0xFFFF9800, // Colors.orange.shade400
        iconCodePoint: 0xf02f, // Icons.work_rounded
        order: 1,
      ),
      const Category(
        id: 'default-hobby',
        name: '趣味',
        colorValue: 0xFF66BB6A, // Colors.green.shade400
        iconCodePoint: 0xe40a, // Icons.palette_rounded
        order: 2,
      ),
    ];
  }
}

/// CategoryをHiveデータベースに保存・読み込みするためのアダプター
///
/// カテゴリー情報をバイナリ形式で保存します。
class CategoryAdapter extends TypeAdapter<Category> {
  @override
  int get typeId => 1; // Hive内でこのデータ型を識別するID(TimerRecordは0番)

  /// Hiveからデータを読み込んでCategoryオブジェクトに変換
  @override
  Category read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final colorValue = reader.readInt();
    final iconCodePoint = reader.readInt();
    final order = reader.readInt();

    return Category(
      id: id,
      name: name,
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      order: order,
    );
  }

  /// CategoryオブジェクトをHiveに保存できる形式に変換
  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeInt(obj.colorValue)
      ..writeInt(obj.iconCodePoint)
      ..writeInt(obj.order);
  }
}
