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
      'color': color.toARGB32(),
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

/// デフォルトの店舗色パレット（掛け持ち機能用）
const List<Color> storeColorPalette = [
  Colors.white, // デフォルト店舗（本店）
  Colors.red, // 掛け持ち先1
  Colors.blue, // 掛け持ち先2
  Colors.green, // 掛け持ち先3
];
