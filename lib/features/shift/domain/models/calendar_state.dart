import 'job.dart';

/// カレンダーの状態
class CalendarState {
  // 年月管理
  final int currentYear;
  final int currentMonth;

  // 日付選択管理
  final Set<String> selectedDates; // 本店の選択日付（ISO 8601形式）
  final Map<String, Set<int>> dateJobMap; // 日付 => ジョブIDのSet

  // ジョブ管理
  final List<Job> jobs; // 掛け持ち店舗リスト（最大4つ）
  final int? currentJobId; // 選択中のジョブID (null=本店)
  final String mainStoreName; // 本店名

  // 祝日データ
  final Map<String, String> holidays; // 日付 => 祝日名

  // テンプレート・前月データ
  final List<String>? previousMonthData; // 前月の選択パターン

  CalendarState({
    required this.currentYear,
    required this.currentMonth,
    Set<String>? selectedDates,
    Map<String, Set<int>>? dateJobMap,
    List<Job>? jobs,
    this.currentJobId,
    this.mainStoreName = '本店',
    Map<String, String>? holidays,
    this.previousMonthData,
  })  : selectedDates = selectedDates ?? {},
        dateJobMap = dateJobMap ?? {},
        jobs = jobs ?? [],
        holidays = holidays ?? {};

  CalendarState copyWith({
    int? currentYear,
    int? currentMonth,
    Set<String>? selectedDates,
    Map<String, Set<int>>? dateJobMap,
    List<Job>? jobs,
    int? currentJobId,
    bool clearCurrentJobId = false,
    String? mainStoreName,
    Map<String, String>? holidays,
    List<String>? previousMonthData,
    bool clearPreviousMonthData = false,
  }) {
    return CalendarState(
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      selectedDates: selectedDates ?? this.selectedDates,
      dateJobMap: dateJobMap ?? this.dateJobMap,
      jobs: jobs ?? this.jobs,
      currentJobId:
          clearCurrentJobId ? null : (currentJobId ?? this.currentJobId),
      mainStoreName: mainStoreName ?? this.mainStoreName,
      holidays: holidays ?? this.holidays,
      previousMonthData: clearPreviousMonthData
          ? null
          : (previousMonthData ?? this.previousMonthData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedDates': selectedDates.toList(),
      'dateJobMap': dateJobMap.map(
        (key, value) => MapEntry(key, value.toList()),
      ),
      'jobs': jobs.map((j) => j.toJson()).toList(),
      'mainStoreName': mainStoreName,
      'previousMonthData': previousMonthData,
    };
  }

  factory CalendarState.fromJson(
    Map<String, dynamic> json,
    int year,
    int month,
  ) {
    return CalendarState(
      currentYear: year,
      currentMonth: month,
      selectedDates: Set<String>.from(json['selectedDates'] ?? []),
      dateJobMap: (json['dateJobMap'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Set<int>.from(value)),
          ) ??
          {},
      jobs: (json['jobs'] as List?)
              ?.map((j) => Job.fromJson(j as Map<String, dynamic>))
              .toList() ??
          [],
      mainStoreName: json['mainStoreName'] ?? '本店',
      previousMonthData: json['previousMonthData'] != null
          ? List<String>.from(json['previousMonthData'])
          : null,
    );
  }
}
