import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record_model.dart';
import '../../services/api_service.dart';
import '../../services/noise_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class SessionRecordsScreen extends StatefulWidget {
  final int sessionId;
  final String sessionTitle;

  const SessionRecordsScreen({super.key, required this.sessionId, required this.sessionTitle});

  @override
  State<SessionRecordsScreen> createState() => _SessionRecordsScreenState();
}

class _SessionRecordsScreenState extends State<SessionRecordsScreen> {
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getSessionRecords(widget.sessionId);
    setState(() {
      _records = list;
      _isLoading = false;
    });
  }

  void _editStatus(AttendanceRecordModel record) async {
    String selectedStatus = record.status;
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cập nhật: ${record.studentName}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => RadioGroup<String>(
            groupValue: selectedStatus,
            onChanged: (val) => setDialogState(() => selectedStatus = val!),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(title: Text('Có mặt (Present)'), value: 'Present'),
                RadioListTile<String>(title: Text('Đi trễ (Late)'), value: 'Late'),
                RadioListTile<String>(title: Text('Vắng mặt (Absent)'), value: 'Absent'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selectedStatus),
            child: const Text('LƯU'),
          ),
        ],
      ),
    );

    if (res != null && res != record.status) {
      final ok = await ApiService.updateRecordStatus(record.id, res);
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái điểm danh!'), backgroundColor: AppTheme.success),
        );
        _loadRecords();
      }
    }
  }

  void _deleteRecord(AttendanceRecordModel record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa bản ghi của "${record.studentName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            child: const Text('XÓA'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await ApiService.deleteRecord(record.id);
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bản ghi thành công!'), backgroundColor: AppTheme.success),
        );
        _loadRecords();
      }
    }
  }

  // Thẻ tóm tắt độ ồn trung bình của cả lớp
  Widget _buildNoiseSummary() {
    final values = _records.where((r) => r.noiseDb != null).map((r) => r.noiseDb!).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final avg = values.reduce((a, b) => a + b) / values.length;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const IconBadge(icon: Icons.graphic_eq_rounded, color: AppTheme.primaryDark, bg: Color(0xFFD9F1EE)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Độ ồn trung bình của lớp',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text('${avg.toStringAsFixed(0)} dB • ${NoiseService.describe(avg)} (${values.length} lượt đo)',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionTitle),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadRecords)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const EmptyState(icon: Icons.groups_2_outlined, message: 'Chưa có sinh viên nào điểm danh trong ca này.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: _records.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildNoiseSummary();
                    final r = _records[index - 1];
                    final isPresent = r.status == 'Present';
                    final isLate = r.status == 'Late';
                    final color = isPresent ? AppTheme.success : (isLate ? AppTheme.warning : AppTheme.danger);
                    final bg = isPresent ? AppTheme.successBg : (isLate ? AppTheme.warningBg : AppTheme.dangerBg);
                    final text = isPresent ? 'Có mặt' : (isLate ? 'Đi trễ' : 'Vắng');
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                      child: Row(
                        children: [
                          IconBadge(icon: isPresent ? Icons.check_rounded : (isLate ? Icons.alarm_rounded : Icons.close_rounded), color: color, bg: bg),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.studentName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                                const SizedBox(height: 3),
                                Text(DateFormat('HH:mm:ss • dd/MM').format(r.checkInTime.toLocal()),
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Text('Cách phòng ${r.distanceMeters}m${r.noiseDb != null ? ' • Ồn ${r.noiseDb!.toStringAsFixed(0)} dB' : ''}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          StatusPill(text: text, color: color, bg: bg),
                          PopupMenuButton<String>(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (val) {
                              if (val == 'edit') _editStatus(r);
                              if (val == 'delete') _deleteRecord(r);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Sửa trạng thái')])),
                              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.danger), SizedBox(width: 8), Text('Xóa')])),
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
