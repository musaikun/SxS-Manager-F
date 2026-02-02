import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/shift_date_provider.dart';
import '../utils/time_utils.dart';
import '../constants/shift_constants.dart';

class TimeSettingScreen extends ConsumerStatefulWidget {
  final String uniqueKey;

  const TimeSettingScreen({
    super.key,
    required this.uniqueKey,
  });

  @override
  ConsumerState<TimeSettingScreen> createState() => _TimeSettingScreenState();
}

class QuickSetPreset {
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool crossesMidnight;

  QuickSetPreset({
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.crossesMidnight = false,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'crossesMidnight': crossesMidnight,
      };

  factory QuickSetPreset.fromJson(Map<String, dynamic> json) => QuickSetPreset(
        label: json['label'],
        startHour: json['startHour'],
        startMinute: json['startMinute'],
        endHour: json['endHour'],
        endMinute: json['endMinute'],
        crossesMidnight: json['crossesMidnight'] ?? false,
      );
}

class _TimeSettingScreenState extends ConsumerState<TimeSettingScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _memoController = TextEditingController();
  List<QuickSetPreset> _customPresets = [];

  @override
  void initState() {
    super.initState();
    // 既存のデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
      _loadCustomPresets();
    });
  }

  // カスタムプリセットを読み込み
  Future<void> _loadCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getString(ShiftConstants.customPresetsStorageKey);
    if (presetsJson != null) {
      final List<dynamic> decoded = jsonDecode(presetsJson);
      setState(() {
        _customPresets =
            decoded.map((json) => QuickSetPreset.fromJson(json)).toList();
      });
    }
  }

  // カスタムプリセットを保存
  Future<void> _saveCustomPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson =
        jsonEncode(_customPresets.map((p) => p.toJson()).toList());
    await prefs.setString(ShiftConstants.customPresetsStorageKey, presetsJson);
  }

  // カスタムプリセットを追加
  Future<void> _addCustomPreset() async {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先に時間を設定してください')),
      );
      return;
    }

    final TextEditingController labelController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プリセット名を入力'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(
            hintText: '例：早番、遅番、夜勤',
            labelText: 'プリセット名',
          ),
          maxLength: 15,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (labelController.text.isNotEmpty) {
                Navigator.pop(context, labelController.text);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // 日をまたぐかチェック
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      final crossesMidnight = endMinutes <= startMinutes;

      setState(() {
        _customPresets.add(QuickSetPreset(
          label: result,
          startHour: _startTime!.hour,
          startMinute: _startTime!.minute,
          endHour: _endTime!.hour,
          endMinute: _endTime!.minute,
          crossesMidnight: crossesMidnight,
        ));
      });
      await _saveCustomPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$result」を追加しました')),
        );
      }
    }
  }

  // カスタムプリセットを削除
  Future<void> _deleteCustomPreset(int index) async {
    final preset = _customPresets[index];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プリセットを削除'),
        content: Text('「${preset.label}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _customPresets.removeAt(index);
      });
      await _saveCustomPresets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${preset.label}」を削除しました')),
        );
      }
    }
  }

  void _loadExistingData() {
    final shiftDates = ref.read(shiftDateProvider);
    final shiftDate =
        shiftDates.firstWhere((d) => d.uniqueKey == widget.uniqueKey);

    if (shiftDate.startTime != null) {
      final parts = shiftDate.startTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    if (shiftDate.endTime != null) {
      final parts = shiftDate.endTime!.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    if (shiftDate.memo != null) {
      _memoController.text = shiftDate.memo!;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  // 保存
  void _save() {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ShiftConstants.messageNoTimeSet)),
      );
      return;
    }

    // Providerに保存（日をまたぐ場合も許可）
    ref.read(shiftDateProvider.notifier).updateTime(
          widget.uniqueKey,
          TimeUtils.timeToString(_startTime!),
          TimeUtils.timeToString(_endTime!),
        );

    if (_memoController.text.isNotEmpty) {
      ref.read(shiftDateProvider.notifier).updateMemo(
            widget.uniqueKey,
            _memoController.text,
          );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ShiftConstants.messageSaved)),
    );
  }

  // 勤務時間を計算（日をまたぐ場合も対応）
  String _calculateWorkingHours() {
    return TimeUtils.formatWorkingHours(_startTime, _endTime);
  }

  // 時間設定ダイアログを表示（スライダー式）
  void _showTimeSettingDialog() {
    // 初期値を15分刻みに丸める
    TimeOfDay initialStartTime = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay initialEndTime = _endTime ?? const TimeOfDay(hour: 18, minute: 0);

    // 分を15分刻みに丸める
    int startMinutes = initialStartTime.hour * 60 + TimeUtils.roundToQuarterHour(initialStartTime.minute);
    int endMinutes = initialEndTime.hour * 60 + TimeUtils.roundToQuarterHour(initialEndTime.minute);

    // 終了時刻が開始時刻より前の場合は、翌日とみなす（+TimeUtils.minutesPerDay分）
    if (endMinutes <= startMinutes) {
      endMinutes += TimeUtils.minutesPerDay;
    }

    double tempStartMinutes = startMinutes.toDouble();
    double tempEndMinutes = endMinutes.toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          TimeOfDay currentStartTime = TimeUtils.minutesToTime(tempStartMinutes.round());
          TimeOfDay currentEndTime = TimeUtils.minutesToTime(tempEndMinutes.round() % TimeUtils.minutesPerDay);

          // 勤務時間を計算
          int workingMinutes = (tempEndMinutes - tempStartMinutes).round();
          int workingHours = workingMinutes ~/ 60;
          int workingMins = workingMinutes % 60;

          // 日をまたぐかどうか
          bool crossesMidnight = tempEndMinutes >= TimeUtils.minutesPerDay;

          return AlertDialog(
            title: const Text('勤務時間設定'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        label: '${currentStartTime.hour}:${currentStartTime.minute.toString().padLeft(2, '0')}',
                        onChanged: (value) {
                          setDialogState(() {
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
                        divisions: ((tempStartMinutes + 720 - tempStartMinutes - 15) ~/ 15).toInt(),
                        activeColor: Colors.red,
                        label: '${currentEndTime.hour}:${currentEndTime.minute.toString().padLeft(2, '0')}${crossesMidnight ? " (翌日)" : ""}',
                        onChanged: (value) {
                          setDialogState(() {
                            // 15分刻みに丸める
                            tempEndMinutes = (value ~/ 15 * 15).toDouble();
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // クイック設定
                  const Text(
                    'クイック設定',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // デフォルトプリセット
                      _buildDialogQuickSetButton(
                        setDialogState,
                        (start, end) {
                          tempStartMinutes = TimeUtils.timeToMinutes(start).toDouble();
                          tempEndMinutes = TimeUtils.timeToMinutes(end).toDouble();
                        },
                        '9:00-18:00',
                        9,
                        0,
                        18,
                        0,
                      ),
                      _buildDialogQuickSetButton(
                        setDialogState,
                        (start, end) {
                          tempStartMinutes = TimeUtils.timeToMinutes(start).toDouble();
                          tempEndMinutes = TimeUtils.timeToMinutes(end).toDouble();
                        },
                        '10:00-19:00',
                        10,
                        0,
                        19,
                        0,
                      ),
                      _buildDialogQuickSetButton(
                        setDialogState,
                        (start, end) {
                          tempStartMinutes = TimeUtils.timeToMinutes(start).toDouble();
                          tempEndMinutes = TimeUtils.timeToMinutes(end).toDouble();
                        },
                        '13:00-22:00',
                        13,
                        0,
                        22,
                        0,
                      ),
                      _buildDialogQuickSetButton(
                        setDialogState,
                        (start, end) {
                          tempStartMinutes = TimeUtils.timeToMinutes(start).toDouble();
                          tempEndMinutes = TimeUtils.timeToMinutes(end).toDouble();
                        },
                        '17:00-23:00',
                        17,
                        0,
                        23,
                        0,
                      ),
                      _buildDialogQuickSetButton(
                        setDialogState,
                        (start, end) {
                          tempStartMinutes = TimeUtils.timeToMinutes(start).toDouble();
                          // 深夜帯なので翌日扱い
                          tempEndMinutes = (TimeUtils.timeToMinutes(end) + TimeUtils.minutesPerDay).toDouble();
                        },
                        '22:00-翌7:00',
                        22,
                        0,
                        7,
                        0,
                      ),
                      // カスタムプリセット
                      ..._customPresets.map((preset) {
                        return _buildDialogQuickSetButton(
                          setDialogState,
                          (start, end) {
                            tempStartMinutes = TimeUtils.timeToMinutes(start).toDouble();
                            if (preset.crossesMidnight) {
                              tempEndMinutes = (TimeUtils.timeToMinutes(end) + TimeUtils.minutesPerDay).toDouble();
                            } else {
                              tempEndMinutes = TimeUtils.timeToMinutes(end).toDouble();
                            }
                          },
                          preset.crossesMidnight
                              ? '${preset.label}\n${preset.startHour}:${preset.startMinute.toString().padLeft(2, '0')}-翌${preset.endHour}:${preset.endMinute.toString().padLeft(2, '0')}'
                              : '${preset.label}\n${preset.startHour}:${preset.startMinute.toString().padLeft(2, '0')}-${preset.endHour}:${preset.endMinute.toString().padLeft(2, '0')}',
                          preset.startHour,
                          preset.startMinute,
                          preset.endHour,
                          preset.endMinute,
                          isCustom: true,
                          onDelete: () async {
                            Navigator.pop(context);
                            await _deleteCustomPreset(_customPresets.indexOf(preset));
                          },
                        );
                      }).toList(),
                    ],
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
                  setState(() {
                    _startTime = TimeUtils.minutesToTime(tempStartMinutes.round());
                    _endTime = TimeUtils.minutesToTime(tempEndMinutes.round() % TimeUtils.minutesPerDay);
                  });
                  Navigator.pop(context);
                },
                child: const Text('設定'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ダイアログ用クイック設定ボタン
  Widget _buildDialogQuickSetButton(
    StateSetter setDialogState,
    Function(TimeOfDay, TimeOfDay) onSet,
    String label,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute, {
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    if (isCustom && onDelete != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          OutlinedButton(
            onPressed: () {
              setDialogState(() {
                onSet(
                  TimeOfDay(hour: startHour, minute: startMinute),
                  TimeOfDay(hour: endHour, minute: endMinute),
                );
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: Colors.purple,
              side: const BorderSide(color: Colors.purple),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            right: -8,
            top: -8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return OutlinedButton(
      onPressed: () {
        setDialogState(() {
          onSet(
            TimeOfDay(hour: startHour, minute: startMinute),
            TimeOfDay(hour: endHour, minute: endMinute),
          );
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // uniqueKeyから日付を抽出（形式: "2025-01-15_storeId"）
    final dateString = widget.uniqueKey.split('_')[0];
    final date = DateTime.parse(dateString);
    final weekday = DateFormat.E('ja_JP').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('時間設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 日付表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      DateFormat('yyyy年M月d日（E）', 'ja_JP').format(date),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_startTime != null && _endTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '勤務時間: ${_calculateWorkingHours()}',
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
            ),

            const SizedBox(height: 24),

            // 時間設定カード（1つのカードで両方設定）
            Card(
              child: InkWell(
                onTap: _showTimeSettingDialog,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '勤務時間',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_startTime == null || _endTime == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'タップして設定',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  _startTime?.format(context) ?? '--:--',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            size: 32,
                            color: Colors.grey,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '終了',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endTime?.format(context) ?? '--:--',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // クイック設定ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'クイック設定',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addCustomPreset,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('追加', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // デフォルトプリセット
                _buildQuickSetButton('9:00 - 18:00', 9, 0, 18, 0),
                _buildQuickSetButton('10:00 - 19:00', 10, 0, 19, 0),
                _buildQuickSetButton('13:00 - 22:00', 13, 0, 22, 0),
                _buildQuickSetButton('17:00 - 23:00', 17, 0, 23, 0),
                // カスタムプリセット
                ..._customPresets.map((preset) {
                  return _buildQuickSetButton(
                    preset.crossesMidnight
                        ? '${preset.label} (${preset.startHour}:${preset.startMinute.toString().padLeft(2, '0')}-翌${preset.endHour}:${preset.endMinute.toString().padLeft(2, '0')})'
                        : '${preset.label} (${preset.startHour}:${preset.startMinute.toString().padLeft(2, '0')}-${preset.endHour}:${preset.endMinute.toString().padLeft(2, '0')})',
                    preset.startHour,
                    preset.startMinute,
                    preset.endHour,
                    preset.endMinute,
                    isCustom: true,
                  );
                }).toList(),
              ],
            ),

            const SizedBox(height: 24),

            // メモ
            const Text(
              'メモ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                hintText: '備考やメモを入力',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              maxLength: 100,
            ),

            const SizedBox(height: 24),

            // 保存ボタン
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('保存'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // クイック設定ボタン
  Widget _buildQuickSetButton(
    String label,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute, {
    bool isCustom = false,
  }) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _startTime = TimeOfDay(hour: startHour, minute: startMinute);
          _endTime = TimeOfDay(hour: endHour, minute: endMinute);
        });
      },
      style: isCustom
          ? OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: const BorderSide(color: Colors.purple),
            )
          : null,
      child: Text(label),
    );
  }
}
