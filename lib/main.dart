import 'package:flutter/material.dart';
import 'models/time_range.dart';
import 'widgets/time_setting_modal.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S×S Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'S×S Manager - シフト管理'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TimeRange? _selectedTimeRange;

  Future<void> _openTimeSettingModal() async {
    final result = await TimeSettingModal.show(
      context,
      initialTimeRange: _selectedTimeRange,
      title: 'シフト時間設定',
    );

    if (result != null) {
      setState(() {
        _selectedTimeRange = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_selectedTimeRange != null) ...[
              const Text('選択された時間:'),
              const SizedBox(height: 8),
              Text(
                _selectedTimeRange!.formattedRange,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '勤務時間: ${_selectedTimeRange!.durationInMinutes ~/ 60}時間${_selectedTimeRange!.durationInMinutes % 60}分',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ] else ...[
              const Text('時間が設定されていません'),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openTimeSettingModal,
              icon: const Icon(Icons.schedule),
              label: const Text('時間を設定'),
            ),
          ],
        ),
      ),
    );
  }
}
