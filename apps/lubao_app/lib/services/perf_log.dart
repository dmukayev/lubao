import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart';

/// 060 п.5: замеры скорости в release/profile. Только при
/// `--dart-define=PERF_LOG=true` — в обычной сборке ничего не делает.
/// Строки `LUBAO_PERF …` читаются из logcat / консоли устройства.
abstract final class PerfLog {
  static const enabled = bool.fromEnvironment('PERF_LOG');
  static final _sinceStart = Stopwatch();
  static bool _feedMarked = false;
  static int _frames = 0, _slow16 = 0, _slow33 = 0;
  static double _worstMs = 0;

  static void start() {
    if (!enabled) return;
    _sinceStart.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    Timer.periodic(const Duration(seconds: 5), (_) => _flush());
  }

  /// Первая лента с данными на экране — время от запуска.
  static void feedShown() {
    if (!enabled || _feedMarked) return;
    _feedMarked = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // ignore: avoid_print
      print('LUBAO_PERF feed_ready_ms=${_sinceStart.elapsedMilliseconds}');
    });
  }

  static void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      final ms = t.totalSpan.inMicroseconds / 1000;
      _frames++;
      if (ms > 16.7) _slow16++;
      if (ms > 33.4) _slow33++;
      if (ms > _worstMs) _worstMs = ms;
    }
  }

  static void _flush() {
    if (_frames == 0) return;
    // ignore: avoid_print
    print('LUBAO_PERF frames=$_frames slow16=$_slow16 slow33=$_slow33 worst_ms=${_worstMs.toStringAsFixed(1)}');
    _frames = _slow16 = _slow33 = 0;
    _worstMs = 0;
  }
}
