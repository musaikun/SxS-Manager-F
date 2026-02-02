import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/shift_date_provider.dart';
import '../providers/store_provider.dart';
import '../domain/models/store.dart';
import '../utils/date_utils.dart';
import '../utils/time_utils.dart';
import '../constants/shift_constants.dart';
import 'time_setting_screen.dart';
import 'widgets/time_setting_modal.dart';

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
  DateTime _focusedDay = DateTime.now();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ページ変更時の処理（重要：状態同期）
  void _syncDateSelectionToProvider() {
    // デフォルト店舗を取得
    final defaultStore = ref.read(defaultStoreProvider);
    final currentShifts = ref.read(shiftDateProvider);

    // 既存のシフト（デフォルト店舗のみ）の日付と時間情報をマップで保持
    final Map<DateTime, dynamic> existingShifts = {};
    for (final shift in currentShifts) {
      if (shift.storeId == defaultStore.id) {
        final normalized = ShiftDateUtils.normalizeDate(shift.date);
        existingShifts[normalized] = shift;
      }
    }

    // 削除すべき日付を特定（既存にあるが_tempSelectedDatesにない）
    final datesToRemove = existingShifts.keys
        .where((date) => !_tempSelectedDates.contains(date))
        .toList();

    // 追加すべき日付を特定（_tempSelectedDatesにあるが既存にない）
    final datesToAdd = _tempSelectedDates
        .where((date) => !existingShifts.containsKey(date))
        .toList();

    // 削除
    for (final date in datesToRemove) {
      final shift = existingShifts[date]!;
      ref.read(shiftDateProvider.notifier).removeDate(shift.uniqueKey);
    }

    // 追加（新規シフトのみ、既存のシフトの時間情報は保持される）
    if (datesToAdd.isNotEmpty) {
      ref
          .read(shiftDateProvider.notifier)
          .addDates(datesToAdd.toList(), defaultStore.id);
    }
  }

  // ページ移動（インジケーターからの移動用）
  void _jumpToPage(int page) {
    // ページ1から離れる場合、Providerに同期
    if (_currentPage == 0 && page != 0) {
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
                // ページ1から離れる時、自動的にProviderに同期
                final wasOnDateSelection = _currentPage == 0;

                // _currentPageを更新
                setState(() {
                  _currentPage = page;
                });

                // ページ1から離れた場合のみ同期
                if (wasOnDateSelection && page != 0) {
                  _syncDateSelectionToProvider();
                }
              },
              children: [
                // Page 1: 日付選択
                _DateSelectionPage(
                  tempSelectedDates: _tempSelectedDates,
                  focusedDay: _focusedDay,
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
// Page 1: 日付選択ページ（シンプル版）
// ============================================================

class _DateSelectionPage extends ConsumerStatefulWidget {
  final Set<DateTime> tempSelectedDates;
  final DateTime focusedDay;
  final ValueChanged<DateTime> onFocusedDayChanged;
  final VoidCallback onNext;

  const _DateSelectionPage({
    required this.tempSelectedDates,
    required this.focusedDay,
    required this.onFocusedDayChanged,
    required this.onNext,
  });

  @override
  ConsumerState<_DateSelectionPage> createState() =>
      _DateSelectionPageState();
}

class _DateSelectionPageState extends ConsumerState<_DateSelectionPage> {
  late PageController _calendarPageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _calendarPageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _calendarPageController.dispose();
    super.dispose();
  }

  bool _isSelected(DateTime day) {
    final normalized = ShiftDateUtils.normalizeDate(day);
    return widget.tempSelectedDates.contains(normalized);
  }

  bool _isHoliday(DateTime day) {
    return JapaneseHolidays.isHoliday(day);
  }

  bool _isWeekendOrHoliday(DateTime day) {
    return ShiftDateUtils.isWeekendOrHoliday(day);
  }

  bool _isWeekday(DateTime day) {
    return ShiftDateUtils.isWeekday(day);
  }

  // 日付の選択/解除（トグル）
  void _toggleDate(DateTime day) {
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    if (ShiftDateUtils.normalizeDate(day).isBefore(today)) return;

    setState(() {
      final normalized = ShiftDateUtils.normalizeDate(day);
      if (widget.tempSelectedDates.contains(normalized)) {
        widget.tempSelectedDates.remove(normalized);
      } else {
        widget.tempSelectedDates.add(normalized);
      }
    });
  }

  // 共通: 条件に合う日付をトグル選択
  void _toggleDatesWhere(bool Function(DateTime) condition) {
    setState(() {
      final dates = _getDatesInMonth(condition);
      final today = ShiftDateUtils.normalizeDate(DateTime.now());

      // 過去日付を除外（表示されている月でも過去は選択不可）
      final validDates = dates.where((d) => !d.isBefore(today)).toList();

      if (validDates.isEmpty) return;

      // 全部選択済みか確認
      final allSelected =
          validDates.every((d) => widget.tempSelectedDates.contains(d));

      if (allSelected) {
        // 解除
        validDates.forEach(widget.tempSelectedDates.remove);
      } else {
        // 選択
        widget.tempSelectedDates.addAll(validDates);
      }
    });
  }

  // 共通: 月内の日付を取得
  List<DateTime> _getDatesInMonth(bool Function(DateTime) condition) {
    final firstDay =
        DateTime(widget.focusedDay.year, widget.focusedDay.month, 1);
    final lastDay =
        DateTime(widget.focusedDay.year, widget.focusedDay.month + 1, 0);

    final dates = <DateTime>[];
    for (int i = 0; i < lastDay.day; i++) {
      final day = firstDay.add(Duration(days: i));
      if (condition(day)) {
        dates.add(ShiftDateUtils.normalizeDate(day));
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

  // 該当する曜日が全て選択されているかチェック
  bool _isWeekdayFullySelected(int weekday) {
    final dates = _getDatesInMonth((day) => day.weekday == weekday);
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    final validDates = dates.where((d) => !d.isBefore(today)).toList();
    if (validDates.isEmpty) return false;
    return validDates.every((d) => widget.tempSelectedDates.contains(d));
  }

  // 平日が全て選択されているかチェック
  bool _isWeekdaysFullySelected() {
    final dates = _getDatesInMonth(_isWeekday);
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    final validDates = dates.where((d) => !d.isBefore(today)).toList();
    if (validDates.isEmpty) return false;
    return validDates.every((d) => widget.tempSelectedDates.contains(d));
  }

  // 土日祝が全て選択されているかチェック
  bool _isWeekendsAndHolidaysFullySelected() {
    final dates = _getDatesInMonth(_isWeekendOrHoliday);
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    final validDates = dates.where((d) => !d.isBefore(today)).toList();
    if (validDates.isEmpty) return false;
    return validDates.every((d) => widget.tempSelectedDates.contains(d));
  }

  // 全日が選択されているかチェック
  bool _isAllDaysFullySelected() {
    final dates = _getDatesInMonth((day) => true);
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    final validDates = dates.where((d) => !d.isBefore(today)).toList();
    if (validDates.isEmpty) return false;
    return validDates.every((d) => widget.tempSelectedDates.contains(d));
  }

  // 第〇週の日付をトグル選択
  void _toggleWeekOfMonth(int week) {
    _toggleDatesWhere((day) => ShiftDateUtils.getWeekOfMonth(day) == week);
  }

  // 第〇週が全て選択されているかチェック
  bool _isWeekOfMonthFullySelected(int week) {
    final dates = _getDatesInMonth((day) => ShiftDateUtils.getWeekOfMonth(day) == week);
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    final validDates = dates.where((d) => !d.isBefore(today)).toList();
    if (validDates.isEmpty) return false;
    return validDates.every((d) => widget.tempSelectedDates.contains(d));
  }

  // 第〇週が存在するかチェック（過去日を除く）
  bool _hasWeekOfMonth(int week) {
    final dates = _getDatesInMonth((day) => ShiftDateUtils.getWeekOfMonth(day) == week);
    final today = ShiftDateUtils.normalizeDate(DateTime.now());
    final validDates = dates.where((d) => !d.isBefore(today)).toList();
    return validDates.isNotEmpty;
  }

  // 該当日付のシフト情報を取得
  String? _getTimeInfo(DateTime day) {
    final normalized = ShiftDateUtils.normalizeDate(day);
    final shiftDates = ref.read(shiftDateProvider);

    // 該当する日付のシフトを探す
    for (final shift in shiftDates) {
      final shiftDate = ShiftDateUtils.normalizeDate(shift.date);
      if (shiftDate == normalized) {
        // 時間が設定されている場合のみ表示
        if (shift.startTime != null && shift.endTime != null) {
          // "HH:MM" から "HH" を抽出
          final startHour = shift.startTime!.split(':')[0];
          final endHour = shift.endTime!.split(':')[0];
          return '$startHour-$endHour';
        }
        break;
      }
    }
    return null;
  }

  // 表示する月のリストを生成（現在月から3ヶ月先まで）
  List<DateTime> _generateMonthsList() {
    final now = DateTime.now();
    final List<DateTime> months = [];
    for (int i = 0; i < 4; i++) {
      months.add(DateTime(now.year, now.month + i, 1));
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final monthsList = _generateMonthsList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('出勤日を選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // アクションボタン（平日・全日・土日祝・クリア）
          _buildActionButtons(),

          const Divider(height: 1),

          // 曜日別選択ボタン
          _buildWeekdayButtons(),

          const Divider(height: 1),

          // 週別選択ボタン
          _buildWeekButtons(),

          const Divider(height: 1),

          // スワイプヒント
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '上下にスワイプで月を移動',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_downward, size: 16, color: Colors.grey[600]),
              ],
            ),
          ),

          const Divider(height: 1),

          // カレンダー（縦PageView）
          Expanded(
            child: PageView.builder(
              controller: _calendarPageController,
              scrollDirection: Axis.vertical,
              itemCount: monthsList.length,
              onPageChanged: (index) {
                final newMonth = monthsList[index];
                setState(() {
                  _currentPageIndex = index;
                });
                // focusedDayを現在の月に更新（一括選択ボタンが正しく動作するように）
                widget.onFocusedDayChanged(newMonth);
              },
              itemBuilder: (context, index) {
                final month = monthsList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TableCalendar(
                    firstDay: month,
                    lastDay: DateTime(month.year, month.month + 1, 0),
                    focusedDay: month,
                    calendarFormat: CalendarFormat.month,
                    locale: 'ja_JP',
                    availableGestures: AvailableGestures.none,
                    selectedDayPredicate: (day) => _isSelected(day),
                    enabledDayPredicate: (day) {
                      final today = ShiftDateUtils.normalizeDate(DateTime.now());
                      return !ShiftDateUtils.normalizeDate(day).isBefore(today);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      _toggleDate(selectedDay);
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      leftChevronVisible: false,
                      rightChevronVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              calendarStyle: CalendarStyle(
                // デフォルト（薄いグレーの背景）
                defaultDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                // 今日（他の日と同じ薄いグレー）
                todayDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                // 選択された日（緑色・四角形・リップルエフェクト風）
                selectedDecoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                // 土曜日（青）
                weekendTextStyle: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
                // 土日も薄いグレーの背景
                weekendDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                outsideTextStyle: TextStyle(color: Colors.grey[400]),
                // 祝日（ピンク）
                holidayTextStyle: const TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.w600,
                ),
                // 祝日も薄いグレーの背景
                holidayDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
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
                // 選択された日付のカスタム表示
                selectedBuilder: (context, day, focusedDay) {
                  final timeInfo = _getTimeInfo(day);

                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (timeInfo != null) ...[
                            Text(
                              timeInfo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                // 今日の日付表示
                todayBuilder: (context, day, focusedDay) {
                  Color textColor = Colors.black;
                  final timeInfo = _getTimeInfo(day);

                  // 祝日はピンク色
                  if (_isHoliday(day)) {
                    textColor = Colors.pink;
                  }
                  // 日曜日は赤色
                  else if (day.weekday == DateTime.sunday) {
                    textColor = Colors.red;
                  }
                  // 土曜日は青色
                  else if (day.weekday == DateTime.saturday) {
                    textColor = Colors.blue;
                  }

                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (timeInfo != null) ...[
                            Text(
                              timeInfo,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                // デフォルトの日付表示をカスタマイズ
                defaultBuilder: (context, day, focusedDay) {
                  Color textColor = Colors.black;
                  final timeInfo = _getTimeInfo(day);

                  // 祝日はピンク色
                  if (_isHoliday(day)) {
                    textColor = Colors.pink;
                  }
                  // 日曜日は赤色
                  else if (day.weekday == DateTime.sunday) {
                    textColor = Colors.red;
                  }
                  // 土曜日は青色
                  else if (day.weekday == DateTime.saturday) {
                    textColor = Colors.blue;
                  }

                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (timeInfo != null) ...[
                            Text(
                              timeInfo,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                // 過去の日付を無効化
                disabledBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 選択数表示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade50,
                ],
              ),
              border:
                  const Border(top: BorderSide(color: Colors.grey, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ページインジケーター
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: List.generate(_generateMonthsList().length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPageIndex == index
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),
                ),
                // 選択数表示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '選択: ${widget.tempSelectedDates.length}日',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                // 右側のスペーサー
                const SizedBox(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayButtons() {
    // 日曜日始まりに変更
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    final colors = [
      Colors.red, // 日
      Colors.grey, // 月
      Colors.grey, // 火
      Colors.grey, // 水
      Colors.grey, // 木
      Colors.grey, // 金
      Colors.blue, // 土
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          // DateTime.sunday=7, Monday=1なので、日曜は7、月〜土は1〜6
          final weekday = index == 0 ? DateTime.sunday : index;
          final isFullySelected = _isWeekdayFullySelected(weekday);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: OutlinedButton(
                onPressed: () => _toggleWeekday(weekday),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  side: BorderSide(color: isFullySelected ? Colors.green : colors[index]),
                  backgroundColor: isFullySelected ? Colors.green : null,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 12,
                    color: isFullySelected ? Colors.white : colors[index],
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

  Widget _buildWeekButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: List.generate(5, (index) {
          final week = index + 1; // 第1週〜第5週
          final isFullySelected = _isWeekOfMonthFullySelected(week);
          final hasWeek = _hasWeekOfMonth(week);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: OutlinedButton(
                onPressed: hasWeek ? () => _toggleWeekOfMonth(week) : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  side: BorderSide(
                    color: !hasWeek
                        ? Colors.grey.shade300
                        : (isFullySelected ? Colors.green : Colors.grey),
                  ),
                  backgroundColor: isFullySelected ? Colors.green : null,
                  minimumSize: const Size(0, 0),
                ),
                child: Text(
                  '第${week}週',
                  style: TextStyle(
                    fontSize: 11,
                    color: !hasWeek
                        ? Colors.grey.shade400
                        : (isFullySelected ? Colors.white : Colors.black),
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
    final isWeekdaysSelected = _isWeekdaysFullySelected();
    final isAllDaysSelected = _isAllDaysFullySelected();
    final isWeekendsSelected = _isWeekendsAndHolidaysFullySelected();

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
                backgroundColor: isWeekdaysSelected ? Colors.green : null,
                foregroundColor: isWeekdaysSelected ? Colors.white : null,
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
                backgroundColor: isAllDaysSelected ? Colors.green : null,
                foregroundColor: isAllDaysSelected ? Colors.white : null,
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
                backgroundColor: isWeekendsSelected ? Colors.green : null,
                foregroundColor: isWeekendsSelected ? Colors.white : null,
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
}

// ============================================================
// Page 2: 時間設定カード一覧
// ============================================================

class _TimeSettingListPage extends ConsumerStatefulWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _TimeSettingListPage({
    required this.onPrevious,
    required this.onNext,
  });

  @override
  ConsumerState<_TimeSettingListPage> createState() =>
      _TimeSettingListPageState();
}

class _TimeSettingListPageState extends ConsumerState<_TimeSettingListPage>
    with TickerProviderStateMixin {
  final Set<String> _selectedUniqueKeys = {};
  bool _isBatchSelectionExpanded = false; // アコーディオンの開閉状態
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late AnimationController _accordionController;
  late Animation<double> _accordionRotation;

  @override
  void initState() {
    super.initState();
    // ブリンクアニメーションの初期化（1.5秒周期でゆっくり点滅）
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // アコーディオンアニメーションの初期化
    _accordionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _accordionRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _accordionController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _accordionController.dispose();
    super.dispose();
  }

  bool _isWeekendOrHoliday(DateTime day) {
    return ShiftDateUtils.isWeekendOrHoliday(day);
  }

  bool _isWeekday(DateTime day) {
    return ShiftDateUtils.isWeekday(day);
  }

  // 曜日別選択
  void _selectByWeekday(int weekday) {
    setState(() {
      final shiftDates = ref.read(shiftDateProvider);
      final keys = shiftDates
          .where((shift) => shift.date.weekday == weekday)
          .map((s) => s.uniqueKey)
          .toList();

      // トグル動作
      final allSelected = keys.every((k) => _selectedUniqueKeys.contains(k));
      if (allSelected) {
        _selectedUniqueKeys.removeAll(keys);
      } else {
        _selectedUniqueKeys.addAll(keys);
      }
    });
  }

  // 平日のみ選択
  void _selectWeekdays() {
    setState(() {
      final shiftDates = ref.read(shiftDateProvider);
      final keys = shiftDates
          .where((shift) => _isWeekday(shift.date))
          .map((s) => s.uniqueKey)
          .toList();

      // トグル動作
      final allSelected = keys.every((k) => _selectedUniqueKeys.contains(k));
      if (allSelected) {
        _selectedUniqueKeys.removeAll(keys);
      } else {
        _selectedUniqueKeys.addAll(keys);
      }
    });
  }

  // 土日祝日選択
  void _selectWeekendsAndHolidays() {
    setState(() {
      final shiftDates = ref.read(shiftDateProvider);
      final keys = shiftDates
          .where((shift) => _isWeekendOrHoliday(shift.date))
          .map((s) => s.uniqueKey)
          .toList();

      // トグル動作
      final allSelected = keys.every((k) => _selectedUniqueKeys.contains(k));
      if (allSelected) {
        _selectedUniqueKeys.removeAll(keys);
      } else {
        _selectedUniqueKeys.addAll(keys);
      }
    });
  }

  // 第〇週選択
  void _selectByWeekOfMonth(int week) {
    setState(() {
      final shiftDates = ref.read(shiftDateProvider);
      final keys = shiftDates
          .where((shift) => ShiftDateUtils.getWeekOfMonth(shift.date) == week)
          .map((s) => s.uniqueKey)
          .toList();

      // トグル動作
      final allSelected = keys.every((k) => _selectedUniqueKeys.contains(k));
      if (allSelected) {
        _selectedUniqueKeys.removeAll(keys);
      } else {
        _selectedUniqueKeys.addAll(keys);
      }
    });
  }

  // 該当する曜日が全て選択されているかチェック
  bool _isWeekdayFullySelected(int weekday) {
    final shiftDates = ref.read(shiftDateProvider);
    final keys = shiftDates
        .where((shift) => shift.date.weekday == weekday)
        .map((s) => s.uniqueKey)
        .toList();
    if (keys.isEmpty) return false;
    return keys.every((k) => _selectedUniqueKeys.contains(k));
  }

  // 平日が全て選択されているかチェック
  bool _isWeekdaysFullySelected() {
    final shiftDates = ref.read(shiftDateProvider);
    final keys = shiftDates
        .where((shift) => _isWeekday(shift.date))
        .map((s) => s.uniqueKey)
        .toList();
    if (keys.isEmpty) return false;
    return keys.every((k) => _selectedUniqueKeys.contains(k));
  }

  // 土日祝が全て選択されているかチェック
  bool _isWeekendsAndHolidaysFullySelected() {
    final shiftDates = ref.read(shiftDateProvider);
    final keys = shiftDates
        .where((shift) => _isWeekendOrHoliday(shift.date))
        .map((s) => s.uniqueKey)
        .toList();
    if (keys.isEmpty) return false;
    return keys.every((k) => _selectedUniqueKeys.contains(k));
  }

  // 第〇週が全て選択されているかチェック
  bool _isWeekOfMonthFullySelected(int week) {
    final shiftDates = ref.read(shiftDateProvider);
    final keys = shiftDates
        .where((shift) => ShiftDateUtils.getWeekOfMonth(shift.date) == week)
        .map((s) => s.uniqueKey)
        .toList();
    if (keys.isEmpty) return false;
    return keys.every((k) => _selectedUniqueKeys.contains(k));
  }

  // =========== 選択可能な項目が存在するかチェック ===========

  // 該当する曜日のシフトが存在するかチェック
  bool _hasWeekday(int weekday) {
    final shiftDates = ref.read(shiftDateProvider);
    return shiftDates.any((shift) => shift.date.weekday == weekday);
  }

  // 平日のシフトが存在するかチェック
  bool _hasWeekdays() {
    final shiftDates = ref.read(shiftDateProvider);
    return shiftDates.any((shift) =>
        shift.date.weekday >= DateTime.monday &&
        shift.date.weekday <= DateTime.friday);
  }

  // 土日祝のシフトが存在するかチェック
  bool _hasWeekendsOrHolidays() {
    final shiftDates = ref.read(shiftDateProvider);
    return shiftDates.any((shift) =>
        shift.date.weekday == DateTime.saturday ||
        shift.date.weekday == DateTime.sunday ||
        JapaneseHolidays.isHoliday(shift.date));
  }

  // 該当する週のシフトが存在するかチェック
  bool _hasWeekOfMonth(int week) {
    final shiftDates = ref.read(shiftDateProvider);
    return shiftDates.any((shift) => ShiftDateUtils.getWeekOfMonth(shift.date) == week);
  }

  // 時間未設定のシフトが存在するかチェック
  bool _hasUnsetTimes() {
    final shiftDates = ref.read(shiftDateProvider);
    return shiftDates.any((shift) => shift.startTime == null || shift.endTime == null);
  }

  // 全選択状態かチェック
  bool _isAllSelected() {
    final shiftDates = ref.read(shiftDateProvider);
    if (shiftDates.isEmpty) return false;
    return _selectedUniqueKeys.length == shiftDates.length;
  }

  // 未設定のシフトが全て選択されているかチェック
  bool _isUnsetTimesFullySelected() {
    final shiftDates = ref.read(shiftDateProvider);
    final unsetKeys = shiftDates
        .where((shift) => shift.startTime == null || shift.endTime == null)
        .map((s) => s.uniqueKey)
        .toSet();
    if (unsetKeys.isEmpty) return false;
    return unsetKeys.every((k) => _selectedUniqueKeys.contains(k));
  }

  // 時間未設定のシフトをトグル選択
  void _selectUnsetTimes() {
    setState(() {
      final shiftDates = ref.read(shiftDateProvider);
      final unsetKeys = shiftDates
          .where((shift) => shift.startTime == null || shift.endTime == null)
          .map((s) => s.uniqueKey)
          .toList();

      // トグル動作
      if (_isUnsetTimesFullySelected()) {
        _selectedUniqueKeys.removeAll(unsetKeys);
      } else {
        _selectedUniqueKeys.addAll(unsetKeys);
      }
    });
  }

  // 統計情報を計算
  Map<String, dynamic> _calculateStatistics(List<dynamic> shifts) {
    int totalDays = shifts.length;
    double totalHours = 0;
    double totalActualHours = 0; // 休憩時間を差し引いた実労働時間
    int daysWithTime = 0;

    for (final shift in shifts) {
      final hours = TimeUtils.calculateWorkHours(shift.startTime, shift.endTime);
      if (hours != null) {
        totalHours += hours;
        final actualHours = TimeUtils.calculateActualWorkHours(shift.startTime, shift.endTime);
        if (actualHours != null) {
          totalActualHours += actualHours;
        }
        daysWithTime++;
      }
    }

    return {
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalActualHours': totalActualHours,
      'daysWithTime': daysWithTime,
    };
  }


  void _showBatchTimeSettingDialog() async {
    if (_selectedUniqueKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日付を選択してください')),
      );
      return;
    }

    // 一括設定用のモーダルを表示
    final result = await showDialog<TimeSettingResult>(
      context: context,
      builder: (context) => TimeSettingModal(
        title: '一括時間設定（${_selectedUniqueKeys.length}件）',
        showMemoField: true,
      ),
    );

    if (result != null) {
      // 選択されたシフトに一括で時間と備考を設定
      ref.read(shiftDateProvider.notifier).updateMultipleTimesAndMemo(
            _selectedUniqueKeys.toList(),
            result.startTime,
            result.endTime,
            result.memo,
          );

      final count = _selectedUniqueKeys.length;
      setState(() {
        _selectedUniqueKeys.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${count}件の時間を設定しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftDates = ref.watch(shiftDateProvider);
    final stores = ref.watch(storeProvider);
    final stats = _calculateStatistics(shiftDates);
    final hasUnsetTimes = shiftDates.any((s) => s.startTime == null || s.endTime == null);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('時間設定', style: TextStyle(fontSize: 18)),
            if (hasUnsetTimes)
              const Text(
                '⚠ 時間未設定の日あり',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
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
          : Column(
              children: [
                // 統計情報表示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade100,
                        Colors.green.shade50,
                      ],
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.calendar_today,
                            '合計勤務日数',
                            '${stats['totalDays']}日',
                          ),
                          _buildStatItem(
                            Icons.access_time,
                            '実労働時間',
                            '${stats['totalActualHours'].toStringAsFixed(1)}時間',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '※休憩時間を差し引いています（労働基準法に基づく）',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                // 一括設定アコーディオン
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // アコーディオンヘッダー
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isBatchSelectionExpanded = !_isBatchSelectionExpanded;
                            if (_isBatchSelectionExpanded) {
                              _accordionController.forward();
                            } else {
                              _accordionController.reverse();
                              _selectedUniqueKeys.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isBatchSelectionExpanded
                                ? Colors.green.shade50
                                : Colors.grey.shade50,
                            borderRadius: _isBatchSelectionExpanded
                                ? const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  )
                                : BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.playlist_add_check,
                                color: _isBatchSelectionExpanded
                                    ? Colors.green
                                    : Colors.grey[700],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _isBatchSelectionExpanded
                                      ? '一括時間設定 (${_selectedUniqueKeys.length}件選択中)'
                                      : '一括時間設定',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isBatchSelectionExpanded
                                        ? Colors.green
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                              RotationTransition(
                                turns: _accordionRotation,
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  size: 32,
                                  color: _isBatchSelectionExpanded
                                      ? Colors.green
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // アコーディオンコンテンツ
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _isBatchSelectionExpanded
                            ? Column(
                                children: [
                  // 全選択、未設定選択、クリア、時間設定ボタン
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: shiftDates.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      if (_isAllSelected()) {
                                        _selectedUniqueKeys.clear();
                                      } else {
                                        _selectedUniqueKeys.clear();
                                        _selectedUniqueKeys.addAll(
                                            shiftDates.map((s) => s.uniqueKey));
                                      }
                                    });
                                  },
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('全選択', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _isAllSelected() ? Colors.green : null,
                              foregroundColor: _isAllSelected() ? Colors.white : null,
                              side: BorderSide(
                                color: shiftDates.isEmpty
                                    ? Colors.grey.shade300
                                    : (_isAllSelected() ? Colors.green : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _hasUnsetTimes() ? _selectUnsetTimes : null,
                            icon: const Icon(Icons.schedule, size: 16),
                            label: const Text('未設定', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _isUnsetTimesFullySelected() ? Colors.orange : null,
                              foregroundColor: _isUnsetTimesFullySelected() ? Colors.white : Colors.orange,
                              side: BorderSide(
                                color: !_hasUnsetTimes()
                                    ? Colors.grey.shade300
                                    : (_isUnsetTimesFullySelected() ? Colors.orange : Colors.orange),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selectedUniqueKeys.isEmpty
                                ? null
                                : () {
                                    setState(() {
                                      _selectedUniqueKeys.clear();
                                    });
                                  },
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('クリア', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _selectedUniqueKeys.isEmpty
                                  ? null
                                  : Colors.red,
                              side: BorderSide(
                                color: _selectedUniqueKeys.isEmpty
                                    ? Colors.grey
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _selectedUniqueKeys.isEmpty
                                ? null
                                : _showBatchTimeSettingDialog,
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(
                                '時間設定 (${_selectedUniqueKeys.length})',
                                style: const TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedUniqueKeys.isEmpty
                                  ? null
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 曜日別選択ボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '曜日別選択',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildWeekdayButton('日', DateTime.sunday, Colors.red),
                            _buildWeekdayButton('月', DateTime.monday, Colors.grey),
                            _buildWeekdayButton('火', DateTime.tuesday, Colors.grey),
                            _buildWeekdayButton('水', DateTime.wednesday, Colors.grey),
                            _buildWeekdayButton('木', DateTime.thursday, Colors.grey),
                            _buildWeekdayButton('金', DateTime.friday, Colors.grey),
                            _buildWeekdayButton('土', DateTime.saturday, Colors.blue),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 平日・土日祝選択ボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _hasWeekdays() ? _selectWeekdays : null,
                            icon: const Icon(Icons.business_center, size: 16),
                            label: const Text('平日',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: _isWeekdaysFullySelected()
                                  ? Colors.green
                                  : null,
                              foregroundColor: _isWeekdaysFullySelected()
                                  ? Colors.white
                                  : null,
                              side: BorderSide(
                                color: !_hasWeekdays()
                                    ? Colors.grey.shade300
                                    : (_isWeekdaysFullySelected()
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _hasWeekendsOrHolidays()
                                ? _selectWeekendsAndHolidays
                                : null,
                            icon: const Icon(Icons.weekend, size: 16),
                            label: const Text('土日祝',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor:
                                  _isWeekendsAndHolidaysFullySelected()
                                      ? Colors.green
                                      : null,
                              foregroundColor:
                                  _isWeekendsAndHolidaysFullySelected()
                                      ? Colors.white
                                      : null,
                              side: BorderSide(
                                color: !_hasWeekendsOrHolidays()
                                    ? Colors.grey.shade300
                                    : (_isWeekendsAndHolidaysFullySelected()
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 第〇週選択ボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '週別選択',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildWeekButton('第1週', 1),
                            _buildWeekButton('第2週', 2),
                            _buildWeekButton('第3週', 3),
                            _buildWeekButton('第4週', 4),
                            _buildWeekButton('第5週', 5),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                // シフトリスト
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: shiftDates.length,
                    itemBuilder: (context, index) {
                      final shift = shiftDates[index];
                      final store = stores.firstWhere(
                        (s) => s.id == shift.storeId,
                        orElse: () => stores.first,
                      );
                      final isSelected =
                          _selectedUniqueKeys.contains(shift.uniqueKey);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isSelected ? 4 : 2,
                        color: isSelected
                            ? Colors.green.shade50
                            : Colors.white,
                        child: ListTile(
                          leading: _isBatchSelectionExpanded
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedUniqueKeys
                                            .add(shift.uniqueKey);
                                      } else {
                                        _selectedUniqueKeys
                                            .remove(shift.uniqueKey);
                                      }
                                    });
                                  },
                                  activeColor: Colors.green,
                                )
                              : const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  radius: 20,
                                ),
                          title: Text(
                            '${shift.date.year}/${shift.date.month}/${shift.date.day}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (shift.startTime != null && shift.endTime != null)
                                Text(
                                  '${shift.startTime} - ${shift.endTime}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                )
                              else
                                AnimatedBuilder(
                                  animation: _blinkAnimation,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _blinkAnimation.value,
                                      child: const Text(
                                        '時間未設定',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (shift.memo != null && shift.memo!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '備考: ${shift.memo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: _isBatchSelectionExpanded
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // 削除確認ダイアログ
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('削除確認'),
                                        content: Text(
                                            '${shift.date.month}/${shift.date.day}のシフトを削除しますか？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('キャンセル'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ref
                                                  .read(shiftDateProvider.notifier)
                                                  .removeDate(shift.uniqueKey);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('削除',
                                                style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          onTap: _isBatchSelectionExpanded
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedUniqueKeys
                                          .remove(shift.uniqueKey);
                                    } else {
                                      _selectedUniqueKeys
                                          .add(shift.uniqueKey);
                                    }
                                  });
                                }
                              : () async {
                                  // 個別設定用のモーダルを表示
                                  final result = await showDialog<TimeSettingResult>(
                                    context: context,
                                    builder: (context) => TimeSettingModal(
                                      title: '時間設定',
                                      initialStartTime: shift.startTime,
                                      initialEndTime: shift.endTime,
                                      initialMemo: shift.memo,
                                      showMemoField: true,
                                    ),
                                  );

                                  if (result != null) {
                                    ref
                                        .read(shiftDateProvider.notifier)
                                        .updateTimeAndMemo(
                                          shift.uniqueKey,
                                          result.startTime,
                                          result.endTime,
                                          result.memo,
                                        );
                                  }
                                },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayButton(String label, int weekday, Color color) {
    final isFullySelected = _isWeekdayFullySelected(weekday);
    final hasWeekday = _hasWeekday(weekday);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: hasWeekday ? () => _selectByWeekday(weekday) : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6),
            side: BorderSide(
              color: !hasWeekday
                  ? Colors.grey.shade300
                  : (isFullySelected ? Colors.green : color),
            ),
            backgroundColor: isFullySelected ? Colors.green : null,
            minimumSize: const Size(0, 0),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: !hasWeekday
                  ? Colors.grey.shade400
                  : (isFullySelected ? Colors.white : color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekButton(String label, int week) {
    final isFullySelected = _isWeekOfMonthFullySelected(week);
    final hasWeek = _hasWeekOfMonth(week);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: OutlinedButton(
          onPressed: hasWeek ? () => _selectByWeekOfMonth(week) : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 6),
            side: BorderSide(
              color: !hasWeek
                  ? Colors.grey.shade300
                  : (isFullySelected ? Colors.green : Colors.grey),
            ),
            backgroundColor: isFullySelected ? Colors.green : null,
            minimumSize: const Size(0, 0),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: !hasWeek
                  ? Colors.grey.shade400
                  : (isFullySelected ? Colors.white : Colors.black),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

}

// ============================================================
// Page 3: 確認・提出
// ============================================================

class _ConfirmationPage extends ConsumerStatefulWidget {
  final VoidCallback onPrevious;

  const _ConfirmationPage({
    required this.onPrevious,
  });

  @override
  ConsumerState<_ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends ConsumerState<_ConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    // ブリンクアニメーションの初期化（1.5秒周期でゆっくり点滅）
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  // 統計情報を計算
  Map<String, dynamic> _calculateStatistics(List<dynamic> shifts) {
    int totalDays = shifts.length;
    double totalHours = 0;
    double totalActualHours = 0; // 休憩時間を差し引いた実労働時間
    int daysWithTime = 0;

    for (final shift in shifts) {
      final hours = TimeUtils.calculateWorkHours(shift.startTime, shift.endTime);
      if (hours != null) {
        totalHours += hours;
        final actualHours = TimeUtils.calculateActualWorkHours(shift.startTime, shift.endTime);
        if (actualHours != null) {
          totalActualHours += actualHours;
        }
        daysWithTime++;
      }
    }

    return {
      'totalDays': totalDays,
      'totalHours': totalHours,
      'totalActualHours': totalActualHours,
      'daysWithTime': daysWithTime,
    };
  }

  @override
  Widget build(BuildContext context) {
    final shiftDates = ref.watch(shiftDateProvider);
    final stores = ref.watch(storeProvider);
    final stats = _calculateStatistics(shiftDates);

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
        automaticallyImplyLeading: false,
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
                // 統計情報表示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade100,
                        Colors.green.shade50,
                      ],
                    ),
                    border: const Border(
                      bottom: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'シフト統計',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.calendar_today,
                            '合計勤務日数',
                            '${stats['totalDays']}日',
                          ),
                          _buildStatItem(
                            Icons.access_time,
                            '実労働時間',
                            '${stats['totalActualHours'].toStringAsFixed(1)}時間',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '※休憩時間を差し引いています（労働基準法に基づく）',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

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
                        backgroundColor: Colors.green,
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

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
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

class _MonthAccordionState extends State<_MonthAccordion>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    // ブリンクアニメーションの初期化（1.5秒周期でゆっくり点滅）
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

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
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 12,
                ),
                title: Text(
                  '${shift.date.month}/${shift.date.day}',
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: shift.startTime != null && shift.endTime != null
                    ? Text(
                        '${shift.startTime} - ${shift.endTime}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : AnimatedBuilder(
                        animation: _blinkAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _blinkAnimation.value,
                            child: const Text(
                              '時間未設定',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
