import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _urlController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  void _loadUrl() async {
    final current = await ApiService.getBaseUrl();
    setState(() {
      _urlController.text = current;
      _loading = false;
    });
  }

  void _save() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;
    await ApiService.setBaseUrl(newUrl);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu cấu hình địa chỉ Server API thành công!'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Máy chủ API')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Địa chỉ Backend API',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Ứng dụng cần kết nối tới API đã deploy (hosting / VPS), không dùng localhost.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 18),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _urlController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(labelText: 'Base API URL', prefixIcon: Icon(Icons.dns_outlined, size: 20)),
                          ),
                          const SizedBox(height: 16),
                          const Text('Điền nhanh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (ApiService.kDeployedBaseUrl.isNotEmpty)
                                ActionChip(
                                  avatar: const Icon(Icons.cloud_done_outlined, size: 16),
                                  label: const Text('Server đã deploy'),
                                  onPressed: () => setState(() => _urlController.text = ApiService.kDeployedBaseUrl),
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.phone_android_rounded, size: 16),
                                label: const Text('Máy ảo Android (dev)'),
                                onPressed: () => setState(() => _urlController.text = 'http://10.0.2.2:5055'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: const Text('Lưu và áp dụng'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
