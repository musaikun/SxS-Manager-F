import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/time_preset.dart';
import '../../providers/time_preset_provider.dart';

/// 時間設定モーダルの結果
class TimeSettingResult {
  final String startTime;
  final String endTime;
  final String? memo;

  TimeSettingResult({
    required this.startTime,
    required this.endTime,
    this.memo,
  });
}

/// 時間設定モーダル（個別・一括共通）
class TimeSettingModal extends ConsumerStatefulWidget {
  final String title; // モーダルのタイトル（例: "時間設定" or "一括時間設定（3件）"）
  final String? initialStartTime;
  final String? initialEndTime;
  final String? initialMemo;
  final bool showMemoField; // 備考欄を表示するか

  const TimeSettingModal({
    super.key,
    required this.title,
    this.initialStartTime,
    this.initialEndTime,
    this.initialMemo,
    this.showMemoField = true,
  });

  @override
  ConsumerState<TimeSettingModal> createState() => _TimeSettingModalState();
}

class _TimeSettingModalState extends ConsumerState<TimeSettingModal> {
  late double tempStartMinutes;
  late double tempEndMinutes;
  late TextEditingController memoController;

  @override
  void initState() {
    super.initState();

    // 初期値の設定
    if (widget.initialStartTime != null) {
      final parts = widget.initialStartTime!.split(':');
      tempStartMinutes =
          (int.parse(parts[0]) * 60 + int.parse(parts[1])).toDouble();
    } else {
      tempStartMinutes = 540.0; // 9:00
    }

    if (widget.initialEndTime != null) {
      final parts = widget.initialEndTime!.split(':');
      int minutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      // 終了時刻が開始時刻より前の場合は翌日扱い
      if (minutes <= tempStartMinutes) {
        minutes += 1440;
      }
      tempEndMinutes = minutes.toDouble();
    } else {
      tempEndMinutes = 1080.0; // 18:00
    }

    memoController = TextEditingController(text: widget.initialMemo ?? '');
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  // 分単位を時間に変換
  TimeOfDay _minutesToTime(int minutes) {
    return TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
  }

  // プリセット追加（名前入力なし、自動生成）
  void _addCurrentTimeAsPreset() {
    final currentStartTime = _minutesToTime(tempStartMinutes.round());
    final currentEndTime = _minutesToTime(tempEndMinutes.round() % 1440);
    final bool crossesMidnight = tempEndMinutes >= 1440;

    final String label = crossesMidnight
        ? '${currentStartTime.hour}:${currentStartTime.minute.toString().padLeft(2, '0')}-翌${currentEndTime.hour}:${currentEndTime.minute.toString().padLeft(2, '0')}'
        : '${currentStartTime.hour}:${currentStartTime.minute.toString().padLeft(2, '0')}-${currentEndTime.hour}:${currentEndTime.minute.toString().padLeft(2, '0')}';

    final preset = TimePreset(
      label: label,
      startHour: currentStartTime.hour,
      startMinute: currentStartTime.minute,
      endHour: currentEndTime.hour,
      endMinute: currentEndTime.minute,
      isNextDay: crossesMidnight,
    );

    ref.read(timePresetProvider.notifier).addPreset(preset);
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(timePresetProvider);
    final currentStartTime = _minutesToTime(tempStartMinutes.round());
    final currentEndTime = _minutesToTime(tempEndMinutes.round() % 1440);

    // 勤務時間を計算
    int workingMinutes = (tempEndMinutes - tempStartMinutes).round();
    int workingHours = workingMinutes ~/ 60;
    int workingMins = workingMinutes % 60;

    // 日をまたぐかどうか
    bool crossesMidnight = tempEndMinutes >= 1440;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 時間範囲の視覚表示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            '開始',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentStartTime.hour.toString().padLeft(2, '0')}:${currentStartTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, size: 32, color: Colors.grey),
                      Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '終了',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (crossesMidnight) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '翌日',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentEndTime.hour.toString().padLeft(2, '0')}:${currentEndTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '勤務時間: $workingHours時間${workingMins > 0 ? "$workingMins分" : ""}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 開始時刻スライダー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.login, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '開始時刻',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currentStartTime.hour}:${currentStartTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tempStartMinutes,
                  min: 0,
                  max: 1425, // 23:45まで（15分刻み）
                  divisions: 95, // 24時間 × 4 (15分刻み) - 1
                  activeColor: Colors.green,
                  label:
                      '${currentStartTime.hour}:${currentStartTime.minute.toString().padLeft(2, '0')}',
                  onChanged: (value) {
                    setState(() {
                      // 15分刻みに丸める
                      tempStartMinutes = (value ~/ 15 * 15).toDouble();

                      // 終了時刻が新しい範囲内に収まるように調整（最大12時間後）
                      double newMax = tempStartMinutes + 720;
                      if (tempEndMinutes > newMax) {
                        tempEndMinutes = newMax;
                      }

                      // 終了時刻が開始時刻より前にならないように調整
                      if (tempEndMinutes <= tempStartMinutes) {
                        tempEndMinutes = tempStartMinutes + 60; // 最低1時間の勤務時間
                      }
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 終了時刻スライダー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '終了時刻',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currentEndTime.hour}:${currentEndTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tempEndMinutes,
                  min: tempStartMinutes + 15, // 開始時刻の15分後から
                  max: tempStartMinutes + 720, // 開始時刻から最大12時間後
                  divisions:
                      ((tempStartMinutes + 720 - tempStartMinutes - 15) ~/ 15)
                          .toInt(),
                  activeColor: Colors.red,
                  label:
                      '${currentEndTime.hour}:${currentEndTime.minute.toString().padLeft(2, '0')}${crossesMidnight ? " (翌日)" : ""}',
                  onChanged: (value) {
                    setState(() {
                      // 15分刻みに丸める
                      tempEndMinutes = (value ~/ 15 * 15).toDouble();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 備考欄
            if (widget.showMemoField) ...[
              TextField(
                controller: memoController,
                decoration: const InputDecoration(
                  labelText: '備考',
                  hintText: '例: 遅刻するかも',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
            ],

            // クイック設定
            const Text(
              'クイック設定（タップで時間を設定）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          tempStartMinutes = preset.startMinutes.toDouble();
                          tempEndMinutes = preset.endMinutes.toDouble();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text(preset.label,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          ref
                              .read(timePresetProvider.notifier)
                              .removePreset(preset.label);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // 現在の時間を追加ボタン（最大5個まで）
            if (presets.length < 5)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addCurrentTimeAsPreset,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('現在の時間を追加'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (presets.length >= 5)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'クイック設定は最大5個までです',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            final startTime = _minutesToTime(tempStartMinutes.round());
            final endTime = _minutesToTime(tempEndMinutes.round() % 1440);

            final startStr =
                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
            final endStr =
                '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

            final result = TimeSettingResult(
              startTime: startStr,
              endTime: endStr,
              memo: memoController.text.trim().isEmpty
                  ? null
                  : memoController.text.trim(),
            );

            Navigator.pop(context, result);
          },
          child: const Text('設定'),
        ),
      ],
    );
  }
}
