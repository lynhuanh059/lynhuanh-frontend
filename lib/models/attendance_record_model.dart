import 'json_date.dart';

class AttendanceRecordModel {
  final int id;
  final int sessionId;
  final int studentId;
  final String studentName;
  final String studentCode;
  final DateTime checkInTime;
  final double studentLatitude;
  final double studentLongitude;
  final double distanceMeters;
  final String status; // Present, Late, Absent
  final String method; // QR_GPS, Biometric_QR_GPS
  final double? noiseDb; // độ ồn lớp học (dB), có thể null

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.checkInTime,
    required this.studentLatitude,
    required this.studentLongitude,
    required this.distanceMeters,
    required this.status,
    required this.method,
    this.noiseDb,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] ?? 0,
      sessionId: json['sessionId'] ?? 0,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      checkInTime: parseServerTime(json['checkInTime']) ?? DateTime.now(),
      studentLatitude: (json['studentLatitude'] as num?)?.toDouble() ?? 0.0,
      studentLongitude: (json['studentLongitude'] as num?)?.toDouble() ?? 0.0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Present',
      method: json['method'] ?? 'QR_GPS',
      noiseDb: (json['noiseDb'] as num?)?.toDouble(),
    );
  }
}
