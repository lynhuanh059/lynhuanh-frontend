import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'qr_scanner_screen.dart';
import 'student_history_screen.dart';
import '../auth/login_screen.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;

  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<AttendanceSessionModel> _activeSessions = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() async {
    setState(() => _isLoading = true);
    final all = await ApiService.getSessions();
    setState(() {
      _activeSessions = all.where((s) => s.isActive && s.expireAt.isAfter(DateTime.now())).toList();
      _isLoading = false;
    });
  }

  Future<void> _openScanner(int? sessionId) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QrScannerScreen(student: widget.user, preselectedSessionId: sessionId)),
    );
    if (res == true) _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async => _loadSessions(),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            GradientHeader(
              title: 'Xin chào, ${widget.user.fullName}',
              subtitle: 'Mã SV: ${widget.user.username}',
              icon: Icons.school_rounded,
              actions: [
                IconButton(
                  tooltip: 'Lịch sử điểm danh',
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentHistoryScreen(student: widget.user)));
                  },
                ),
                IconButton(
                  tooltip: 'Đăng xuất',
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ],
              bottom: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    StatTile(value: '${_activeSessions.length}', label: 'Ca đang mở'),
                    const SizedBox(width: 10),
                    const StatTile(value: 'Bật', label: 'GPS & vân tay'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 58)),
                    onPressed: () => _openScanner(_activeSessions.isNotEmpty ? _activeSessions.first.id : null),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                    label: const Text('Quét mã QR điểm danh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.graphic_eq_rounded, size: 16, color: AppTheme.textMuted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Khi điểm danh, app đo độ ồn lớp học bằng micro (chỉ đo mức âm thanh, không ghi âm).',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle('Ca học đang mở điểm danh'),
                  if (_isLoading)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                  else if (_activeSessions.isEmpty)
                    const AppCard(
                      child: EmptyState(icon: Icons.event_busy_rounded, message: 'Hiện không có ca học nào đang mở.\nKéo xuống để làm mới.'),
                    )
                  else
                    ..._activeSessions.map(
                      (s) => AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const IconBadge(icon: Icons.menu_book_rounded, color: AppTheme.success, bg: AppTheme.successBg),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.className,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(s.sessionTitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                minimumSize: const Size(96, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _openScanner(s.id),
                              child: const Text('Điểm danh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
