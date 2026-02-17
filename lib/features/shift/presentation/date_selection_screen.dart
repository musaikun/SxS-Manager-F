import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
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
  final CalendarFormat _calendarFormat = CalendarFormat.month;

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
    // 過去の日付は選択できない
    final today = _normalizeDate(DateTime.now());
    if (_normalizeDate(day).isBefore(today)) {
      return;
    }

    setState(() {
      final normalized = _normalizeDate(day);
      if (_tempSelectedDates.contains(normalized)) {
        _tempSelectedDates.remove(normalized);
      } else {
        _tempSelectedDates.add(normalized);
      }
    });
  }

  // 共通: 条件に合う日付をトグル選択
  void _toggleDatesWhere(bool Function(DateTime) condition) {
    setState(() {
      final dates = _getDatesInMonth(condition);
      final today = _normalizeDate(DateTime.now());

      // 過去日付を除外（表示されている月でも過去は選択不可）
      final validDates = dates.where((d) => !d.isBefore(today)).toList();

      if (validDates.isEmpty) return;

      // 全部選択済みか確認
      final allSelected = validDates.every((d) => _tempSelectedDates.contains(d));

      if (allSelected) {
        // 解除
        validDates.forEach(_tempSelectedDates.remove);
      } else {
        // 選択
        _tempSelectedDates.addAll(validDates);
      }
    });
  }

  // 共通: 月内の日付を取得
  List<DateTime> _getDatesInMonth(bool Function(DateTime) condition) {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final dates = <DateTime>[];
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      if (condition(day)) {
        dates.add(_normalizeDate(day));
      }
    }
    return dates;
  }

  // 曜日別選択（月=1, 日=7）
  void _toggleWeekday(int weekday) {
    _toggleDatesWhere((day) => day.weekday == weekday);
  }

  // 平日トグル
  void _toggleWeekdays() {
    _toggleDatesWhere(_isWeekday);
  }

  // 全日トグル
  void _toggleAllDays() {
    _toggleDatesWhere((day) => true); // 全ての日付
  }

  // 土日祝日トグル
  void _toggleWeekendsAndHolidays() {
    _toggleDatesWhere(_isWeekendOrHoliday);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト日付選択'),
        centerTitle: true,
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
          // スクロール可能な上部エリア
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 店舗セレクター
                  _buildStoreSelector(stores),

                  const Divider(height: 1),

                  // アクションボタン（平日・全日・土日祝・クリア）
                  _buildActionButtons(),

                  const Divider(height: 1),

                  // 曜日別選択ボタン
                  _buildWeekdayButtons(),

                  const Divider(height: 1),

                  // カレンダー（固定高さ）
                  SizedBox(
                    height: 420,
                    child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'ja_JP',

              // 複数選択モード
              selectedDayPredicate: (day) => _isSelected(day),

              // 過去の日付を無効化
              enabledDayPredicate: (day) {
                final today = _normalizeDate(DateTime.now());
                return !_normalizeDate(day).isBefore(today);
              },

              // 日付タップ時の処理
              onDaySelected: (selectedDay, focusedDay) {
                _toggleDate(selectedDay);
                setState(() {
                  _focusedDay = focusedDay;
                });
              },

              // スワイプでの月移動を完全に無効化（矢印ボタンのみで操作）
              availableGestures: AvailableGestures.none,

              // カスタムヘッダー（矢印ボタン付き）
              headerVisible: true,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                leftChevronVisible: false,
                rightChevronVisible: false,
                titleCentered: true,
                headerPadding: EdgeInsets.zero,
              ),

              // カレンダースタイル
              calendarStyle: CalendarStyle(
                // 今日
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
                  shape: BoxShape.circle,
                ),
                // 選択された日（四角形に変更）
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                // 土曜日（青）
                weekendTextStyle: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
                // 日曜日（赤）- これはweekendに含まれるが、個別設定
                outsideTextStyle: TextStyle(color: Colors.grey[400]),
                // 祝日（ピンク）
                holidayTextStyle: const TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.w600,
                ),
                holidayDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),

              // 曜日のスタイル設定
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(fontWeight: FontWeight.bold),
                weekendStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // カスタムビルダーで日曜日を赤色に
              calendarBuilders: CalendarBuilders(
                // カスタムヘッダービルダー（矢印ボタン付き）
                headerTitleBuilder: (context, day) {
                  return _buildCustomHeader(day);
                },
                // 選択された日付のカスタム表示（四角形 + 店舗ドット + 時間帯）
                selectedBuilder: (context, day, focusedDay) {
                  // この日付にシフトが登録されている店舗を取得
                  final shifts = ref
                      .read(shiftDateProvider.notifier)
                      .getShiftsForDate(day);
                  final stores = ref.read(storeProvider);

                  // 時間が設定されているシフトを取得
                  final shiftsWithTime = shifts.where((s) => s.hasTime).toList();

                  // 表示する店舗のリストを作成（登録済み + 現在選択中）
                  final displayStoreIds = <String>{};
                  // 登録済みのシフトの店舗IDを追加
                  for (final shift in shifts) {
                    displayStoreIds.add(shift.storeId);
                  }
                  // 現在選択中の店舗IDを追加
                  if (_selectedStoreId != null) {
                    displayStoreIds.add(_selectedStoreId!);
                  }

                  // 店舗リストの順序に従ってフィルタリング（最大4つまで）
                  final displayStores = stores.where((s) => displayStoreIds.contains(s.id)).take(4).toList();

                  return Center(
                    child: Container(
                      width: 40,  // 固定幅
                      height: 40, // 固定高さ
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 時間帯リスト（時間が設定されている場合のみ）
                          if (shiftsWithTime.isNotEmpty) ...[
                            ...shiftsWithTime.take(4).map((shift) {
                              // 店舗の色を取得
                              final store = stores.firstWhere(
                                (s) => s.id == shift.storeId,
                                orElse: () => stores.first,
                              );
                              // 時間をフォーマット (例: 12:00 → 12)
                              final start = shift.startTime!.split(':')[0];
                              final end = shift.endTime!.split(':')[0];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: store.color == Colors.white
                                        ? Colors.blue.withValues(alpha:0.8)
                                        : store.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha:0.6),
                                        width: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$start-$end',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 2),
                          ],
                          // 日付
                          Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          // 店舗ドット（店舗リストの順序で表示）
                          if (displayStores.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            SizedBox(
                              height: 6,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: displayStores.map((store) {
                                  final dotColor = store.color;
                                  // 白ドットの場合は枠線を濃くする
                                  final isWhite = dotColor == Colors.white;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isWhite
                                            ? Colors.blue.withValues(alpha:0.8)
                                            : Colors.white.withValues(alpha:0.5),
                                        width: isWhite ? 1 : 0.5,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                // デフォルトの日付表示をカスタマイズ（ドット + 時間帯）
                defaultBuilder: (context, day, focusedDay) {
                  // この日付にシフトが登録されているか確認
                  final shifts = ref
                      .read(shiftDateProvider.notifier)
                      .getShiftsForDate(day);
                  final stores = ref.read(storeProvider);

                  // 表示する店舗IDのセットを作成
                  final displayStoreIds = <String>{};
                  for (final shift in shifts) {
                    displayStoreIds.add(shift.storeId);
                  }
                  // 店舗リストの順序に従ってフィルタリング
                  final displayStores = stores.where((s) => displayStoreIds.contains(s.id)).take(4).toList();

                  Color textColor = Colors.black;
                  // 祝日をピンク色に（最優先）
                  if (_isHoliday(day)) {
                    textColor = Colors.pink;
                  }
                  // 日曜日を赤色に
                  else if (day.weekday == DateTime.sunday) {
                    textColor = Colors.red;
                  }
                  // 土曜日を青色に
                  else if (day.weekday == DateTime.saturday) {
                    textColor = Colors.blue;
                  }

                  // 時間が設定されているシフトを取得
                  final shiftsWithTime = shifts.where((s) => s.hasTime).toList();

                  // シフトがある場合はドット付きで表示
                  if (shifts.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 時間帯リスト（時間が設定されている場合のみ）
                          if (shiftsWithTime.isNotEmpty) ...[
                            ...shiftsWithTime.take(4).map((shift) {
                              // 店舗の色を取得
                              final store = stores.firstWhere(
                                (s) => s.id == shift.storeId,
                                orElse: () => stores.first,
                              );
                              // 時間をフォーマット (例: 12:00 → 12)
                              final start = shift.startTime!.split(':')[0];
                              final end = shift.endTime!.split(':')[0];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: store.color == Colors.white
                                        ? Colors.white
                                        : store.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: store.color == Colors.white
                                            ? Colors.blue.shade400
                                            : store.color.withValues(alpha:0.5),
                                        width: store.color == Colors.white ? 0.5 : 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$start-$end',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 1),
                          ],
                          // 日付
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 1),
                          // 店舗ドット（店舗リストの順序で表示）
                          SizedBox(
                            height: 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: displayStores.map((store) {
                                final dotColor = store.color;
                                final isWhite = dotColor == Colors.white;

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isWhite
                                          ? Colors.blue.shade400
                                          : dotColor.withValues(alpha:0.3),
                                      width: isWhite ? 1.0 : 0.8,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // シフトがない場合は通常表示
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
                // 過去の日付を無効化
                disabledBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // 選択数表示（統一デザイン）
          Container(
            padding: const EdgeInsets.all(12),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '選択: ${_tempSelectedDates.length}日',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 店舗セレクター
  Widget _buildStoreSelector(List<Store> stores) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                '勤務先を選択',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...stores.map((store) {
                final isSelected = _selectedStoreId == store.id;
                // 白色の場合は特別な処理
                final isWhite = store.color == Colors.white;
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
                  selectedColor: isWhite ? Colors.grey[300] : store.color,
                  backgroundColor: isWhite ? Colors.white : store.color.withValues(alpha:0.15),
                  side: BorderSide(
                    color: isWhite
                        ? (isSelected ? Colors.grey[600]! : Colors.grey[400]!)
                        : (isSelected ? store.color : store.color.withValues(alpha:0.3)),
                    width: isSelected ? 2.5 : 2,
                  ),
                  labelStyle: TextStyle(
                    color: isWhite
                        ? Colors.black87
                        : (isSelected ? Colors.white : Colors.black87),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  elevation: isSelected ? 4 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }),
              // 店舗追加ボタン（最大4店舗まで）
              if (stores.length < 4)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text(
                    '店舗追加',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showAddStoreDialog(context),
                  elevation: 2,
                  backgroundColor: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 曜日別選択ボタン
  Widget _buildWeekdayButtons() {
    // 日曜日始まりに変更
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final colors = [
      Colors.red,    // 日
      Colors.grey,   // 月
      Colors.grey,   // 火
      Colors.grey,   // 水
      Colors.grey,   // 木
      Colors.grey,   // 金
      Colors.blue,   // 土
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: List.generate(7, (index) {
          // DateTime.sunday=7, Monday=1なので、日曜は7、月〜土は1〜6
          final weekday = index == 0 ? DateTime.sunday : index;
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

  // アクションボタン（トグル式）
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleWeekdays,
              icon: const Icon(Icons.business_center, size: 18),
              label: const Text('平日', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleAllDays,
              icon: const Icon(Icons.calendar_month, size: 18),
              label: const Text('全日', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleWeekendsAndHolidays,
              icon: const Icon(Icons.weekend, size: 18),
              label: const Text('土日祝', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear, size: 18, color: Colors.red),
              label: const Text('クリア', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.red, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

  // カスタムヘッダー（矢印ボタン付き）
  Widget _buildCustomHeader(DateTime focusedDay) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final displayMonth = DateTime(focusedDay.year, focusedDay.month);

    // 過去の月かどうかチェック
    final isPastMonth = displayMonth.isBefore(currentMonth);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 前月ボタン
          Container(
            decoration: BoxDecoration(
              color: isPastMonth ? Colors.grey.shade100 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPastMonth ? Colors.grey.shade300 : Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 28,
                color: isPastMonth ? Colors.grey.shade400 : Colors.blue.shade700,
              ),
              onPressed: isPastMonth
                  ? null  // 過去の月の場合は無効化
                  : () {
                      final previousMonth = DateTime(
                        focusedDay.year,
                        focusedDay.month - 1,
                      );
                      // 過去の月には移動できない
                      if (!DateTime(previousMonth.year, previousMonth.month)
                          .isBefore(currentMonth)) {
                        setState(() {
                          _focusedDay = previousMonth;
                        });
                      }
                    },
            ),
          ),

          // 月表示（中央配置）
          Expanded(
            child: Center(
              child: Text(
                '${focusedDay.year}年 ${focusedDay.month}月',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // 次月ボタン
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_right,
                size: 28,
                color: Colors.blue.shade700,
              ),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(
                    focusedDay.year,
                    focusedDay.month + 1,
                  );
                });
              },
            ),
          ),
        ],
      ),
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
