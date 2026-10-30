import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/session_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'session_records_screen.dart';

class DynamicQrScreen extends StatefulWidget {
  final AttendanceSessionModel session;

  const DynamicQrScreen({super.key, required this.session});

  @override
  State<DynamicQrScreen> createState() => _DynamicQrScreenState();
}

class _DynamicQrScreenState extends State<DynamicQrScreen> {
  static const int _windowSeconds = 15;
  String _token = '';
  int _remaining = _windowSeconds;
  bool _fetching = false;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshToken();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        _refreshToken();
      }
    });
  }

  // Lấy mã QR mới từ server (mã được server tính theo chu kỳ 15 giây)
  Future<void> _refreshToken() async {
    if (_fetching) return;
    _fetching = true;
    final res = await ApiService.getQrToken(widget.session.id);
    _fetching = false;
    if (!mounted) return;
    setState(() {
      if (res != null && res['token'] != null) {
        _token = res['token'] as String;
        _remaining = (res['secondsRemaining'] as num?)?.toInt() ?? _windowSeconds;
        _failed = false;
      } else {
        _failed = true;
        _remaining = 3; // thử lại sau 3 giây
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionRecordsScreen(sessionId: widget.session.id, sessionTitle: widget.session.sessionTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'sessionId': widget.session.id,
      'token': _token,
      'className': widget.session.className,
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR điểm danh'),
        actions: [
          IconButton(tooltip: 'Danh sách đã điểm danh', icon: const Icon(Icons.people_alt_outlined), onPressed: _openRecords),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.session.className,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(widget.session.sessionTitle,
                  textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: _token.isEmpty
                          ? Center(
                              child: _failed
                                  ? const EmptyState(icon: Icons.wifi_off_rounded, message: 'Không tải được mã QR.\nĐang thử lại...')
                                  : const CircularProgressIndicator(),
                            )
                          : QrImageView(data: qrData, version: QrVersions.auto, size: 240, backgroundColor: Colors.white),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _remaining / _windowSeconds,
                                strokeWidth: 4,
                                backgroundColor: AppTheme.border,
                                color: _remaining <= 5 ? AppTheme.warning : AppTheme.primaryDark,
                              ),
                              Text('$_remaining', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Mã tự đổi sau mỗi 15 giây',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14)),
                      ],
                    ),
                    if (_token.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SelectableText(_token,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, letterSpacing: 1.2)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.successBg, borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: AppTheme.success),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ảnh chụp màn hình QR sẽ hết hạn sau vài giây, và hệ thống còn đối chiếu GPS của sinh viên với phòng học để chặn điểm danh hộ.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openRecords,
                icon: const Icon(Icons.list_alt_rounded, size: 20),
                label: const Text('Xem danh sách đã điểm danh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
