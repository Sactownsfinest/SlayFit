import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = File('../mobile/assets/images/app_icon.png').readAsBytesSync();
  final original = img.decodePng(src)!;

  // Adaptive icon safe zone is 66% of canvas — add ~20% padding each side
  const canvasSize = 1024;
  final padding = (canvasSize * 0.18).toInt(); // 18% each side = 64% content area
  final contentSize = canvasSize - padding * 2;

  // Create dark background canvas
  final canvas = img.Image(width: canvasSize, height: canvasSize);
  img.fill(canvas, color: img.ColorRgb8(10, 14, 26)); // #0A0E1A

  // Scale original down to content size
  final scaled = img.copyResize(original, width: contentSize, height: contentSize);

  // Composite centered onto canvas
  img.compositeImage(canvas, scaled, dstX: padding, dstY: padding);

  // Save as adaptive foreground
  File('../mobile/assets/images/app_icon_adaptive_fg.png')
      .writeAsBytesSync(img.encodePng(canvas));

  print('Done: app_icon_adaptive_fg.png (${canvasSize}x${canvasSize}, padding=$padding)');
}
