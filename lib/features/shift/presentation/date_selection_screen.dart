import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/shift_date_provider.dart';
import 'shift_list_screen.dart';

class DateSelectionScreen extends ConsumerStatefulWidget {
  const DateSelectionScreen({super.key});

  @override
  ConsumerState<DateSelectionScreen> createState() =>
      _DateSelectionScreenState();
}

class _DateSelectionScreenState extends ConsumerState<DateSelectionScreen> {
  // カレンダーの状態
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 一時的な選択（確定前）
  final Set<DateTime> _tempSelectedDates = {};

  // 2025年の祝日リスト（日本）
  final Map<DateTime, String> _holidays = {
    DateTime.utc(2025, 1, 1): '元日',
    DateTime.utc(2025, 1, 13): '成人の日',
    DateTime.utc(2025, 2, 11): '建国記念の日',
    DateTime.utc(2025, 2, 23): '天皇誕生日',
    DateTime.utc(2025, 3, 20): '春分の日',
    DateTime.utc(2025, 4, 29): '昭和の日',
    DateTime.utc(2025, 5, 3): '憲法記念日',
    DateTime.utc(2025, 5, 4): 'みどりの日',
    DateTime.utc(2025, 5, 5): 'こどもの日',
    DateTime.utc(2025, 7, 21): '海の日',
    DateTime.utc(2025, 8, 11): '山の日',
    DateTime.utc(2025, 9, 15): '敬老の日',
    DateTime.utc(2025, 9, 23): '秋分の日',
    DateTime.utc(2025, 10, 13): 'スポーツの日',
    DateTime.utc(2025, 11, 3): '文化の日',
    DateTime.utc(2025, 11, 23): '勤労感謝の日',
  };

  // 日付を正規化（時刻を00:00:00に）
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  // 日付が選択されているか確認
  bool _isSelected(DateTime day) {
    final normalized = _normalizeDate(day);
    return _tempSelectedDates.contains(normalized);
  }

  // 日付が祝日か確認
  bool _isHoliday(DateTime day) {
    final normalized = _normalizeDate(day);
    return _holidays.containsKey(normalized);
  }

  // 日付が土日祝日か確認
  bool _isWeekendOrHoliday(DateTime day) {
    return day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday ||
        _isHoliday(day);
  }

  // 日付が平日か確認
  bool _isWeekday(DateTime day) {
    return !_isWeekendOrHoliday(day);
  }

  // 日付の選択/解除
  void _toggleDate(DateTime day) {
    setState(() {
      final normalized = _normalizeDate(day);
      if (_tempSelectedDates.contains(normalized)) {
        _tempSelectedDates.remove(normalized);
      } else {
        _tempSelectedDates.add(normalized);
      }
    });
  }

  // 平日のみ選択
  void _selectWeekdays() {
    setState(() {
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      for (int i = 0; i <= lastDay.day - 1; i++) {
        final day = firstDay.add(Duration(days: i));
        if (_isWeekday(day)) {
          _tempSelectedDates.add(_normalizeDate(day));
        }
      }
    });
  }

  // 全日選択
  void _selectAllDays() {
    setState(() {
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      for (int i = 0; i <= lastDay.day - 1; i++) {
        final day = firstDay.add(Duration(days: i));
        _tempSelectedDates.add(_normalizeDate(day));
      }
    });
  }

  // 土日祝日のみ選択
  void _selectWeekendsAndHolidays() {
    setState(() {
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      for (int i = 0; i <= lastDay.day - 1; i++) {
        final day = firstDay.add(Duration(days: i));
        if (_isWeekendOrHoliday(day)) {
          _tempSelectedDates.add(_normalizeDate(day));
        }
      }
    });
  }

  // クリア
  void _clearSelection() {
    setState(() {
      _tempSelectedDates.clear();
    });
  }

  // 日付を確定してリスト画面へ遷移
  void _confirmAndNavigate() {
    if (_tempSelectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日付を選択してください')),
      );
      return;
    }

    // Providerに日付を追加
    ref.read(shiftDateProvider.notifier).addDates(_tempSelectedDates.toList());

    // リスト画面へ遷移
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ShiftListScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト日付選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _confirmAndNavigate,
            child: const Text(
              '次へ',
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
          // カレンダー
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,

            // 複数選択モード
            selectedDayPredicate: (day) => _isSelected(day),

            // ヘッダースタイル
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            // カレンダースタイル
            calendarStyle: CalendarStyle(
              // 今日
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              // 選択された日
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              // 土曜日
              weekendTextStyle: const TextStyle(color: Colors.blue),
              // 休日（祝日）
              holidayTextStyle: const TextStyle(color: Colors.red),
            ),

            // 祝日判定
            holidayPredicate: (day) => _isHoliday(day),

            // 日付タップ時の処理
            onDaySelected: (selectedDay, focusedDay) {
              _toggleDate(selectedDay);
              setState(() {
                _focusedDay = focusedDay;
              });
            },

            // ページ変更時の処理
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),

          const Divider(),

          // 選択ボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 選択数表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '選択: ${_tempSelectedDates.length}日',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // ボタン行1
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectWeekdays,
                        icon: const Icon(Icons.business_center),
                        label: const Text('平日のみ'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectAllDays,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('全日'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ボタン行2
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectWeekendsAndHolidays,
                        icon: const Icon(Icons.weekend),
                        label: const Text('土日祝日'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearSelection,
                        icon: const Icon(Icons.clear),
                        label: const Text('クリア'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 選択された日付リスト
          Expanded(
            child: _buildSelectedDatesList(),
          ),
        ],
      ),
    );
  }

  // 選択された日付のリスト
  Widget _buildSelectedDatesList() {
    if (_tempSelectedDates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '日付をタップして選択',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 日付を昇順にソート
    final sortedDates = _tempSelectedDates.toList()
      ..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final weekday = DateFormat.E('ja_JP').format(date);
        final isWeekendOrHoliday = _isWeekendOrHoliday(date);
        final holidayName = _holidays[date];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isWeekendOrHoliday ? Colors.red : Colors.blue,
              child: Text(
                DateFormat('d').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  '${DateFormat('M月d日').format(date)}（$weekday）',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWeekendOrHoliday ? Colors.red : Colors.black,
                  ),
                ),
                if (holidayName != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      holidayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.red[100],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => _toggleDate(date),
            ),
          ),
        );
      },
    );
  }
}
