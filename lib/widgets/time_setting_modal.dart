import 'package:flutter/material.dart';
import '../models/time_range.dart';

/// 時間設定モーダル
/// シフトの開始時間と終了時間を設定するためのモーダルダイアログ
/// タップのみで時間を選択できるグリッド形式UI
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
  late int _startHour;
  late int _startMinute;
  late int _endHour;
  late int _endMinute;

  // true: 開始時間を編集中, false: 終了時間を編集中
  bool _isEditingStart = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTimeRange ?? TimeRange.defaultWorkHours();
    _startHour = initial.startTime.hour;
    _startMinute = _roundToQuarter(initial.startTime.minute);
    _endHour = initial.endTime.hour;
    _endMinute = _roundToQuarter(initial.endTime.minute);
  }

  /// 分を15分単位に丸める
  int _roundToQuarter(int minute) {
    return ((minute + 7) ~/ 15) * 15 % 60;
  }

  void _onHourSelected(int hour) {
    setState(() {
      if (_isEditingStart) {
        _startHour = hour;
      } else {
        _endHour = hour;
      }
    });
  }

  void _onMinuteSelected(int minute) {
    setState(() {
      if (_isEditingStart) {
        _startMinute = minute;
      } else {
        _endMinute = minute;
      }
    });
  }

  void _onConfirm() {
    final result = TimeRange(
      startTime: TimeOfDay(hour: _startHour, minute: _startMinute),
      endTime: TimeOfDay(hour: _endHour, minute: _endMinute),
    );
    Navigator.of(context).pop(result);
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  int get _currentHour => _isEditingStart ? _startHour : _endHour;
  int get _currentMinute => _isEditingStart ? _startMinute : _endMinute;

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
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 12),

              // タイトル
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 開始/終了 切り替えタブ
              _TimeToggle(
                isEditingStart: _isEditingStart,
                startHour: _startHour,
                startMinute: _startMinute,
                endHour: _endHour,
                endMinute: _endMinute,
                onToggle: (isStart) {
                  setState(() {
                    _isEditingStart = isStart;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 時間グリッド（0-23時）
              Text(
                '時',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              _HourGrid(
                selectedHour: _currentHour,
                onHourSelected: _onHourSelected,
              ),
              const SizedBox(height: 16),

              // 分ボタン（00, 15, 30, 45）
              Text(
                '分',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              _MinuteSelector(
                selectedMinute: _currentMinute,
                onMinuteSelected: _onMinuteSelected,
              ),
              const SizedBox(height: 16),

              // 勤務時間表示
              _DurationDisplay(
                startHour: _startHour,
                startMinute: _startMinute,
                endHour: _endHour,
                endMinute: _endMinute,
              ),
              const SizedBox(height: 16),

              // ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _onConfirm,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

/// 開始/終了時間の切り替えトグル
class _TimeToggle extends StatelessWidget {
  final bool isEditingStart;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final ValueChanged<bool> onToggle;

  const _TimeToggle({
    required this.isEditingStart,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.onToggle,
  });

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: '開始',
            time: _formatTime(startHour, startMinute),
            isSelected: isEditingStart,
            onTap: () => onToggle(true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            color: colorScheme.outline,
            size: 20,
          ),
        ),
        Expanded(
          child: _ToggleButton(
            label: '終了',
            time: _formatTime(endHour, endMinute),
            isSelected: !isEditingStart,
            onTap: () => onToggle(false),
          ),
        ),
      ],
    );
  }
}

/// トグルボタン
class _ToggleButton extends StatelessWidget {
  final String label;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 時間グリッド（0-23時）
class _HourGrid extends StatelessWidget {
  final int selectedHour;
  final ValueChanged<int> onHourSelected;

  const _HourGrid({
    required this.selectedHour,
    required this.onHourSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.5,
      ),
      itemCount: 24,
      itemBuilder: (context, index) {
        return _GridButton(
          label: index.toString().padLeft(2, '0'),
          isSelected: selectedHour == index,
          onTap: () => onHourSelected(index),
        );
      },
    );
  }
}

/// 分セレクター（00, 15, 30, 45）
class _MinuteSelector extends StatelessWidget {
  final int selectedMinute;
  final ValueChanged<int> onMinuteSelected;

  const _MinuteSelector({
    required this.selectedMinute,
    required this.onMinuteSelected,
  });

  static const List<int> _minutes = [0, 15, 30, 45];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _minutes.map((minute) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: minute != 45 ? 6 : 0,
            ),
            child: _GridButton(
              label: ':${minute.toString().padLeft(2, '0')}',
              isSelected: selectedMinute == minute,
              onTap: () => onMinuteSelected(minute),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// グリッドボタン
class _GridButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GridButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// 勤務時間表示
class _DurationDisplay extends StatelessWidget {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const _DurationDisplay({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timeRange = TimeRange(
      startTime: TimeOfDay(hour: startHour, minute: startMinute),
      endTime: TimeOfDay(hour: endHour, minute: endMinute),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '勤務時間: $durationText',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
