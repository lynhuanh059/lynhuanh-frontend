import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import '../../models/user_model.dart';
import '../../services/biometric_login_service.dart';
import 'otp_screen.dart';
import 'role_router.dart';
import 'register_screen.dart';
import '../settings/server_settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'sinhvien');
  final _passwordController = TextEditingController(text: '123');
  bool _isLoading = false;
  String _selectedRolePreset = 'Student';
  UserModel? _savedUser;
  String _bioLabel = 'khuôn mặt / vân tay';

  @override
  void initState() {
    super.initState();
    _loadSavedBiometric();
  }

  Future<void> _loadSavedBiometric() async {
    final u = await BiometricLoginService.savedUser();
    final label = await BiometricLoginService.label();
    if (!mounted) return;
    setState(() {
      _savedUser = u;
      _bioLabel = label;
    });
  }

  /// Lần sau: đăng nhập bằng khuôn mặt / vân tay, bỏ qua mật khẩu + OTP.
  Future<void> _biometricLogin() async {
    final u = _savedUser;
    if (u == null) return;
    final ok = await BiometricLoginService.authenticate();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xác thực $_bioLabel chưa thành công'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dashboardFor(u)),
      (route) => false,
    );
  }

  void _login() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đăng nhập và mật khẩu!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.login(user, pass);
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              usernameOrEmail: user,
              email: res['email'] ?? '',
              otpDemo: (res['otpDemo'] ?? '').toString(),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Sai thông tin đăng nhập!'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không kết nối được Backend. Vui lòng kiểm tra IP Server. Lỗi: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _selectPreset(String role, String username, String pass) {
    setState(() {
      _selectedRolePreset = role;
      _usernameController.text = username;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 8, 56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Cài đặt IP Máy chủ',
                          icon: const Icon(Icons.tune_rounded, color: Colors.white),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerSettingsScreen()));
                          },
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(38),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, size: 34, color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Điểm Danh Thông Minh',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Quét QR, xác thực vân tay và định vị GPS trong một chạm.',
                        style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(215), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -32),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_savedUser != null) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 54),
                                side: const BorderSide(color: AppTheme.primaryDark, width: 1.5),
                                foregroundColor: AppTheme.primaryDark,
                              ),
                              onPressed: _biometricLogin,
                              icon: const Icon(Icons.fingerprint_rounded, size: 26),
                              label: Text(
                                'Đăng nhập nhanh bằng $_bioLabel\n(${_savedUser!.fullName})',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Center(
                              child: Text('hoặc đăng nhập bằng mật khẩu',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const Text('Đăng nhập',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('Chọn vai trò để điền nhanh tài khoản thử nghiệm',
                              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildPresetChip('Student', 'Sinh viên', AppTheme.success, 'sinhvien', '123'),
                              const SizedBox(width: 8),
                              _buildPresetChip('Lecturer', 'Giảng viên', AppTheme.warning, 'giangvien', '123'),
                              const SizedBox(width: 8),
                              _buildPresetChip('Admin', 'Admin', AppTheme.danger, 'admin', '123'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên đăng nhập hoặc Email',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(height: 22),
                          LoadingButton(
                            loading: _isLoading,
                            onPressed: _login,
                            label: 'Tiếp tục với OTP',
                            icon: Icons.arrow_forward_rounded,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chưa có tài khoản?', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                          },
                          child: const Text('Đăng ký', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const Text(
                      'Nhóm 4 con mèo • Lý Như Ánh',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String key, String label, Color color, String u, String p) {
    final isSelected = _selectedRolePreset == key;
    final icon = key == 'Student'
        ? Icons.school_outlined
        : (key == 'Lecturer' ? Icons.co_present_outlined : Icons.admin_panel_settings_outlined);
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectPreset(key, u, p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(24) : AppTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? color : AppTheme.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
