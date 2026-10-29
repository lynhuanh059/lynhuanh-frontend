import 'package:flutter/material.dart';
import '../../models/classroom_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ClassRoomFormScreen extends StatefulWidget {
  final ClassRoomModel? classRoom;

  const ClassRoomFormScreen({super.key, this.classRoom});

  @override
  State<ClassRoomFormScreen> createState() => _ClassRoomFormScreenState();
}

class _ClassRoomFormScreenState extends State<ClassRoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _latController = TextEditingController(text: '10.7769');
  final _lonController = TextEditingController(text: '106.7009');
  final _radiusController = TextEditingController(text: '100');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.classRoom != null) {
      _codeController.text = widget.classRoom!.courseCode;
      _nameController.text = widget.classRoom!.courseName;
      _roomController.text = widget.classRoom!.roomName;
      _lecturerController.text = widget.classRoom!.lecturerName;
      _latController.text = widget.classRoom!.latitude.toString();
      _lonController.text = widget.classRoom!.longitude.toString();
      _radiusController.text = widget.classRoom!.allowedRadiusMeters.toString();
    }
  }

  void _getCurrentLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _latController.text = pos.latitude.toStringAsFixed(6);
        _lonController.text = pos.longitude.toStringAsFixed(6);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật tọa độ GPS phòng học thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final room = ClassRoomModel(
      id: widget.classRoom?.id ?? 0,
      courseCode: _codeController.text.trim(),
      courseName: _nameController.text.trim(),
      roomName: _roomController.text.trim(),
      lecturerId: widget.classRoom?.lecturerId ?? 2,
      lecturerName: _lecturerController.text.trim(),
      latitude: double.tryParse(_latController.text.trim()) ?? 10.7769,
      longitude: double.tryParse(_lonController.text.trim()) ?? 106.7009,
      allowedRadiusMeters: double.tryParse(_radiusController.text.trim()) ?? 100.0,
    );

    bool ok;
    if (widget.classRoom == null) {
      ok = await ApiService.createClassRoom(room);
    } else {
      ok = await ApiService.updateClassRoom(room.id, room);
    }

    setState(() => _isLoading = false);

    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.classRoom == null ? 'Thêm lớp học thành công!' : 'Cập nhật lớp học thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thao tác thất bại!'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.classRoom != null;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(isEdit ? 'Chỉnh sửa lớp học' : 'Thêm lớp học')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Thông tin học phần'),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Mã môn học (VD: LTDD01)'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mã môn' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tên môn học'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên môn' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _roomController,
                              decoration: const InputDecoration(labelText: 'Phòng (B205)'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Nhập phòng' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lecturerController,
                              decoration: const InputDecoration(labelText: 'Giảng viên'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Nhập giảng viên' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: SectionTitle('Vị trí phòng học (GPS)')),
                    TextButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: const Text('Lấy vị trí của tôi'),
                    ),
                  ],
                ),
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(labelText: 'Vĩ độ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lonController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(labelText: 'Kinh độ'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _radiusController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Bán kính hợp lệ (mét)',
                          helperText: 'Sinh viên ở xa hơn bán kính này sẽ không điểm danh được',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                LoadingButton(
                  loading: _isLoading,
                  onPressed: _save,
                  label: isEdit ? 'Lưu cập nhật' : 'Tạo môn học',
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
