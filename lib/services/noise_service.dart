import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Đo mức ồn xung quanh bằng micro. Chỉ đo cường độ âm thanh (dB), KHÔNG ghi âm hay lưu âm thanh.
class NoiseService {
  /// Đo trong [seconds] giây, trả về dB trung bình (làm tròn 1 chữ số).
  /// Trả về null nếu thiết bị không hỗ trợ, bị từ chối quyền micro hoặc lỗi.
  static Future<double?> measure({int seconds = 3, void Function(double db)? onLevel}) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;

    final status = await Permission.microphone.request();
    if (!status.isGranted) return null;

    final readings = <double>[];
    StreamSubscription<NoiseReading>? sub;
    try {
      final failed = Completer<void>();
      sub = NoiseMeter().noise.listen(
        (reading) {
          final db = reading.meanDecibel;
          if (db.isFinite && db > 0) {
            readings.add(db);
            onLevel?.call(db);
          }
        },
        onError: (_) {
          if (!failed.isCompleted) failed.complete();
        },
      );
      await Future.any([Future.delayed(Duration(seconds: seconds)), failed.future]);
    } catch (_) {
      // bỏ qua, trả về kết quả đã đo được (nếu có)
    } finally {
      await sub?.cancel();
    }

    if (readings.isEmpty) return null;
    final avg = readings.reduce((a, b) => a + b) / readings.length;
    return double.parse(avg.toStringAsFixed(1));
  }

  /// Nhãn mô tả mức ồn (tương đối, micro mỗi máy một khác).
  static String describe(double db) {
    if (db < 40) return 'Yên tĩnh';
    if (db < 60) return 'Bình thường';
    if (db < 75) return 'Hơi ồn';
    return 'Ồn ào';
  }
}
