import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lynhuanh/main.dart';
import 'package:lynhuanh/theme/app_theme.dart';
import 'package:lynhuanh/widgets/app_widgets.dart';

void main() {
  testWidgets('Màn hình đăng nhập hiển thị đúng', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    expect(find.text('Điểm Danh Thông Minh'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.text('Tiếp tục với OTP'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Chọn vai trò điền sẵn tài khoản', (WidgetTester tester) async {
    await tester.pumpWidget(const AttendanceApp());
    await tester.tap(find.text('Giảng viên'));
    await tester.pump();
    expect(find.text('giangvien'), findsOneWidget);
    await tester.tap(find.text('Admin'));
    await tester.pump();
    expect(find.text('admin'), findsOneWidget);
  });

  testWidgets('Widget dùng chung: EmptyState và StatusPill', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme,
      home: const Scaffold(
        body: Column(children: [
          EmptyState(icon: Icons.event_busy_rounded, message: 'Trống'),
          StatusPill(text: 'Đang mở', color: AppTheme.success, bg: AppTheme.successBg),
        ]),
      ),
    ));
    expect(find.text('Trống'), findsOneWidget);
    expect(find.text('Đang mở'), findsOneWidget);
  });
}
