import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Header gradient dùng chung cho các màn hình chính.
class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;
  final Widget? bottom;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(36), borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconTheme(data: const IconThemeData(color: Colors.white), child: Row(children: actions)),
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 18), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô thống kê nhỏ nằm trong header.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  const StatTile({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.white.withAlpha(210), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Thẻ nội dung bo tròn có bóng nhẹ.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
      );
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  const IconBadge({super.key, required this.icon, required this.color, required this.bg, this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const StatusPill({super.key, required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppTheme.primaryDark.withAlpha(20), shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 14),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      );
}

/// Nút chính có trạng thái loading, giữ chiều cao cố định.
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  const LoadingButton({super.key, required this.loading, required this.onPressed, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Text(label),
            ],
          );
    return ElevatedButton(onPressed: loading ? null : onPressed, child: child);
  }
}
