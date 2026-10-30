import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Đăng nhập nhanh bằng khuôn mặt / vân tay cho các lần đăng nhập sau.
/// Lần đầu vẫn phải đăng nhập bằng mật khẩu + OTP, sau đó người dùng bật tính năng này.
class BiometricLoginService {
  static const _kUser = 'biometric_login_user';
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Nhãn hiển thị theo loại sinh trắc học máy có.
  static Future<String> label() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      final face = types.contains(BiometricType.face);
      final finger = types.contains(BiometricType.fingerprint);
      if (face && finger) return 'khuôn mặt / vân tay';
      if (face) return 'khuôn mặt';
      if (finger) return 'vân tay';
    } catch (_) {}
    return 'khuôn mặt / vân tay';
  }

  static Future<UserModel?> savedUser() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kUser);
      if (raw == null || raw.isEmpty) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> enable(UserModel user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUser, jsonEncode(user.toJson()));
  }

  static Future<void> disable() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kUser);
  }

  /// Cập nhật bản lưu khi hồ sơ đổi (chỉ khi đã bật cho đúng tài khoản này).
  static Future<void> refreshIfEnabled(UserModel user) async {
    final saved = await savedUser();
    if (saved != null && saved.id == user.id) await enable(user);
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Xác thực khuôn mặt hoặc vân tay để đăng nhập',
      );
    } catch (_) {
      return false;
    }
  }
}
