import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/shift_date_provider.dart';

class TimeSettingScreen extends ConsumerStatefulWidget {
  final String dateString;

  const TimeSettingScreen({
    super.key,
    required this.dateString,
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
        shiftDates.firstWhere((d) => d.dateString == widget.dateString);

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

  // 時間を文字列に変換
  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 保存
  void _save() {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開始時刻と終了時刻を設定してください')),
      );
      return;
    }

    // 時刻の妥当性チェック
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('終了時刻は開始時刻より後にしてください')),
      );
      return;
    }

    // Providerに保存
    ref.read(shiftDateProvider.notifier).updateTime(
          widget.dateString,
          _timeToString(_startTime!),
          _timeToString(_endTime!),
        );

    if (_memoController.text.isNotEmpty) {
      ref.read(shiftDateProvider.notifier).updateMemo(
            widget.dateString,
            _memoController.text,
          );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました')),
    );
  }

  // 勤務時間を計算
  String _calculateWorkingHours() {
    if (_startTime == null || _endTime == null) {
      return '--';
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final diff = endMinutes - startMinutes;

    if (diff <= 0) return '--';

    final hours = diff ~/ 60;
    final minutes = diff % 60;

    return '$hours時間${minutes > 0 ? "$minutes分" : ""}';
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.dateString);
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

            // 開始時刻
            Card(
              child: ListTile(
                leading: const Icon(Icons.login, color: Colors.green),
                title: const Text('開始時刻'),
                subtitle: _startTime != null
                    ? null
                    : const Text('タップして設定', style: TextStyle(fontSize: 12)),
                trailing: Text(
                  _startTime?.format(context) ?? '--:--',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _startTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // 終了時刻
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('終了時刻'),
                subtitle: _endTime != null
                    ? null
                    : const Text('タップして設定', style: TextStyle(fontSize: 12)),
                trailing: Text(
                  _endTime?.format(context) ?? '--:--',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        _endTime ?? const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => _endTime = picked);
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // クイック設定ボタン
            const Text(
              'クイック設定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSetButton('9:00 - 18:00', 9, 0, 18, 0),
                _buildQuickSetButton('10:00 - 19:00', 10, 0, 19, 0),
                _buildQuickSetButton('13:00 - 22:00', 13, 0, 22, 0),
                _buildQuickSetButton('17:00 - 23:00', 17, 0, 23, 0),
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
    int endMinute,
  ) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _startTime = TimeOfDay(hour: startHour, minute: startMinute);
          _endTime = TimeOfDay(hour: endHour, minute: endMinute);
        });
      },
      child: Text(label),
    );
  }
}
