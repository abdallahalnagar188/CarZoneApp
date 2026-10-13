import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';

class MapPin extends StatelessWidget {
  final bool open;
  final bool selected;
  final VoidCallback onTap;

  const MapPin({super.key, required this.open, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = selected ? 46.0 : 38.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: open ? AppColors.primaryGradient : null,
              color: open ? null : AppColors.ink500,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: AppColors.liftShadow,
            ),
            child: Icon(Iconsax.car, color: Colors.white, size: size * 0.45),
          ),
          CustomPaint(size: const Size(12, 8), painter: _Tail(open ? AppColors.brand : AppColors.ink500)),
        ],
      ),
    );
  }
}

class _Tail extends CustomPainter {
  final Color color;

  _Tail(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _Tail oldDelegate) => oldDelegate.color != color;
}

class UserDot extends StatelessWidget {
  const UserDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent.withValues(alpha: 0.25),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}
