import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'package:flutter/widgets.dart';
import '../services/session_service.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({Key? key}) : super(key: key);

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen>
    with WidgetsBindingObserver {
  int seconds = 0;
  int breakSeconds = 0;
  bool isRunning = false;
  bool isBreak = false;
  Timer? timer;
  final SessionService _sessionService = SessionService();
  int totalFocus = 0;
  int totalBreak = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _sessionService.loadSessionStats();
    setState(() {
      totalFocus = stats['totalFocus']!;
      totalBreak = stats['totalBreak']!;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseTimer();
    }
  }

  void _startTimer() {
    setState(() => isRunning = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (isBreak) {
          breakSeconds++;
        } else {
          seconds++;
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() => isRunning = false);
    timer?.cancel();
  }

  void _toggleBreakMode() {
    _pauseTimer();
    setState(() {
      isBreak = !isBreak;
    });
  }

  Future<void> _endSession() async {
    _pauseTimer();
    await _sessionService.saveSessionStats(seconds ~/ 60, breakSeconds ~/ 60);
    await _loadStats();
    setState(() {
      seconds = 0;
      breakSeconds = 0;
      isBreak = false;
    });
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212), // dark background
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBreak ? "Break Mode" : "Focus Mode",
                  style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Text(
                  _formatTime(isBreak ? breakSeconds : seconds),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00FFAA), // minty timer color
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SimpleButton(
                      text: isRunning ? "Pause" : "Start",
                      onPressed: isRunning ? _pauseTimer : _startTimer,
                      color: const Color(0xFF1DB954),
                    ),
                    const SizedBox(width: 16),
                    _SimpleButton(
                      text: isBreak ? "Back to Focus" : "Take Break",
                      onPressed: _toggleBreakMode,
                      color: const Color(0xFF3A3A3A),
                    ),
                    const SizedBox(width: 16),
                    _SimpleButton(
                      text: "End",
                      onPressed: _endSession,
                      color: const Color(0xFFFF5555),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  "Total Focus: ${totalFocus}m  •  Total Break: ${totalBreak}m",
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _SimpleButton(
      {required this.text, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

