import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/json_date.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class StudentHistoryScreen extends StatefulWidget {
  final UserModel student;

  const StudentHistoryScreen({super.key, required this.student});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getStudentHistory(widget.student.id);
    setState(() {
      _history = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chuyên cần'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadHistory)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const EmptyState(icon: Icons.history_toggle_off_rounded, message: 'Bạn chưa có bản ghi điểm danh nào.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final checkInTime = parseServerTime(item['checkInTime']) ?? DateTime.now();
                    final isPresent = (item['status'] ?? 'Present') == 'Present';
                    final color = isPresent ? AppTheme.success : AppTheme.warning;
                    final bg = isPresent ? AppTheme.successBg : AppTheme.warningBg;
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          IconBadge(icon: isPresent ? Icons.check_rounded : Icons.alarm_rounded, color: color, bg: bg),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['className'] ?? 'Môn học',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                                const SizedBox(height: 2),
                                Text('${item['sessionTitle']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(DateFormat('HH:mm • dd/MM/yyyy').format(checkInTime.toLocal()),
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusPill(text: isPresent ? 'Có mặt' : 'Đi trễ', color: color, bg: bg),
                              const SizedBox(height: 6),
                              Text('Cách ${item['distanceMeters']}m', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
