import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/classroom_model.dart';
import '../models/session_model.dart';
import '../models/attendance_record_model.dart';

class ApiService {
  static const String _prefBaseUrlKey = 'custom_base_url';

  /// Địa chỉ API đã DEPLOY (hosting / VPS) theo yêu cầu đề: không dùng localhost.
  /// >>> Điền URL thật sau khi deploy backend, ví dụ: 'https://lynhuanh.onrender.com'
  static const String kDeployedBaseUrl = 'https://lynhuanh-backend.onrender.com';

  /// Địa chỉ dự phòng khi chưa điền kDeployedBaseUrl (chỉ để phát triển, KHÔNG nộp bài với giá trị này).
  static String getDefaultBaseUrl() {
    if (kDeployedBaseUrl.isNotEmpty) return kDeployedBaseUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5055';
    return 'http://localhost:5055';
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefBaseUrlKey) ?? getDefaultBaseUrl();
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefBaseUrlKey, url.trim());
  }

  // 1. Đăng nhập bước 1: gửi user + pass -> nhận OTP
  static Future<Map<String, dynamic>> login(String usernameOrEmail, String password) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usernameOrEmail': usernameOrEmail,
        'password': password,
      }),
    );
    return jsonDecode(res.body);
  }

  // 2. Đăng nhập bước 2: xác nhận OTP
  static Future<Map<String, dynamic>> verifyOtp(String usernameOrEmail, String otp) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/Auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usernameOrEmail': usernameOrEmail,
        'otp': otp,
      }),
    );
    return jsonDecode(res.body);
  }

  // 2b. Gửi lại OTP qua email
  static Future<Map<String, dynamic>> resendOtp(String usernameOrEmail) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/Auth/resend-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'usernameOrEmail': usernameOrEmail}),
    );
    return jsonDecode(res.body);
  }

  // 3. Đăng ký tài khoản
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String fullName,
    required String email,
    required String role,
  }) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/Auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'role': role,
      }),
    );
    return jsonDecode(res.body);
  }

  // 4. Lấy danh sách tài khoản (cho Admin)
  static Future<List<UserModel>> getUsers() async {
    final baseUrl = await getBaseUrl();
    final res = await http.get(Uri.parse('$baseUrl/api/Auth/users'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> updateUser(int id, {required String fullName, required String email, required String role}) async {
    final baseUrl = await getBaseUrl();
    final res = await http.put(
      Uri.parse('$baseUrl/api/Auth/users/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fullName': fullName, 'email': email, 'role': role}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteUser(int id) async {
    final baseUrl = await getBaseUrl();
    final res = await http.delete(Uri.parse('$baseUrl/api/Auth/users/$id'));
    return res.statusCode == 200;
  }

  // 5. CRUD Lớp học phần
  static Future<List<ClassRoomModel>> getClassRooms() async {
    final baseUrl = await getBaseUrl();
    final res = await http.get(Uri.parse('$baseUrl/api/ClassRoom'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => ClassRoomModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> createClassRoom(ClassRoomModel room) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/ClassRoom'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(room.toJson()),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  static Future<bool> updateClassRoom(int id, ClassRoomModel room) async {
    final baseUrl = await getBaseUrl();
    final res = await http.put(
      Uri.parse('$baseUrl/api/ClassRoom/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(room.toJson()),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteClassRoom(int id) async {
    final baseUrl = await getBaseUrl();
    final res = await http.delete(Uri.parse('$baseUrl/api/ClassRoom/$id'));
    return res.statusCode == 200;
  }

  // 6. Quản lý Phiên Điểm Danh
  static Future<Map<String, dynamic>> startSession(int classRoomId, String title, int durationMinutes) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/Attendance/start-session'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'classRoomId': classRoomId,
        'title': title,
        'durationMinutes': durationMinutes,
      }),
    );
    return jsonDecode(res.body);
  }

  /// Lấy mã QR động hiện tại (đổi mỗi 15 giây, do server tính).
  static Future<Map<String, dynamic>?> getQrToken(int sessionId) async {
    try {
      final baseUrl = await getBaseUrl();
      final res = await http.get(Uri.parse('$baseUrl/api/Attendance/qr-token/$sessionId'));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<List<AttendanceSessionModel>> getSessions() async {
    final baseUrl = await getBaseUrl();
    final res = await http.get(Uri.parse('$baseUrl/api/Attendance/sessions'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AttendanceSessionModel.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> closeSession(int id) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(Uri.parse('$baseUrl/api/Attendance/close-session/$id'));
    return res.statusCode == 200;
  }

  // 7. Sinh viên điểm danh (Quét QR + GPS + Anti-Cheat)
  static Future<Map<String, dynamic>> checkIn({
    required int sessionId,
    required int studentId,
    required String studentName,
    required String qrToken,
    required double studentLatitude,
    required double studentLongitude,
    required String method,
    double? noiseDb,
  }) async {
    final baseUrl = await getBaseUrl();
    final res = await http.post(
      Uri.parse('$baseUrl/api/Attendance/check-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': sessionId,
        'studentId': studentId,
        'studentName': studentName,
        'qrToken': qrToken,
        'studentLatitude': studentLatitude,
        'studentLongitude': studentLongitude,
        'method': method,
        'noiseDb': noiseDb,
      }),
    );
    return jsonDecode(res.body);
  }

  // 8. Lấy danh sách điểm danh của buổi học
  static Future<List<AttendanceRecordModel>> getSessionRecords(int sessionId) async {
    final baseUrl = await getBaseUrl();
    final res = await http.get(Uri.parse('$baseUrl/api/Attendance/records/$sessionId'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => AttendanceRecordModel.fromJson(e)).toList();
    }
    return [];
  }

  // 9. Lịch sử điểm danh sinh viên
  static Future<List<dynamic>> getStudentHistory(int studentId) async {
    final baseUrl = await getBaseUrl();
    final res = await http.get(Uri.parse('$baseUrl/api/Attendance/student-history/$studentId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  // 10. CRUD Trạng thái điểm danh
  static Future<bool> updateRecordStatus(int recordId, String status) async {
    final baseUrl = await getBaseUrl();
    final res = await http.put(
      Uri.parse('$baseUrl/api/Attendance/records/$recordId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> deleteRecord(int recordId) async {
    final baseUrl = await getBaseUrl();
    final res = await http.delete(Uri.parse('$baseUrl/api/Attendance/records/$recordId'));
    return res.statusCode == 200;
  }
}
