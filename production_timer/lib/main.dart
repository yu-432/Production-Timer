import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TimerPage(),
    );
  }
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  // 今日の0時からの経過秒数を保存する変数
  int _seconds = 0;

  // タイマーが動いているかどうかを管理するフラグ
  bool _isRunning = false;

  // Timerオブジェクトを保存する変数
  Timer? _timer;

  // 今日の0時（深夜）の日時を取得する関数
  DateTime _getTodayMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // 今日の0時からの経過秒数を計算する関数
  int _getSecondsFromMidnight() {
    final now = DateTime.now();
    final midnight = _getTodayMidnight();
    return now.difference(midnight).inSeconds;
  }

  // タイマーをスタート/ストップする関数
  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        // タイマーが動いている場合は停止
        _timer?.cancel();
        _isRunning = false;
      } else {
        // タイマーが停止している場合は開始
        _isRunning = true;
        // 0秒から開始
        _seconds = 0;

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            // 1秒ずつカウントアップ
            _seconds++;
          });
        });
      }
    });
  }

  // 秒数を「HH:MM:SS」形式の文字列に変換する関数
  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    // 2桁のゼロ埋め形式で返す（例：01:05:09）
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // ウィジェットが破棄される時にタイマーをキャンセル
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Timer'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // タイマーの表示
            Text(
              _formatTime(_seconds),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 60),
            // Start/Stopボタン
            ElevatedButton(
              onPressed: _toggleTimer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: Text(_isRunning ? 'STOP' : 'START'),
            ),
          ],
        ),
      ),
    );
  }
}
