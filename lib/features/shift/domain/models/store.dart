import 'package:flutter/material.dart';

/// 勤務先店舗モデル
class Store {
  final String id; // UUID
  final String name; // 店舗名
  final Color color; // 識別用の色

  Store({
    required this.id,
    required this.name,
    required this.color,
  });

  /// コピーメソッド
  Store copyWith({
    String? name,
    Color? color,
  }) {
    return Store(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
    };
  }

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Store && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// デフォルトの店舗色パレット
const List<Color> storeColorPalette = [
  Color(0xFF5C6BC0), // インディゴ
  Color(0xFFFF7043), // ディープオレンジ
  Color(0xFF66BB6A), // グリーン
  Color(0xFFEC407A), // ピンク
  Color(0xFF42A5F5), // ブルー
  Color(0xFFAB47BC), // パープル
  Color(0xFF26A69A), // ティール
  Color(0xFFFFCA28), // アンバー
];
