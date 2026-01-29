import 'package:flutter/material.dart';
import '../models/time_range.dart';

/// 時間設定モーダル
/// シフトの開始時間と終了時間を設定するためのモーダルダイアログ
class TimeSettingModal extends StatefulWidget {
  final TimeRange? initialTimeRange;
  final String title;

  const TimeSettingModal({
    super.key,
    this.initialTimeRange,
    this.title = '時間設定',
  });

  /// モーダルを表示し、選択された時間範囲を返す
  static Future<TimeRange?> show(
    BuildContext context, {
    TimeRange? initialTimeRange,
    String title = '時間設定',
  }) {
    return showModalBottomSheet<TimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TimeSettingModal(
        initialTimeRange: initialTimeRange,
        title: title,
      ),
    );
  }

  @override
  State<TimeSettingModal> createState() => _TimeSettingModalState();
}

class _TimeSettingModalState extends State<TimeSettingModal> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTimeRange ?? TimeRange.defaultWorkHours();
    _startTime = initial.startTime;
    _endTime = initial.endTime;
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: '開始時間を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
      hourLabelText: '時',
      minuteLabelText: '分',
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: '終了時間を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
      hourLabelText: '時',
      minuteLabelText: '分',
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _onConfirm() {
    final result = TimeRange(startTime: _startTime, endTime: _endTime);
    Navigator.of(context).pop(result);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ハンドルバー
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // タイトル
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 時間選択セクション
              Row(
                children: [
                  // 開始時間
                  Expanded(
                    child: _TimeSelector(
                      label: '開始',
                      time: _startTime,
                      onTap: _selectStartTime,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: colorScheme.outline,
                    ),
                  ),
                  // 終了時間
                  Expanded(
                    child: _TimeSelector(
                      label: '終了',
                      time: _endTime,
                      onTap: _selectEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 勤務時間表示
              _DurationDisplay(
                startTime: _startTime,
                endTime: _endTime,
              ),
              const SizedBox(height: 24),

              // ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onConfirm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('決定'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 時間選択ボタン
class _TimeSelector extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                TimeRange.formatTime(time),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 勤務時間表示
class _DurationDisplay extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const _DurationDisplay({
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timeRange = TimeRange(startTime: startTime, endTime: endTime);
    final totalMinutes = timeRange.durationInMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    String durationText;
    if (hours > 0 && minutes > 0) {
      durationText = '$hours時間$minutes分';
    } else if (hours > 0) {
      durationText = '$hours時間';
    } else {
      durationText = '$minutes分';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '勤務時間: $durationText',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
