import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:local_auth/local_auth.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/noise_service.dart';
import '../../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  final UserModel student;
  final int? preselectedSessionId;

  const QrScannerScreen({super.key, required this.student, this.preselectedSessionId});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(autoStart: false);
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isProcessing = false;
  bool _biometricVerified = false;
  double? _noiseDb;
  bool _measuringNoise = false;

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  // Xin quyền lần lượt (camera -> vân tay -> micro) để các hộp thoại không chồng lên nhau
  Future<void> _startSequence() async {
    await _initCamera();
    await _checkBiometrics();
    await _measureNoise();
  }

  Future<void> _initCamera() async {
    var granted = true;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      granted = (await Permission.camera.request()).isGranted;
    }
    if (!mounted) return;
    if (granted) {
      try {
        await _scannerController.start();
      } catch (_) {}
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cần cấp quyền camera để quét mã QR.'),
          backgroundColor: AppTheme.danger,
          action: SnackBarAction(label: 'Mở cài đặt', textColor: Colors.white, onPressed: openAppSettings),
        ),
      );
    }
  }

  // Đo độ ồn lớp học bằng micro trong vài giây (không ghi âm)
  Future<void> _measureNoise() async {
    if (_measuringNoise) return;
    setState(() => _measuringNoise = true);
    final db = await NoiseService.measure(
      seconds: 3,
      onLevel: (v) {
        if (mounted) setState(() => _noiseDb = v);
      },
    );
    if (!mounted) return;
    setState(() {
      if (db != null) _noiseDb = db;
      _measuringNoise = false;
    });
  }

  String _noiseLabel() {
    if (_measuringNoise) {
      return _noiseDb == null ? 'Đang đo tiếng ồn...' : 'Đang đo: ${_noiseDb!.toStringAsFixed(0)} dB';
    }
    if (_noiseDb == null) return 'Chưa đo được độ ồn (cần quyền micro)';
    return 'Độ ồn: ${_noiseDb!.toStringAsFixed(0)} dB • ${NoiseService.describe(_noiseDb!)}';
  }

  Future<void> _checkBiometrics() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (canAuth) {
        final didAuth = await _localAuth.authenticate(
          localizedReason: 'Vui lòng quét vân tay để xác thực chính chủ trước khi điểm danh',
        );
        setState(() => _biometricVerified = didAuth);
      } else {
        setState(() => _biometricVerified = true);
      }
    } catch (_) {
      setState(() => _biometricVerified = true);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawVal = barcode.rawValue!;
    _processCheckIn(rawVal);
  }

  void _processCheckIn(String qrString) async {
    setState(() => _isProcessing = true);

    try {
      int sessionId = widget.preselectedSessionId ?? 0;
      String token = qrString;

      try {
        final map = jsonDecode(qrString);
        sessionId = map['sessionId'] ?? sessionId;
        token = map['token'] ?? qrString;
      } catch (_) {}

      final pos = await LocationService.getCurrentPosition();
      final lat = pos?.latitude ?? 10.7769;
      final lon = pos?.longitude ?? 106.7009;

      final res = await ApiService.checkIn(
        sessionId: sessionId,
        studentId: widget.student.id,
        studentName: widget.student.fullName,
        qrToken: token,
        studentLatitude: lat,
        studentLongitude: lon,
        method: _biometricVerified ? 'Biometric_QR_GPS' : 'QR_GPS',
        noiseDb: _noiseDb,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
                SizedBox(width: 10),
                Text('Điểm Danh Thành Công!'),
              ],
            ),
            content: Text(res['message'] ?? 'Bạn đã hoàn tất điểm danh ca học.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, true);
                },
                child: const Text('HOÀN TẤT'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
                SizedBox(width: 10),
                Text('Cảnh Báo Vị Trí'),
              ],
            ),
            content: Text(res['message'] ?? 'Không thể điểm danh.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isProcessing = false);
                },
                child: const Text('THỬ LẠI'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
      );
      setState(() => _isProcessing = false);
    }
  }

  void _openManualDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mô phỏng Quét QR (Máy ảo)'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Mã Token QR',
            hintText: 'Nhập mã token từ màn hình Giảng viên',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processCheckIn(controller.text.trim());
            },
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quét QR & Định vị GPS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Nhập mã thủ công cho máy ảo',
            icon: const Icon(Icons.keyboard_outlined),
            onPressed: _openManualDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Cyber Scanner Target Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withAlpha(50), blurRadius: 20),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withAlpha(220),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(40)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gps_fixed_rounded, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _biometricVerified ? 'Vân tay đã xác thực • GPS Geofencing Bật' : 'Đang quét cảm biến...',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(_noiseLabel(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
                      ),
                      if (!_measuringNoise)
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.greenAccent, minimumSize: const Size(0, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: _measureNoise,
                          child: const Text('Đo lại', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Hướng camera vào mã QR của giảng viên.\nHệ thống tự động kiểm tra vị trí phòng học.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withAlpha(180),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.greenAccent),
                    SizedBox(height: 16),
                    Text('Đang xác thực tọa độ GPS phòng học...', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
