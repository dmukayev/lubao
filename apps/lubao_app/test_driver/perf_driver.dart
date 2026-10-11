import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// 060 п.5: `flutter drive --profile` — сводка кадров и времени в
/// build/perf/perf_summary.json (см. scripts/perf.sh).
Future<void> main() => integrationDriver(responseDataCallback: (data) async {
      final dir = Directory('build/perf')..createSync(recursive: true);
      File('${dir.path}/perf_summary.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    });
