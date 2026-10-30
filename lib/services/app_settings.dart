import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cài đặt giao diện toàn app: cỡ chữ + màu nền. Lưu bằng SharedPreferences.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kFont = 'setting_font_scale';
  static const _kBg = 'setting_bg_index';

  static const List<Color> backgrounds = [
    Color(0xFFF3F7F6),
    Color(0xFFFFFFFF),
    Color(0xFFFFF6E5),
    Color(0xFFE8F1FF),
    Color(0xFFFDEBF1),
    Color(0xFFEFEAFB),
    Color(0xFFE6F7EA),
  ];
  static const List<String> backgroundNames = [
    'Xanh ngọc nhạt',
    'Trắng',
    'Kem',
    'Xanh trời',
    'Hồng phấn',
    'Tím nhạt',
    'Xanh lá nhạt',
  ];

  double fontScale = 1.0;
  int bgIndex = 0;

  Color get background => backgrounds[bgIndex];

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      fontScale = (p.getDouble(_kFont) ?? 1.0).clamp(0.8, 1.5);
      final i = p.getInt(_kBg) ?? 0;
      bgIndex = (i >= 0 && i < backgrounds.length) ? i : 0;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v.clamp(0.8, 1.5);
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_kFont, fontScale);
    } catch (_) {}
  }

  Future<void> setBackground(int index) async {
    bgIndex = index;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kBg, index);
    } catch (_) {}
  }

  Future<void> reset() async {
    await setFontScale(1.0);
    await setBackground(0);
  }
}
