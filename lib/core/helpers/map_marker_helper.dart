import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

import '../constance/app_colors.dart';

enum PinState { normal, selected, closed }

class MapMarkerHelper {
  MapMarkerHelper._();

  static const double _ratio = 3;
  static final Map<String, BitmapDescriptor> _cache = {};
  static bool? _flipsY;

  /// Impeller's OpenGLES backend (Android emulators, phones without Vulkan)
  /// returns Picture.toImage upside down. Checked once with a 1x2 image whose
  /// top pixel is painted: when it reads back empty, markers are drawn pre-flipped.
  static Future<bool> _toImageFlipsY() async {
    if (_flipsY != null) return _flipsY!;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = const Color(0xFFFF0000));
    final image = await recorder.endRecording().toImage(1, 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return _flipsY = data == null ? false : data.getUint8(0) == 0;
  }

  /// A canvas in logical units ([_ratio] applied) for an image [height] tall,
  /// pre-flipped when this device's toImage comes back upside down.
  static Future<Canvas> _canvas(ui.PictureRecorder recorder, double height) async {
    final canvas = Canvas(recorder);
    if (await _toImageFlipsY()) {
      canvas
        ..translate(0, (height * _ratio).ceilToDouble())
        ..scale(1, -1);
    }
    return canvas..scale(_ratio);
  }

  static Future<BitmapDescriptor> pricePin(String label, PinState state) async {
    final key = 'price|$label|${state.name}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final selected = state == PinState.selected;
    final closed = state == PinState.closed;
    final scale = selected ? 1.15 : 1.0;
    final fontSize = 13.0 * scale;
    final iconBox = 24.0 * scale;
    final padH = 5.0 * scale;
    final height = 34.0 * scale;
    const tail = 8.0;
    const shadow = 6.0;

    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontFamily: 'IPM',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : (closed ? const Color(0xFF5B6B85) : AppColors.brandDeep),
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    final width = padH + iconBox + 6 * scale + text.width + 10 * scale;
    final canvasW = width + shadow * 2;
    final canvasH = height + tail + shadow * 2;

    final recorder = ui.PictureRecorder();
    final canvas = await _canvas(recorder, canvasH);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(shadow, shadow, width, height),
      Radius.circular(height / 2),
    );
    final tailPath = Path()
      ..moveTo(shadow + width / 2 - tail, shadow + height - 1)
      ..lineTo(shadow + width / 2, shadow + height + tail)
      ..lineTo(shadow + width / 2 + tail, shadow + height - 1)
      ..close();

    canvas.drawRRect(
      body.shift(const Offset(0, 2)),
      Paint()
        ..color = AppColors.brandNight.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    final fill = Paint();
    if (selected) {
      fill.shader = const LinearGradient(
        colors: [AppColors.brandSky, AppColors.brand, AppColors.brandDeep],
      ).createShader(body.outerRect);
    } else {
      fill.color = Colors.white;
    }
    canvas.drawRRect(body, fill);
    canvas.drawPath(tailPath, selected ? (Paint()..color = AppColors.brand) : fill);

    final circleCenter = Offset(shadow + padH + iconBox / 2, shadow + height / 2);
    canvas.drawCircle(
      circleCenter,
      iconBox / 2,
      Paint()..color = selected ? Colors.white : (closed ? const Color(0xFFC5D0E0) : AppColors.brand),
    );
    _drawIcon(
      canvas,
      Iconsax.car,
      circleCenter,
      iconBox * 0.6,
      selected ? AppColors.brand : Colors.white,
    );

    text.paint(canvas, Offset(shadow + padH + iconBox + 6 * scale, shadow + (height - text.height) / 2));

    final image = await recorder.endRecording().toImage(
          (canvasW * _ratio).ceil(),
          (canvasH * _ratio).ceil(),
        );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: _ratio);
    _cache[key] = descriptor;
    return descriptor;
  }

  static Future<BitmapDescriptor> userDot() async {
    const key = 'user';
    final cached = _cache[key];
    if (cached != null) return cached;
    const size = 44.0;
    final recorder = ui.PictureRecorder();
    final canvas = await _canvas(recorder, size);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, Paint()..color = AppColors.accent.withValues(alpha: 0.22));
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
    canvas.drawCircle(center, 8, Paint()..color = AppColors.accent);
    final image = await recorder.endRecording().toImage((size * _ratio).ceil(), (size * _ratio).ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(bytes!.buffer.asUint8List(), imagePixelRatio: _ratio);
    _cache[key] = descriptor;
    return descriptor;
  }

  static void _drawIcon(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }
}
