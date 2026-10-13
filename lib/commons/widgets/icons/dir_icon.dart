import 'package:flutter/material.dart';

class DirIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const DirIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final child = Icon(icon, size: size, color: color);
    if (!rtl) return child;
    return Transform.flip(flipX: true, child: child);
  }
}
