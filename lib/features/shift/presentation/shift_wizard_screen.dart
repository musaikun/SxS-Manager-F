import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/shift_date_provider.dart';
import '../providers/store_provider.dart';
import '../domain/models/store.dart';
import 'time_setting_screen.dart';

/// シフト登録ウィザード（3ページ構成）
/// Page 1: 日付選択
/// Page 2: 時間設定カード一覧
/// Page 3: 確認・提出
class ShiftWizardScreen extends ConsumerStatefulWidget {
  const ShiftWizardScreen({super.key});

  @override
  ConsumerState<ShiftWizardScreen> createState() => _ShiftWizardScreenState();
}

class _ShiftWizardScreenState extends ConsumerState<ShiftWizardScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ページ1: 日付選択の一時状態
  final Set<DateTime> _tempSelectedDates = {};
  String? _selectedStoreId;
  DateTime _focusedDay = DateTime.now();

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

    // ページ変更の監視は不要（onPageChangedで処理）
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ページ変更時の処理（重要：状態同期）
  void _syncDateSelectionToProvider() {
    print('🔄 _syncDateSelectionToProvider called');
    print('   _tempSelectedDates: ${_tempSelectedDates.length} dates');
    print('   _selectedStoreId: $_selectedStoreId');

    if (_tempSelectedDates.isEmpty || _selectedStoreId == null) {
      print('   ⚠️ Skipped: isEmpty=${_tempSelectedDates.isEmpty}, storeId=$_selectedStoreId');
      return;
    }

    // 一時選択状態をProviderに同期
    print('   ✅ Syncing to provider...');
    ref
        .read(shiftDateProvider.notifier)
        .addDates(_tempSelectedDates.toList(), _selectedStoreId!);
    print('   ✅ Sync completed');
  }

  // ページ移動（インジケーターからの移動用）
  void _jumpToPage(int page) {
    print('🔘 _jumpToPage: $_currentPage -> $page');

    // ページ1から離れる場合、Providerに同期
    if (_currentPage == 0 && page != 0) {
      print('   🔄 Triggering sync from page 0 (jumpTo)');
      _syncDateSelectionToProvider();
    }

    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ページインジケーター（タップ可能）
          _buildPageIndicator(),

          // PageView（3ページ）
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                print('📄 PageView onPageChanged: $_currentPage -> $page');

                // ページ1から離れる時、自動的にProviderに同期
                // 重要：_currentPageが更新される前にチェックする必要がある
                final wasOnDateSelection = _currentPage == 0;

                // _currentPageを更新
                setState(() {
                  _currentPage = page;
                });

                // ページ1から離れた場合のみ同期
                if (wasOnDateSelection && page != 0) {
                  print('   🔄 Triggering sync from page 0');
                  _syncDateSelectionToProvider();
                }
              },
              children: [
                // Page 1: 日付選択
                _DateSelectionPage(
                  tempSelectedDates: _tempSelectedDates,
                  selectedStoreId: _selectedStoreId,
                  focusedDay: _focusedDay,
                  onStoreChanged: (storeId) {
                    // 店舗切り替え前に、現在の一時選択をProviderに同期
                    print('🏪 Store changing: $_selectedStoreId -> $storeId');
                    _syncDateSelectionToProvider();

                    setState(() {
                      _selectedStoreId = storeId;
                      // 新しい店舗用の一時選択をクリア
                      _tempSelectedDates.clear();
                      print('   ✅ Cleared temp selection for new store');
                    });
                  },
                  onFocusedDayChanged: (day) {
                    setState(() {
                      _focusedDay = day;
                    });
                  },
                  onNext: () => _jumpToPage(1),
                ),

                // Page 2: 時間設定カード一覧
                _TimeSettingListPage(
                  onPrevious: () => _jumpToPage(0),
                  onNext: () => _jumpToPage(2),
                ),

                // Page 3: 確認・提出
                _ConfirmationPage(
                  onPrevious: () => _jumpToPage(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ページインジケーター
  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicatorDot(0, '日付選択'),
            _buildIndicatorLine(0),
            _buildIndicatorDot(1, '時間設定'),
            _buildIndicatorLine(1),
            _buildIndicatorDot(2, '確認'),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorDot(int page, String label) {
    final isActive = _currentPage == page;

    return InkWell(
      onTap: () => _jumpToPage(page),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${page + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorLine(int index) {
    final isActive = _currentPage > index;
    return Container(
      width: 40,
      height: 2,
      color: isActive
          ? Theme.of(context).colorScheme.primary
          : Colors.grey[300],
    );
  }
}

// ============================================================
// Page 1: 日付選択ページ
// ============================================================

class _DateSelectionPage extends ConsumerStatefulWidget {
  final Set<DateTime> tempSelectedDates;
  final String? selectedStoreId;
  final DateTime focusedDay;
  final ValueChanged<String?> onStoreChanged;
  final ValueChanged<DateTime> onFocusedDayChanged;
  final VoidCallback onNext;

  const _DateSelectionPage({
    required this.tempSelectedDates,
    required this.selectedStoreId,
    required this.focusedDay,
    required this.onStoreChanged,
    required this.onFocusedDayChanged,
    required this.onNext,
  });

  @override
  ConsumerState<_DateSelectionPage> createState() =>
      _DateSelectionPageState();
}

class _DateSelectionPageState extends ConsumerState<_DateSelectionPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

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

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  bool _isSelected(DateTime day) {
    final normalized = _normalizeDate(day);

    // Provider内にこの日付のシフトが存在するか、または一時選択されているか
    final hasShiftInProvider = ref
        .read(shiftDateProvider.notifier)
        .getShiftCountForDate(day) > 0;
    final isInTempSelection = widget.tempSelectedDates.contains(normalized);

    return hasShiftInProvider || isInTempSelection;
  }

  bool _isHoliday(DateTime day) {
    final normalized = _normalizeDate(day);
    return _holidays.containsKey(normalized);
  }

  bool _isWeekendOrHoliday(DateTime day) {
    return day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday ||
        _isHoliday(day);
  }

  bool _isWeekday(DateTime day) {
    return !_isWeekendOrHoliday(day);
  }

  void _toggleDate(DateTime day) {
    final today = _normalizeDate(DateTime.now());
    if (_normalizeDate(day).isBefore(today)) {
      print('⛔ Past date rejected: $day');
      return;
    }

    if (widget.selectedStoreId == null) {
      print('⚠️ No store selected');
      return;
    }

    setState(() {
      final normalized = _normalizeDate(day);
      final dateString = '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
      final uniqueKey = '${dateString}_${widget.selectedStoreId}';

      // 現在の店舗でこの日付のシフトが既にProviderに存在するかチェック
      final existingShift = ref.read(shiftDateProvider).firstWhere(
            (shift) => shift.uniqueKey == uniqueKey,
            orElse: () => null as dynamic,
          );

      if (existingShift != null) {
        // 既存のシフトを削除
        ref.read(shiftDateProvider.notifier).removeDate(uniqueKey);
        widget.tempSelectedDates.remove(normalized);
        print('➖ Removed shift: $uniqueKey from Provider');
      } else {
        // 一時選択に追加（ページ移動時にProviderに同期される）
        widget.tempSelectedDates.add(normalized);
        print('➕ Added date to temp: $normalized (total: ${widget.tempSelectedDates.length})');
      }
    });
  }

  void _toggleDatesWhere(bool Function(DateTime) condition) {
    if (widget.selectedStoreId == null) {
      print('⚠️ No store selected for batch operation');
      return;
    }

    setState(() {
      final dates = _getDatesInMonth(condition);
      final today = _normalizeDate(DateTime.now());
      final validDates = dates.where((d) => !d.isBefore(today)).toList();

      if (validDates.isEmpty) return;

      // 現在の店舗で、これらの日付が全て選択済みか確認
      final allSelected = validDates.every((date) {
        final dateString =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final uniqueKey = '${dateString}_${widget.selectedStoreId}';

        // Providerに存在するか、または一時選択されているか
        final existsInProvider = ref.read(shiftDateProvider).any(
              (shift) => shift.uniqueKey == uniqueKey,
            );
        final isInTemp = widget.tempSelectedDates.contains(date);

        return existsInProvider || isInTemp;
      });

      if (allSelected) {
        // 解除：Providerから削除 & 一時選択から削除
        for (final date in validDates) {
          final dateString =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final uniqueKey = '${dateString}_${widget.selectedStoreId}';

          // Providerから削除
          final existsInProvider = ref.read(shiftDateProvider).any(
                (shift) => shift.uniqueKey == uniqueKey,
              );
          if (existsInProvider) {
            ref.read(shiftDateProvider.notifier).removeDate(uniqueKey);
          }

          // 一時選択から削除
          widget.tempSelectedDates.remove(date);
        }
        print('➖ Batch removed ${validDates.length} dates');
      } else {
        // 選択：一時選択に追加（既にProviderにあるものは除外）
        for (final date in validDates) {
          final dateString =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final uniqueKey = '${dateString}_${widget.selectedStoreId}';

          final existsInProvider = ref.read(shiftDateProvider).any(
                (shift) => shift.uniqueKey == uniqueKey,
              );

          if (!existsInProvider) {
            widget.tempSelectedDates.add(date);
          }
        }
        print('➕ Batch added ${validDates.length} dates to temp');
      }
    });
  }

  List<DateTime> _getDatesInMonth(bool Function(DateTime) condition) {
    final firstDay =
        DateTime(widget.focusedDay.year, widget.focusedDay.month, 1);
    final lastDay =
        DateTime(widget.focusedDay.year, widget.focusedDay.month + 1, 0);

    final dates = <DateTime>[];
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      if (condition(day)) {
        dates.add(_normalizeDate(day));
      }
    }
    return dates;
  }

  void _toggleWeekday(int weekday) {
    _toggleDatesWhere((day) => day.weekday == weekday);
  }

  void _toggleWeekdays() {
    _toggleDatesWhere(_isWeekday);
  }

  void _toggleAllDays() {
    _toggleDatesWhere((day) => true);
  }

  void _toggleWeekendsAndHolidays() {
    _toggleDatesWhere(_isWeekendOrHoliday);
  }

  void _clearSelection() {
    setState(() {
      widget.tempSelectedDates.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storeProvider);
    final shiftDates = ref.watch(shiftDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日付選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () => _showStoreManageDialog(context),
            tooltip: '店舗管理',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStoreSelector(stores),
          const Divider(height: 1),
          _buildActionButtons(),
          const Divider(height: 1),
          _buildWeekdayButtons(),
          const Divider(height: 1),
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: widget.focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'ja_JP',
              selectedDayPredicate: (day) => _isSelected(day),
              enabledDayPredicate: (day) {
                final today = _normalizeDate(DateTime.now());
                return !_normalizeDate(day).isBefore(today);
              },
              onDaySelected: (selectedDay, focusedDay) {
                _toggleDate(selectedDay);
                widget.onFocusedDayChanged(focusedDay);
              },
              onPageChanged: (focusedDay) {
                // 月が変わったらfocusedDayを更新（重要：これがないと翌月の一括選択が機能しない）
                widget.onFocusedDayChanged(focusedDay);
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                weekendTextStyle: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
                outsideTextStyle: TextStyle(color: Colors.grey[400]),
                holidayTextStyle: const TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.w600,
                ),
                holidayDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(fontWeight: FontWeight.bold),
                weekendStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, day, focusedDay) {
                  final shifts =
                      ref.read(shiftDateProvider.notifier).getShiftsForDate(day);
                  final stores = ref.read(storeProvider);
                  final dotColors = [
                    Colors.red,
                    Colors.blue,
                    Colors.yellow,
                    Colors.green,
                  ];

                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (shifts.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: shifts.take(4).map((shift) {
                                final storeIndex = stores.indexWhere(
                                  (s) => s.id == shift.storeId,
                                );
                                final dotColor =
                                    storeIndex >= 0 && storeIndex < 4
                                        ? dotColors[storeIndex]
                                        : Colors.white;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, day, focusedDay) {
                  if (_isHoliday(day)) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.pink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  if (day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  if (day.weekday == DateTime.saturday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return null;
                },
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.7),
                ],
              ),
              border: const Border(top: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '選択: ${widget.tempSelectedDates.length}日',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSelector(List<Store> stores) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...stores.map((store) {
                final isSelected = widget.selectedStoreId == store.id;
                return ChoiceChip(
                  label: Text(store.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      widget.onStoreChanged(store.id);
                    }
                  },
                  selectedColor: store.color,
                  backgroundColor: store.color.withOpacity(0.15),
                  side: BorderSide(
                    color: isSelected
                        ? store.color
                        : store.color.withOpacity(0.3),
                    width: 2,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  elevation: isSelected ? 4 : 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }),
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

  Widget _buildWeekdayButtons() {
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final colors = [
      Colors.red,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.grey,
      Colors.blue,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
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

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _toggleWeekdays,
              icon: const Icon(Icons.business_center, size: 18),
              label: const Text('平日',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
              label: const Text('全日',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
              label: const Text('土日祝',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
              label: const Text('クリア',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
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
                final newStore =
                    ref.read(storeProvider.notifier).addStore(controller.text);
                widget.onStoreChanged(newStore.id);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showStoreManageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StoreManageDialog(),
    );
  }
}

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
                            ref
                                .read(shiftDateProvider.notifier)
                                .removeStore(store.id);
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

// ============================================================
// Page 2: 時間設定カード一覧
// ============================================================

class _TimeSettingListPage extends ConsumerWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _TimeSettingListPage({
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftDates = ref.watch(shiftDateProvider);
    final stores = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('時間設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onPrevious,
        ),
        actions: [
          TextButton(
            onPressed: onNext,
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
      body: shiftDates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '日付未選択',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '前のページで日付を選択してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shiftDates.length,
              itemBuilder: (context, index) {
                final shift = shiftDates[index];
                final store = stores.firstWhere(
                  (s) => s.id == shift.storeId,
                  orElse: () => stores.first,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: store.color,
                      child: Text(
                        shift.date.day.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${shift.date.year}/${shift.date.month}/${shift.date.day}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      shift.startTime != null && shift.endTime != null
                          ? '${shift.startTime} - ${shift.endTime}'
                          : '時間未設定',
                      style: TextStyle(
                        color: shift.startTime != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TimeSettingScreen(uniqueKey: shift.uniqueKey),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// Page 3: 確認・提出
// ============================================================

class _ConfirmationPage extends ConsumerWidget {
  final VoidCallback onPrevious;

  const _ConfirmationPage({
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftDates = ref.watch(shiftDateProvider);
    final stores = ref.watch(storeProvider);

    // 月ごとにグループ化
    final Map<String, List<dynamic>> groupedByMonth = {};
    for (final shift in shiftDates) {
      final key = '${shift.date.year}年${shift.date.month}月';
      groupedByMonth.putIfAbsent(key, () => []);
      groupedByMonth[key]!.add(shift);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('確認・提出'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onPrevious,
        ),
      ),
      body: shiftDates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'シフト未登録',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '日付と時間を設定してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: groupedByMonth.entries.map((entry) {
                      return _MonthAccordion(
                        monthLabel: entry.key,
                        shifts: entry.value,
                        stores: stores,
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('シフトを提出しました（※機能は未実装）'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        '提出する',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

class _MonthAccordion extends StatefulWidget {
  final String monthLabel;
  final List<dynamic> shifts;
  final List<Store> stores;

  const _MonthAccordion({
    required this.monthLabel,
    required this.shifts,
    required this.stores,
  });

  @override
  State<_MonthAccordion> createState() => _MonthAccordionState();
}

class _MonthAccordionState extends State<_MonthAccordion> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.monthLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${widget.shifts.length}件'),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            ...widget.shifts.map((shift) {
              final store = widget.stores.firstWhere(
                (s) => s.id == shift.storeId,
                orElse: () => widget.stores.first,
              );

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: store.color,
                  radius: 12,
                ),
                title: Text(
                  '${shift.date.month}/${shift.date.day} (${store.name})',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  shift.startTime != null && shift.endTime != null
                      ? '${shift.startTime} - ${shift.endTime}'
                      : '時間未設定',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
