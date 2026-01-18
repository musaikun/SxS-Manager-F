import 'package:flutter/material.dart';

/// 掛け持ち店舗（ジョブ）
class Job {
  final int id; // 1-4
  final String name; // 店舗名（14文字まで）
  final Color color; // 蛍光色
  final bool isActive; // アクティブ状態

  Job({
    required this.id,
    required this.name,
    required this.color,
    this.isActive = true,
  });

  Job copyWith({
    String? name,
    bool? isActive,
  }) {
    return Job(
      id: id,
      name: name ?? this.name,
      color: color,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'isActive': isActive,
    };
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
      isActive: json['isActive'] ?? true,
    );
  }
}

/// ジョブの蛍光色マッピング
const Map<int, Color> jobColors = {
  1: Color(0xFFFFFF00), // 蛍光黄色
  2: Color(0xFF39FF14), // 蛍光緑
  3: Color(0xFFFF10F0), // 蛍光ピンク
  4: Color(0xFF00FFFF), // 蛍光水色
};
