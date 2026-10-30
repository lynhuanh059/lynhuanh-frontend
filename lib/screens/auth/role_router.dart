import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../lecturer/lecturer_dashboard.dart';
import '../student/student_dashboard.dart';

/// Chọn màn hình chính theo vai trò (Admin / Giảng viên / Sinh viên).
Widget dashboardFor(UserModel user) {
  if (user.role == 'Admin') return AdminDashboard(user: user);
  if (user.role == 'Lecturer') return LecturerDashboard(user: user);
  return StudentDashboard(user: user);
}
