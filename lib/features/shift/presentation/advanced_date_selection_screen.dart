import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../domain/models/job.dart';

class AdvancedDateSelectionScreen extends ConsumerWidget {
  const AdvancedDateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final calendarNotifier = ref.read(calendarProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト日付選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.business),
            onPressed: () => _showJobManagerDialog(context, ref),
            tooltip: '店舗管理',
          ),
          TextButton(
            onPressed: () {
              // 選択完了
              calendarNotifier.savePreviousMonthData();
              Navigator.pop(context);
            },
            child: const Text(
              '完了',
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
          // ジョブセレクター
          _buildJobSelector(context, ref, calendarState, calendarNotifier),

          // 月選択
          _buildMonthSelector(context, calendarState, calendarNotifier),

          // 一括操作ボタン
          _buildActionButtons(context, ref, calendarState, calendarNotifier),

          // 曜日別選択ボタン
          _buildWeekdayButtons(context, ref, calendarState, calendarNotifier),

          const Divider(height: 1),

          // カレンダーグリッド
          Expanded(
            child: _buildCalendarGrid(context, ref, calendarState, calendarNotifier),
          ),

          // 統計情報
          _buildStats(context, calendarState),
        ],
      ),
    );
  }

  // ジョブセレクター
  Widget _buildJobSelector(
    BuildContext context,
    WidgetRef ref,
    dynamic calendarState,
    dynamic calendarNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: calendarState.currentJobId != null
          ? jobColors[calendarState.currentJobId]!.withOpacity(0.2)
          : null,
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
              // 本店
              ChoiceChip(
                label: Text(calendarState.mainStoreName),
                selected: calendarState.currentJobId == null,
                onSelected: (selected) {
                  if (selected) {
                    calendarNotifier.switchJob(null);
                  }
                },
                selectedColor: Colors.blue,
                labelStyle: TextStyle(
                  color: calendarState.currentJobId == null
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ジョブ1-4
              ...calendarState.jobs.map((job) {
                return ChoiceChip(
                  label: Text(job.name),
                  selected: calendarState.currentJobId == job.id,
                  onSelected: (selected) {
                    if (selected) {
                      calendarNotifier.switchJob(job.id);
                    }
                  },
                  selectedColor: job.color.withOpacity(0.8),
                  backgroundColor: job.color.withOpacity(0.3),
                  labelStyle: TextStyle(
                    color: calendarState.currentJobId == job.id
                        ? Colors.black
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              // ジョブ追加ボタン
              if (calendarState.jobs.length < 4)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('店舗追加'),
                  onPressed: () => _showAddJobDialog(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 月選択
  Widget _buildMonthSelector(
    BuildContext context,
    dynamic calendarState,
    dynamic calendarNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => calendarNotifier.changeMonth(-1),
          ),
          Text(
            '${calendarState.currentYear}年 ${calendarState.currentMonth}月',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => calendarNotifier.changeMonth(1),
          ),
        ],
      ),
    );
  }

  // 一括操作ボタン
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic calendarState,
    dynamic calendarNotifier,
  ) {
    // 現在月のすべての日付を取得
    final dates = _getMonthDates(calendarState.currentYear, calendarState.currentMonth);
    final weekdayDates = dates.where((d) => d.weekday >= 1 && d.weekday <= 5).toList();
    final weekendDates = dates.where((d) => d.weekday >= 6).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => calendarNotifier.selectAll(dates),
              icon: const Icon(Icons.calendar_month, size: 16),
              label: const Text('全日', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => calendarNotifier.selectWeekdays(weekdayDates),
              icon: const Icon(Icons.business_center, size: 16),
              label: const Text('平日', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => calendarNotifier.selectWeekendsAndHolidays(weekendDates),
              icon: const Icon(Icons.weekend, size: 16),
              label: const Text('土日', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => calendarNotifier.clearAll(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('クリア', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
            ),
          ),
          if (calendarState.previousMonthData != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () => calendarNotifier.copyPreviousMonth(),
              tooltip: '前月コピー',
            ),
          ],
        ],
      ),
    );
  }

  // 曜日別選択ボタン
  Widget _buildWeekdayButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic calendarState,
    dynamic calendarNotifier,
  ) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(7, (index) {
          final weekday = index + 1; // 1=月, 7=日
          final dates = _getMonthDates(calendarState.currentYear, calendarState.currentMonth)
              .where((d) => d.weekday == weekday)
              .toList();

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: OutlinedButton(
                onPressed: () => calendarNotifier.toggleWeekday(weekday, dates),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: BorderSide(color: colors[index]),
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

  // カレンダーグリッド（続く...）
  Widget _buildCalendarGrid(
    BuildContext context,
    WidgetRef ref,
    dynamic calendarState,
    dynamic calendarNotifier,
  ) {
    final dates = _getCalendarGridDates(calendarState.currentYear, calendarState.currentMonth);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final isCurrentMonth = date.month == calendarState.currentMonth;
        final isToday = _isSameDay(date, DateTime.now());
        final isPast = date.isBefore(DateTime.now()) && !isToday;
        final isSelected = calendarNotifier.isDateSelected(_formatDateString(date));

        // ジョブドットを取得
        final dateString = _formatDateString(date);
        final jobIds = calendarState.dateJobMap[dateString] ?? <int>{};
        final hasMainStore = calendarState.selectedDates.contains(dateString);

        return GestureDetector(
          onTap: isPast || !isCurrentMonth
              ? null
              : () => calendarNotifier.toggleDate(date),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.withOpacity(0.3)
                  : (isPast ? Colors.grey.withOpacity(0.1) : null),
              border: Border.all(
                color: isToday ? Colors.purple : Colors.grey.withOpacity(0.3),
                width: isToday ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isPast
                        ? Colors.grey
                        : (isCurrentMonth ? Colors.black : Colors.grey),
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                // ジョブドット表示
                if (jobIds.isNotEmpty || hasMainStore)
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    alignment: WrapAlignment.center,
                    children: [
                      if (hasMainStore)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ...jobIds.map((jobId) {
                        final color = jobColors[jobId] ?? Colors.grey;
                        return Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 統計情報
  Widget _buildStats(BuildContext context, dynamic calendarState) {
    final selectedCount = calendarState.currentJobId == null
        ? calendarState.selectedDates.length
        : calendarState.dateJobMap.values
            .where((v) => v.contains(calendarState.currentJobId))
            .length;

    return Container(
      padding: const EdgeInsets.all(16),
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
            '選択: $selectedCount日',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ヘルパー関数
  List<DateTime> _getMonthDates(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final now = DateTime.now();

    final dates = <DateTime>[];
    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      if (!date.isBefore(now) || _isSameDay(date, now)) {
        dates.add(date);
      }
    }
    return dates;
  }

  List<DateTime> _getCalendarGridDates(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final firstWeekday = firstDay.weekday; // 1=月, 7=日
    final startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    return List.generate(42, (index) => startDate.add(Duration(days: index)));
  }

  String _formatDateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ダイアログ
  void _showJobManagerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _JobManagerDialog(ref: ref),
    );
  }

  void _showAddJobDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '店舗名（14文字まで）',
            border: OutlineInputBorder(),
          ),
          maxLength: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(calendarProvider.notifier).addJob(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}

// ジョブ管理ダイアログ
class _JobManagerDialog extends StatelessWidget {
  final WidgetRef ref;

  const _JobManagerDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    final calendarNotifier = ref.read(calendarProvider.notifier);

    return AlertDialog(
      title: const Text('店舗管理'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: calendarState.jobs.length,
          itemBuilder: (context, index) {
            final job = calendarState.jobs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: job.color,
                child: Text('${job.id}'),
              ),
              title: Text(job.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditJobDialog(context, job, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      calendarNotifier.removeJob(job.id);
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

  void _showEditJobDialog(BuildContext context, Job job, WidgetRef ref) {
    final controller = TextEditingController(text: job.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('店舗名変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '店舗名（14文字まで）',
            border: OutlineInputBorder(),
          ),
          maxLength: 14,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(calendarProvider.notifier).renameJob(job.id, controller.text);
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
