/// Server trả thời gian ở dạng UTC nhưng có thể thiếu hậu tố "Z" (SQL Server).
/// Hàm này luôn coi chuỗi không có múi giờ là UTC rồi đổi sang giờ máy.
DateTime? parseServerTime(dynamic value) {
  if (value == null) return null;
  var s = value.toString().trim();
  if (s.isEmpty) return null;
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  if (!hasZone) s = '${s}Z';
  return DateTime.tryParse(s)?.toLocal();
}
