import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../models/session_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'dynamic_qr_screen.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class LecturerDashboard extends StatefulWidget {
  final UserModel user;

  const LecturerDashboard({super.key, required this.user});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  Future<void> _openSettings() async {
    final updated = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
    );
    if (updated != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LecturerDashboard(user: updated)),
      );
    }
  }

  List<ClassRoomModel> _myClasses = [];
  List<AttendanceSessionModel> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final classes = await ApiService.getClassRooms();
    final sessions = await ApiService.getSessions();
    setState(() {
      _myClasses = classes;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  void _openNewSessionDialog() async {
    if (_myClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có lớp học nào. Hãy nhờ Admin tạo lớp trước!')),
      );
      return;
    }

    int selectedClassId = _myClasses.first.id;
    final titleController = TextEditingController(text: 'Ca điểm danh ngày ${DateTime.now().day}/${DateTime.now().month}');
    int duration = 45;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Mở Phiên Điểm Danh Mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: selectedClassId,
                  decoration: const InputDecoration(labelText: 'Chọn Lớp học phần'),
                  items: _myClasses.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.courseCode} - ${c.courseName}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedClassId = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề ca học'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: duration,
                  decoration: const InputDecoration(labelText: 'Thời lượng mở quét'),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 phút')),
                    DropdownMenuItem(value: 30, child: Text('30 phút')),
                    DropdownMenuItem(value: 45, child: Text('45 phút')),
                    DropdownMenuItem(value: 60, child: Text('60 phút')),
                  ],
                  onChanged: (val) => setDialogState(() => duration = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                Navigator.pop(ctx);
                final res = await ApiService.startSession(selectedClassId, titleController.text.trim(), duration);
                if (res['success'] == true && res['session'] != null) {
                  _loadData();
                  final newSession = AttendanceSessionModel.fromJson(res['session']);
                  if (!mounted) return;
                  nav.push(
                    MaterialPageRoute(builder: (_) => DynamicQrScreen(session: newSession)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
              child: const Text('TẠO MÃ QR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _sessions.where((x) => x.isActive && x.expireAt.isAfter(DateTime.now())).length;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            GradientHeader(
              title: widget.user.fullName,
              subtitle: 'Giảng viên • ${widget.user.email}',
              icon: Icons.co_present_rounded,
              actions: [
                IconButton(tooltip: 'Làm mới', icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
                IconButton(tooltip: 'Cài đặt', icon: const Icon(Icons.settings_rounded), onPressed: _openSettings),
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
                    StatTile(value: '${_myClasses.length}', label: 'Lớp học phần'),
                    const SizedBox(width: 10),
                    StatTile(value: '$openCount', label: 'Ca đang mở'),
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
                    onPressed: _openNewSessionDialog,
                    icon: const Icon(Icons.qr_code_2_rounded, size: 24),
                    label: const Text('Mở ca điểm danh mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 22),
                  const SectionTitle('Các ca điểm danh gần đây'),
                  if (_isLoading)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                  else if (_sessions.isEmpty)
                    const AppCard(child: EmptyState(icon: Icons.qr_code_2_rounded, message: 'Chưa có ca điểm danh nào được tạo.'))
                  else
                    ..._sessions.map((s) {
                      final live = s.isActive && s.expireAt.isAfter(DateTime.now());
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            IconBadge(
                              icon: Icons.qr_code_rounded,
                              color: live ? AppTheme.success : AppTheme.textMuted,
                              bg: live ? AppTheme.successBg : AppTheme.background,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.className,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(s.sessionTitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  StatusPill(
                                    text: live ? 'Đang mở' : 'Đã đóng',
                                    color: live ? AppTheme.success : AppTheme.textSecondary,
                                    bg: live ? AppTheme.successBg : AppTheme.background,
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(84, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicQrScreen(session: s)));
                              },
                              child: const Text('Xem QR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
