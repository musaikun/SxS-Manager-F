import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/shift_date_provider.dart';
import '../providers/store_provider.dart';
import '../domain/models/store.dart';
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

  // 選択中の店舗ID
  String? _selectedStoreId;

  // 2025-2026年の祝日リスト（日本）
  final Map<DateTime, String> _holidays = {
    DateTime.utc(2025, 1, 1): '元日',
    DateTime.utc(2025, 1, 13): '成人の日',
    DateTime.utc(2025, 2, 11): '建国記念の日',
    DateTime.utc(2025, 2, 23): '天皇誕生日',
    DateTime.utc(2025, 2, 24): '振替休日',
    DateTime.utc(2025, 3, 20): '春分の日',
    DateTime.utc(2025, 4, 29): '昭和の日',
    DateTime.utc(2025, 5, 3): '憲法記念日',
    DateTime.utc(2025, 5, 4): 'みどりの日',
    DateTime.utc(2025, 5, 5): 'こどもの日',
    DateTime.utc(2025, 5, 6): '振替休日',
    DateTime.utc(2025, 7, 21): '海の日',
    DateTime.utc(2025, 8, 11): '山の日',
    DateTime.utc(2025, 9, 15): '敬老の日',
    DateTime.utc(2025, 9, 23): '秋分の日',
    DateTime.utc(2025, 10, 13): 'スポーツの日',
    DateTime.utc(2025, 11, 3): '文化の日',
    DateTime.utc(2025, 11, 23): '勤労感謝の日',
    DateTime.utc(2025, 11, 24): '振替休日',
    DateTime.utc(2026, 1, 1): '元日',
    DateTime.utc(2026, 1, 12): '成人の日',
    DateTime.utc(2026, 2, 11): '建国記念の日',
    DateTime.utc(2026, 2, 23): '天皇誕生日',
    DateTime.utc(2026, 3, 20): '春分の日',
    DateTime.utc(2026, 4, 29): '昭和の日',
    DateTime.utc(2026, 5, 3): '憲法記念日',
    DateTime.utc(2026, 5, 4): 'みどりの日',
    DateTime.utc(2026, 5, 5): 'こどもの日',
    DateTime.utc(2026, 5, 6): '振替休日',
    DateTime.utc(2026, 7, 20): '海の日',
    DateTime.utc(2026, 8, 11): '山の日',
    DateTime.utc(2026, 9, 21): '敬老の日',
    DateTime.utc(2026, 9, 22): '国民の休日',
    DateTime.utc(2026, 9, 23): '秋分の日',
    DateTime.utc(2026, 10, 12): 'スポーツの日',
    DateTime.utc(2026, 11, 3): '文化の日',
    DateTime.utc(2026, 11, 23): '勤労感謝の日',
  };

  @override
  void initState() {
    super.initState();
    // 初回起動時にデフォルト店舗を選択
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final defaultStore = ref.read(defaultStoreProvider);
      setState(() {
        _selectedStoreId = defaultStore.id;
      });
    });
  }

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

  // 曜日別選択（月=1, 日=7）
  void _toggleWeekday(int weekday) {
    setState(() {
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final weekdayDates = <DateTime>[];
      for (int i = 0; i < lastDay.day; i++) {
        final day = firstDay.add(Duration(days: i));
        if (day.weekday == weekday) {
          weekdayDates.add(_normalizeDate(day));
        }
      }

      // 全部選択済みか確認
      final allSelected =
          weekdayDates.every((d) => _tempSelectedDates.contains(d));

      if (allSelected) {
        // 解除
        weekdayDates.forEach(_tempSelectedDates.remove);
      } else {
        // 選択
        _tempSelectedDates.addAll(weekdayDates);
      }
    });
  }

  // 平日のみ選択
  void _selectWeekdays() {
    setState(() {
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      for (int i = 0; i < lastDay.day; i++) {
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

      for (int i = 0; i < lastDay.day; i++) {
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

      for (int i = 0; i < lastDay.day; i++) {
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

    if (_selectedStoreId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('店舗を選択してください')),
      );
      return;
    }

    // Providerに日付を追加
    ref
        .read(shiftDateProvider.notifier)
        .addDates(_tempSelectedDates.toList(), _selectedStoreId!);

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
    final stores = ref.watch(storeProvider);
    final shiftDates = ref.watch(shiftDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト日付選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () => _showStoreManageDialog(context),
            tooltip: '店舗管理',
          ),
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
          // 店舗セレクター
          _buildStoreSelector(stores),

          const Divider(height: 1),

          // 曜日別選択ボタン
          _buildWeekdayButtons(),

          const Divider(height: 1),

          // カレンダー
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'ja_JP',

              // 複数選択モード
              selectedDayPredicate: (day) => _isSelected(day),

              // ヘッダースタイル
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
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

              // カスタムビルダー
              calendarBuilders: CalendarBuilders(
                // 日付の下に複数店舗インジケーターを表示
                markerBuilder: (context, day, events) {
                  final count = ref
                      .read(shiftDateProvider.notifier)
                      .getShiftCountForDate(day);

                  if (count == 0) return const SizedBox.shrink();

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // 選択ボタン
          _buildActionButtons(),

          // 選択数表示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: const Border(top: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 20),
                const SizedBox(width: 8),
                Text(
                  '選択: ${_tempSelectedDates.length}日',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 店舗セレクター
  Widget _buildStoreSelector(List<Store> stores) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '店舗選択',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...stores.map((store) {
                final isSelected = _selectedStoreId == store.id;
                return ChoiceChip(
                  label: Text(store.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStoreId = store.id;
                      });
                    }
                  },
                  selectedColor: store.color.withOpacity(0.7),
                  backgroundColor: store.color.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
              // 店舗追加ボタン
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('店舗追加'),
                onPressed: () => _showAddStoreDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 曜日別選択ボタン
  Widget _buildWeekdayButtons() {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final colors = [
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.blue,
      Colors.red,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final weekday = index + 1; // 1=月, 7=日
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: OutlinedButton(
                onPressed: () => _toggleWeekday(weekday),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  side: BorderSide(color: colors[index]),
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: colors[index],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // アクションボタン
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectWeekdays,
              icon: const Icon(Icons.business_center, size: 16),
              label: const Text('平日', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectAllDays,
              icon: const Icon(Icons.calendar_month, size: 16),
              label: const Text('全日', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _selectWeekendsAndHolidays,
              icon: const Icon(Icons.weekend, size: 16),
              label: const Text('土日祝', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('クリア', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 店舗追加ダイアログ
  void _showAddStoreDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '店舗名',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newStore = ref
                    .read(storeProvider.notifier)
                    .addStore(controller.text);
                setState(() {
                  _selectedStoreId = newStore.id;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  // 店舗管理ダイアログ
  void _showStoreManageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StoreManageDialog(),
    );
  }
}

// 店舗管理ダイアログ
class _StoreManageDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storeProvider);

    return AlertDialog(
      title: const Text('店舗管理'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            final isDefault = store.id == 'default';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: store.color,
                radius: 16,
              ),
              title: Text(store.name),
              subtitle: isDefault ? const Text('デフォルト店舗') : null,
              trailing: isDefault
                  ? IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditStoreDialog(context, ref, store),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditStoreDialog(context, ref, store),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // シフトデータも削除
                            ref.read(shiftDateProvider.notifier).removeStore(store.id);
                            ref.read(storeProvider.notifier).removeStore(store.id);
                          },
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  void _showEditStoreDialog(BuildContext context, WidgetRef ref, Store store) {
    final controller = TextEditingController(text: store.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗名変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '店舗名',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(storeProvider.notifier)
                    .renameStore(store.id, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
