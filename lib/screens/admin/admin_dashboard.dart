import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/classroom_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';
import 'classroom_form_screen.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  Future<void> _openSettings() async {
    final updated = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(user: widget.user)),
    );
    if (updated != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminDashboard(user: updated)),
      );
    }
  }

  late TabController _tabController;
  List<ClassRoomModel> _classRooms = [];
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final rooms = await ApiService.getClassRooms();
    final users = await ApiService.getUsers();
    if (!mounted) return;
    setState(() {
      _classRooms = rooms;
      _users = users;
      _isLoading = false;
    });
  }

  void _toast(String msg, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? AppTheme.success : AppTheme.danger),
    );
  }

  Future<bool> _confirm(String message) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, minimumSize: const Size(88, 44)),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    return r == true;
  }

  void _deleteClass(ClassRoomModel room) async {
    if (!await _confirm('Bạn có chắc muốn xóa môn "${room.courseName}" (${room.courseCode})?')) return;
    final ok = await ApiService.deleteClassRoom(room.id);
    if (!mounted) return;
    if (ok) {
      _toast('Đã xóa lớp học thành công!');
      _loadData();
    } else {
      _toast('Không xóa được lớp học', ok: false);
    }
  }

  void _deleteUser(UserModel u) async {
    if (u.id == widget.user.id) {
      _toast('Không thể xóa tài khoản đang đăng nhập', ok: false);
      return;
    }
    if (!await _confirm('Xóa tài khoản "${u.fullName}" (${u.username})?')) return;
    final ok = await ApiService.deleteUser(u.id);
    if (!mounted) return;
    if (ok) {
      _toast('Đã xóa người dùng');
      _loadData();
    } else {
      _toast('Không xóa được người dùng', ok: false);
    }
  }

  void _editUser(UserModel u) async {
    final nameCtl = TextEditingController(text: u.fullName);
    final mailCtl = TextEditingController(text: u.email);
    String role = u.role;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Sửa: ${u.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Họ và tên')),
                const SizedBox(height: 12),
                TextField(controller: mailCtl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Vai trò'),
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Sinh viên')),
                    DropdownMenuItem(value: 'Lecturer', child: Text('Giảng viên')),
                    DropdownMenuItem(value: 'Admin', child: Text('Quản trị viên')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(88, 44)),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final ok = await ApiService.updateUser(u.id, fullName: nameCtl.text.trim(), email: mailCtl.text.trim(), role: role);
    if (!mounted) return;
    if (ok) {
      _toast('Đã cập nhật người dùng');
      _loadData();
    } else {
      _toast('Không cập nhật được người dùng', ok: false);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Future<void> _openForm([ClassRoomModel? room]) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => ClassRoomFormScreen(classRoom: room)));
    if (res == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Quản trị hệ thống',
            subtitle: widget.user.fullName,
            icon: Icons.admin_panel_settings_rounded,
            actions: [
              IconButton(tooltip: 'Làm mới', icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
              IconButton(tooltip: 'Cài đặt', icon: const Icon(Icons.settings_rounded), onPressed: _openSettings),
              IconButton(
                  tooltip: 'Đăng xuất', icon: const Icon(Icons.logout_rounded), onPressed: _logout),
            ],
            bottom: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  StatTile(value: '${_classRooms.length}', label: 'Lớp học'),
                  const SizedBox(width: 10),
                  StatTile(value: '${_users.length}', label: 'Người dùng'),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryDark,
            indicatorWeight: 3,
            labelColor: AppTheme.primaryDark,
            unselectedLabelColor: AppTheme.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [Tab(text: 'Lớp học'), Tab(text: 'Người dùng')],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(controller: _tabController, children: [_buildClassTab(), _buildUserTab()]),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm môn học', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _openForm(),
            )
          : null,
    );
  }

  Widget _buildClassTab() {
    if (_classRooms.isEmpty) {
      return const EmptyState(icon: Icons.class_outlined, message: 'Chưa có lớp học nào.\nBấm "Thêm môn học" để tạo.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
      itemCount: _classRooms.length,
      itemBuilder: (context, index) {
        final c = _classRooms[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
          child: Row(
            children: [
              const IconBadge(icon: Icons.menu_book_rounded, color: AppTheme.primaryDark, bg: Color(0xFFD9F1EE)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.courseName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 3),
                    Text('${c.courseCode} • Phòng ${c.roomName}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('GV: ${c.lecturerName} • Bán kính ${c.allowedRadiusMeters.toStringAsFixed(0)}m',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Sửa',
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.accentBlue),
                onPressed: () => _openForm(c),
              ),
              IconButton(
                tooltip: 'Xóa',
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                onPressed: () => _deleteClass(c),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTab() {
    if (_users.isEmpty) {
      return const EmptyState(icon: Icons.people_outline_rounded, message: 'Chưa có người dùng nào.');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final u = _users[index];
        Color roleColor = AppTheme.success;
        Color roleBg = AppTheme.successBg;
        String roleLabel = 'Sinh viên';
        if (u.role == 'Admin') {
          roleColor = AppTheme.danger;
          roleBg = AppTheme.dangerBg;
          roleLabel = 'Quản trị';
        } else if (u.role == 'Lecturer') {
          roleColor = AppTheme.warning;
          roleBg = AppTheme.warningBg;
          roleLabel = 'Giảng viên';
        }
        return AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleBg,
                child: Text(
                  u.fullName.isNotEmpty ? u.fullName.substring(0, 1).toUpperCase() : 'U',
                  style: TextStyle(color: roleColor, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${u.username} • ${u.email}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    StatusPill(text: roleLabel, color: roleColor, bg: roleBg),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (v) => v == 'edit' ? _editUser(u) : _deleteUser(u),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Sửa / đổi vai trò')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.danger), SizedBox(width: 8), Text('Xóa')])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
