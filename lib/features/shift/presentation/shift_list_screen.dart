import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/shift_date_provider.dart';
import '../domain/models/shift_date.dart';
import 'date_selection_screen.dart';
import 'time_setting_screen.dart';

class ShiftListScreen extends ConsumerWidget {
  const ShiftListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftDates = ref.watch(shiftDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('シフト管理'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF出力機能は後で実装します')),
              );
            },
            tooltip: 'PDF出力',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('設定画面は後で実装します')),
              );
            },
            tooltip: '設定',
          ),
        ],
      ),
      body: shiftDates.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                // 統計情報
                _buildStatistics(shiftDates),
                const Divider(height: 1),
                // 一括操作ボタン
                _buildBatchActions(context, ref, shiftDates),
                const Divider(height: 1),
                // シフトリスト
                Expanded(
                  child: _buildShiftList(context, ref, shiftDates),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 日付選択画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DateSelectionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('日付を追加'),
      ),
    );
  }

  // 空の状態
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 100, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'シフト日付がありません',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DateSelectionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('日付を追加'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 統計情報
  Widget _buildStatistics(List<ShiftDate> shiftDates) {
    final totalDays = shiftDates.length;
    final daysWithTime = shiftDates.where((d) => d.hasTime).length;
    final daysWithoutTime = totalDays - daysWithTime;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('合計', '$totalDays日', Colors.blue),
          _buildStatItem('時間設定済み', '$daysWithTime日', Colors.green),
          _buildStatItem('未設定', '$daysWithoutTime日', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 一括操作ボタン
  Widget _buildBatchActions(
    BuildContext context,
    WidgetRef ref,
    List<ShiftDate> shiftDates,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _showBatchTimeSettingDialog(context, ref, shiftDates);
              },
              icon: const Icon(Icons.schedule),
              label: const Text('一括時間設定'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _showClearAllDialog(context, ref);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('全削除'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // シフトリスト
  Widget _buildShiftList(
    BuildContext context,
    WidgetRef ref,
    List<ShiftDate> shiftDates,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: shiftDates.length,
      itemBuilder: (context, index) {
        final shiftDate = shiftDates[index];
        final date = shiftDate.date;
        final weekday = DateFormat.E('ja_JP').format(date);
        final isWeekend =
            date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              // 時間設定画面へ遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TimeSettingScreen(uniqueKey: shiftDate.uniqueKey),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 日付アイコン
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isWeekend ? Colors.red : Colors.blue,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('M/d').format(date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          weekday,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 時間情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy年M月d日（E）', 'ja_JP').format(date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (shiftDate.hasTime)
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${shiftDate.startTime} - ${shiftDate.endTime}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                '時間未設定',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        if (shiftDate.memo != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            shiftDate.memo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 削除ボタン
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      _showDeleteDialog(context, ref, shiftDate);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 削除確認ダイアログ
  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ShiftDate shiftDate,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text(
          '${DateFormat('yyyy年M月d日', 'ja_JP').format(shiftDate.date)}を削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shiftDateProvider.notifier).removeDate(shiftDate.uniqueKey);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 全削除確認ダイアログ
  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全削除確認'),
        content: const Text('すべてのシフト日付を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shiftDateProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('全削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 一括時間設定ダイアログ
  void _showBatchTimeSettingDialog(
    BuildContext context,
    WidgetRef ref,
    List<ShiftDate> shiftDates,
  ) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('一括時間設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('すべての日付に同じ時間を設定します'),
              const SizedBox(height: 16),
              // 開始時刻
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('開始時刻'),
                trailing: Text(
                  startTime?.format(context) ?? '未設定',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => startTime = picked);
                  }
                },
              ),
              // 終了時刻
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('終了時刻'),
                trailing: Text(
                  endTime?.format(context) ?? '未設定',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: endTime ?? const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (picked != null) {
                    setState(() => endTime = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                if (startTime != null && endTime != null) {
                  final startStr =
                      '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}';
                  final endStr =
                      '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';

                  final uniqueKeys =
                      shiftDates.map((d) => d.uniqueKey).toList();
                  ref
                      .read(shiftDateProvider.notifier)
                      .updateMultipleTimes(uniqueKeys, startStr, endStr);

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${uniqueKeys.length}件に時間を設定しました')),
                  );
                }
              },
              child: const Text('設定'),
            ),
          ],
        ),
      ),
    );
  }
}
