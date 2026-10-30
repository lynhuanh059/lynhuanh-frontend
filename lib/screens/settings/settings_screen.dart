import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/biometric_login_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Màn hình "Cài đặt": đổi cỡ chữ, màu nền, cập nhật hồ sơ cá nhân,
/// bật/tắt đăng nhập bằng khuôn mặt / vân tay.
class SettingsScreen extends StatefulWidget {
  final UserModel user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = AppSettings.instance;
  late UserModel _user;
  late final TextEditingController _nameCtl;
  late final TextEditingController _mailCtl;
  bool _saving = false;
  bool _profileChanged = false;

  bool _bioSupported = false;
  bool _bioEnabled = false;
  String _bioLabel = 'khuôn mặt / vân tay';

  static const _fontPresets = <String, double>{
    'Nhỏ': 0.9,
    'Vừa': 1.0,
    'Lớn': 1.2,
    'Rất lớn': 1.4,
  };

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _nameCtl = TextEditingController(text: _user.fullName);
    _mailCtl = TextEditingController(text: _user.email);
    _loadBiometric();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _mailCtl.dispose();
    super.dispose();
  }

  Future<void> _loadBiometric() async {
    final supported = await BiometricLoginService.isSupported();
    final label = await BiometricLoginService.label();
    final saved = await BiometricLoginService.savedUser();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioLabel = label;
      _bioEnabled = saved != null && saved.id == _user.id;
    });
  }

  void _toast(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? AppTheme.success : AppTheme.danger),
    );
  }

  Future<void> _toggleBiometric(bool on) async {
    if (on) {
      final ok = await BiometricLoginService.authenticate();
      if (!ok) {
        _toast('Chưa xác thực được $_bioLabel', ok: false);
        return;
      }
      await BiometricLoginService.enable(_user);
      _toast('Đã bật đăng nhập bằng $_bioLabel');
    } else {
      await BiometricLoginService.disable();
      _toast('Đã tắt đăng nhập bằng $_bioLabel');
    }
    if (mounted) setState(() => _bioEnabled = on);
  }

  Future<void> _saveProfile() async {
    final name = _nameCtl.text.trim();
    final mail = _mailCtl.text.trim();
    if (name.isEmpty) {
      _toast('Họ tên không được để trống', ok: false);
      return;
    }
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail);
    if (!emailOk) {
      _toast('Email không hợp lệ', ok: false);
      return;
    }
    setState(() => _saving = true);
    bool ok = false;
    try {
      ok = await ApiService.updateUser(_user.id, fullName: name, email: mail, role: _user.role);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      _user = UserModel(id: _user.id, username: _user.username, fullName: name, email: mail, role: _user.role);
      _profileChanged = true;
      await BiometricLoginService.refreshIfEnabled(_user);
      _toast('Đã cập nhật hồ sơ cá nhân');
    } else {
      _toast('Không cập nhật được hồ sơ. Kiểm tra kết nối mạng và thử lại', ok: false);
    }
  }

  String get _roleName {
    switch (_user.role) {
      case 'Admin':
        return 'Quản trị viên';
      case 'Lecturer':
        return 'Giảng viên';
      default:
        return 'Sinh viên';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _profileChanged ? _user : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cài đặt'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _profileChanged ? _user : null),
          ),
        ),
        body: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              const SectionTitle('Hồ sơ cá nhân'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primaryDark,
                          child: Text(
                            _user.fullName.isNotEmpty ? _user.fullName.trim()[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${_user.username}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                              Text(_roleName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mailCtl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LoadingButton(
                      loading: _saving,
                      onPressed: _saveProfile,
                      label: 'Lưu hồ sơ',
                      icon: Icons.save_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Cỡ chữ'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields_rounded, size: 18, color: AppTheme.textSecondary),
                        Expanded(
                          child: Slider(
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            value: _settings.fontScale,
                            label: '${(_settings.fontScale * 100).round()}%',
                            onChanged: (v) => _settings.setFontScale(v),
                          ),
                        ),
                        Text('${(_settings.fontScale * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _fontPresets.entries.map((e) {
                        final selected = (_settings.fontScale - e.value).abs() < 0.01;
                        return ChoiceChip(
                          label: Text(e.key),
                          selected: selected,
                          onSelected: (_) => _settings.setFontScale(e.value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Xem trước: Điểm danh thông minh bằng QR, vân tay và GPS.',
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Màu nền'),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: List.generate(AppSettings.backgrounds.length, (i) {
                        final selected = _settings.bgIndex == i;
                        return GestureDetector(
                          onTap: () => _settings.setBackground(i),
                          child: Tooltip(
                            message: AppSettings.backgroundNames[i],
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppSettings.backgrounds[i],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? AppTheme.primaryDark : AppTheme.border,
                                  width: selected ? 3 : 1.5,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryDark)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text('Đang chọn: ${AppSettings.backgroundNames[_settings.bgIndex]}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Bảo mật'),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text('Đăng nhập bằng $_bioLabel',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    _bioSupported
                        ? 'Lần sau chỉ cần xác thực sinh trắc học, không cần nhập mật khẩu và OTP.'
                        : 'Thiết bị chưa hỗ trợ hoặc chưa cài khuôn mặt / vân tay.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  value: _bioEnabled,
                  onChanged: _bioSupported ? _toggleBiometric : null,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _settings.reset(),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Khôi phục giao diện mặc định'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
