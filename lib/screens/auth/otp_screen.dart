import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../admin/admin_dashboard.dart';
import '../lecturer/lecturer_dashboard.dart';
import '../student/student_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String usernameOrEmail;
  final String email;
  /// Chỉ có giá trị khi server không gửi được email (OTP dự phòng).
  final String otpDemo;

  const OtpScreen({
    super.key,
    required this.usernameOrEmail,
    required this.email,
    this.otpDemo = '',
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;
  String _demoOtp = '';
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _demoOtp = widget.otpDemo;
    _otpController.text = _demoOtp;
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
      }
      setState(() => _cooldown--);
    });
  }

  void _resendOtp() async {
    setState(() => _resending = true);
    try {
      final res = await ApiService.resendOtp(widget.usernameOrEmail);
      if (!mounted) return;
      final ok = res['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? (ok ? 'Đã gửi lại mã OTP' : 'Không gửi lại được mã')),
          backgroundColor: ok ? AppTheme.success : AppTheme.danger,
        ),
      );
      if (ok) {
        final demo = (res['otpDemo'] ?? '').toString();
        setState(() => _demoOtp = demo);
        _otpController.text = demo;
        _startCooldown();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối Server: $e'), backgroundColor: AppTheme.danger),
      );
    }
    if (mounted) setState(() => _resending = false);
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ 6 chữ số OTP!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.verifyOtp(widget.usernameOrEmail, otp);
      setState(() => _isLoading = false);

      if (res['success'] == true && res['user'] != null) {
        final user = UserModel.fromJson(res['user']);
        if (!mounted) return;

        Widget nextScreen;
        if (user.role == 'Admin') {
          nextScreen = AdminDashboard(user: user);
        } else if (user.role == 'Lecturer') {
          nextScreen = LecturerDashboard(user: user);
        } else {
          nextScreen = StudentDashboard(user: user);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Xác thực OTP thất bại!'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối Server: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.email.isNotEmpty ? widget.email : widget.usernameOrEmail;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Xác thực 2 lớp')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const IconBadge(icon: Icons.mark_email_read_outlined, color: AppTheme.primaryDark, bg: Color(0xFFD9F1EE), size: 64),
              const SizedBox(height: 16),
              const Text('Nhập mã OTP',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Mã gồm 6 chữ số đã được gửi tới\n$target',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
              const SizedBox(height: 22),
              if (_demoOtp.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.warningBg, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.warning),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Không gửi được email • mã OTP dự phòng: $_demoOtp',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 30, letterSpacing: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                      decoration: const InputDecoration(hintText: '000000', counterText: ''),
                    ),
                    const SizedBox(height: 18),
                    LoadingButton(loading: _isLoading, onPressed: _verifyOtp, label: 'Xác nhận và truy cập', icon: Icons.verified_user_outlined),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: (_cooldown > 0 || _resending) ? null : _resendOtp,
                      child: Text(_cooldown > 0 ? 'Gửi lại mã sau ${_cooldown}s' : 'Gửi lại mã OTP'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
