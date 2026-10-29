import 'json_date.dart';

class AttendanceSessionModel {
  final int id;
  final int classRoomId;
  final String className;
  final String sessionTitle;
  final DateTime createdAt;
  final DateTime expireAt;
  final String dynamicQrToken;
  final bool isActive;

  AttendanceSessionModel({
    required this.id,
    required this.classRoomId,
    required this.className,
    required this.sessionTitle,
    required this.createdAt,
    required this.expireAt,
    required this.dynamicQrToken,
    required this.isActive,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id'] ?? 0,
      classRoomId: json['classRoomId'] ?? 0,
      className: json['className'] ?? '',
      sessionTitle: json['sessionTitle'] ?? '',
      createdAt: parseServerTime(json['createdAt']) ?? DateTime.now(),
      expireAt: parseServerTime(json['expireAt']) ?? DateTime.now(),
      dynamicQrToken: json['dynamicQrToken'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
