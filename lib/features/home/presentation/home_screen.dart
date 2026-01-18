import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../shift/presentation/date_selection_screen.dart';
import '../../shift/presentation/advanced_date_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // カレンダーの状態
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 仮のシフトデータ（後でデータベースから取得）
  final Map<DateTime, List<Map<String, dynamic>>> _shifts = {
    DateTime.utc(2025, 1, 15): [
      {'store': 'カフェA', 'time': '10:00-18:00', 'color': Colors.blue},
    ],
    DateTime.utc(2025, 1, 18): [
      {'store': '居酒屋B', 'time': '14:00-22:00', 'color': Colors.red},
    ],
    DateTime.utc(2025, 1, 20): [
      {'store': 'コンビニC', 'time': '09:00-17:00', 'color': Colors.green},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // その日のシフトを取得
  List<Map<String, dynamic>> _getShiftsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _shifts[normalizedDay] ?? [];
  }

  // 今週の予定を取得
  List<Map<String, dynamic>> _getThisWeekShifts() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> thisWeekShifts = [];

    for (int i = 0; i < 7; i++) {
      final day = now.add(Duration(days: i));
      final shifts = _getShiftsForDay(day);
      for (var shift in shifts) {
        thisWeekShifts.add({
          'date': day,
          'store': shift['store'],
          'time': shift['time'],
          'color': shift['color'],
        });
      }
    }

    return thisWeekShifts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S×S Manager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // PDF出力画面へ遷移（後で実装）
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF出力機能は後で実装します')),
              );
            },
            tooltip: 'PDF出力',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 設定画面へ遷移（後で実装）
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定画面は後で実装します')),
              );
            },
            tooltip: '設定',
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
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,

            // 日本語のヘッダーフォーマット
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // カレンダースタイル
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),

            // 日付選択時の処理
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // シフト入力画面へ遷移（後で実装）
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${DateFormat('M月d日').format(selectedDay)}のシフト入力画面へ遷移',
                  ),
                ),
              );
            },

            // ページ変更時の処理
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },

            // シフトマーカーの表示
            eventLoader: (day) {
              return _getShiftsForDay(day);
            },

            calendarBuilders: CalendarBuilders(
              // シフトドット表示
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((event) {
                      final shift = event as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: shift['color'],
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          const Divider(),

          // 今週の予定リスト
          Expanded(
            child: _buildWeeklyShiftsList(),
          ),
        ],
      ),

      // ボトムナビゲーション
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '勤務先',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '統計',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('勤務先管理画面は後で実装します')),
            );
          } else if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('統計画面はPhase 2で実装します')),
            );
          }
        },
      ),

      // 日付選択ボタン
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'simple',
            onPressed: () async {
              // シンプルな日付選択画面へ遷移
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DateSelectionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.event),
            label: const Text('シンプル'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'advanced',
            onPressed: () async {
              // 拡張版日付選択画面へ遷移
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdvancedDateSelectionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('掛け持ち対応'),
          ),
        ],
      ),
    );
  }

  // 今週の予定リスト
  Widget _buildWeeklyShiftsList() {
    final shifts = _getThisWeekShifts();

    if (shifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '今週のシフトはありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final shift = shifts[index];
        final date = shift['date'] as DateTime;
        final weekday = DateFormat.E('ja_JP').format(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: shift['color'],
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
                  '${DateFormat('M/d').format(date)}（$weekday）',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  shift['time'],
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shift['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(shift['store']),
              ],
            ),
            onTap: () {
              // シフト編集画面へ遷移（後で実装）
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${shift['store']}のシフト編集画面へ遷移'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
