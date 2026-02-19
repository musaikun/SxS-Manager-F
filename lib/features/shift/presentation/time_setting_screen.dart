import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

class _TimeSettingScreenState extends ConsumerState<TimeSettingScreen> {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 既存のデータを読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
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

  @override
  Widget build(BuildContext context) {
    // uniqueKeyから日付を抽出（形式: "2025-01-15_storeId"）
    final dateString = widget.uniqueKey.split('_')[0];
    final date = DateTime.parse(dateString);

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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

                ],
              ),
            ),
          ),

          // 保存ボタン（統一デザインフッター）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Colors.grey, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 24),
                label: const Text('保存'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
