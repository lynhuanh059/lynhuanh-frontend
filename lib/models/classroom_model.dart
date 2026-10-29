class ClassRoomModel {
  final int id;
  final String courseCode;
  final String courseName;
  final String roomName;
  final int lecturerId;
  final String lecturerName;
  final double latitude;
  final double longitude;
  final double allowedRadiusMeters;

  ClassRoomModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.roomName,
    required this.lecturerId,
    required this.lecturerName,
    required this.latitude,
    required this.longitude,
    required this.allowedRadiusMeters,
  });

  factory ClassRoomModel.fromJson(Map<String, dynamic> json) {
    return ClassRoomModel(
      id: json['id'] ?? 0,
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      roomName: json['roomName'] ?? '',
      lecturerId: json['lecturerId'] ?? 0,
      lecturerName: json['lecturerName'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.7769,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.7009,
      allowedRadiusMeters: (json['allowedRadiusMeters'] as num?)?.toDouble() ?? 50.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseCode': courseCode,
    'courseName': courseName,
    'roomName': roomName,
    'lecturerId': lecturerId,
    'lecturerName': lecturerName,
    'latitude': latitude,
    'longitude': longitude,
    'allowedRadiusMeters': allowedRadiusMeters,
  };
}
