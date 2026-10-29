import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Student';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
      );

      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký tài khoản thành công! Vui lòng đăng nhập.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Đăng ký thất bại'), backgroundColor: AppTheme.danger),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối Server: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Tạo tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Đăng ký bằng email',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Mã OTP đăng nhập sẽ được gửi tới email bạn nhập.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.alternate_email_rounded, size: 20)),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Tên đăng nhập / Mã SV', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
                        validator: (v) => (v == null || v.length < 3) ? 'Mật khẩu ít nhất 3 ký tự' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: const InputDecoration(labelText: 'Vai trò', prefixIcon: Icon(Icons.security_outlined, size: 20)),
                        items: const [
                          DropdownMenuItem(value: 'Student', child: Text('Sinh viên')),
                          DropdownMenuItem(value: 'Lecturer', child: Text('Giảng viên')),
                        ],
                        onChanged: (val) => setState(() => _selectedRole = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                LoadingButton(loading: _isLoading, onPressed: _submit, label: 'Hoàn tất đăng ký', icon: Icons.check_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
