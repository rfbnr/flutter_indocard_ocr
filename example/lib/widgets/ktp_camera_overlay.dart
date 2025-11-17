// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:porto_crm_app/src/features/ocr/presentation/blocs/ocr_camera_bloc/ocr_camera_bloc.dart';

// class KtpCameraOverlayWidget extends StatelessWidget {
//   final Animation<double> pulseAnimation;
//   final Animation<Offset> slideAnimation;
//   final OcrCameraState cameraState;

//   const KtpCameraOverlayWidget({
//     required this.pulseAnimation,
//     required this.slideAnimation,
//     required this.cameraState,
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size.infinite,
//       painter: OverlayPainterKtpLandscape(
//         pulseAnimation: pulseAnimation,
//         slideAnimation: slideAnimation,
//         cameraState: cameraState,
//       ),
//     );
//   }
// }

// class OverlayPainterKtpLandscape extends CustomPainter {
//   final Animation<double> pulseAnimation;
//   final Animation<Offset> slideAnimation;
//   final OcrCameraState cameraState;

//   OverlayPainterKtpLandscape({
//     required this.pulseAnimation,
//     required this.slideAnimation,
//     required this.cameraState,
//   }) : super(repaint: pulseAnimation);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final screenWidth = size.width;
//     final screenHeight = size.height;

//     // Save the current canvas state
//     canvas.save();

//     // Rotate canvas 90 degrees for landscape orientation
//     canvas.translate(screenWidth / 2, screenHeight / 2);
//     canvas.rotate(90 * 3.14159 / 180); // 90 degrees in radians
//     canvas.translate(-screenHeight / 2, -screenWidth / 2);

//     // Use rotated dimensions (swap width and height)
//     final rotatedWidth = screenHeight;
//     final rotatedHeight = screenWidth;

//     // KTP aspect ratio (approximately 3.37:2.12)
//     const ktpAspectRatio = 3.37 / 2.12;

//     // Calculate KTP frame dimensions to fill most of the screen
//     const margin = 20.0; // Reduced margin for fuller screen

//     // Try to use maximum width first
//     double frameWidth = rotatedWidth - (margin * 2);
//     double frameHeight = frameWidth / ktpAspectRatio;

//     // If height exceeds screen, adjust to fit height instead
//     if (frameHeight > rotatedHeight - (margin * 2)) {
//       frameHeight = rotatedHeight - (margin * 2);
//       frameWidth = frameHeight * ktpAspectRatio;
//     }

//     // Center the frame in rotated coordinates
//     final frameLeft = (rotatedWidth - frameWidth) / 2;
//     final frameTop = (rotatedHeight - frameHeight) / 2;
//     final frameRect = Rect.fromLTWH(
//       frameLeft,
//       frameTop,
//       frameWidth,
//       frameHeight,
//     );

//     // Draw overlay background (dimmed area)
//     _drawOverlayBackground(
//       canvas,
//       Size(rotatedWidth, rotatedHeight),
//       frameRect,
//     );

//     if (cameraState is CameraPicturePreview) {
//       // Draw a solid border when in picture preview state
//       final previewBorderPaint = Paint()
//         ..color = Colors.green
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 3.0;

//       final previewRRect = RRect.fromRectAndRadius(
//         frameRect,
//         const Radius.circular(12),
//       );
//       canvas.drawRRect(previewRRect, previewBorderPaint);
//     } else {
//       // Draw KTP frame with animated border
//       _drawKTPFrame(canvas, frameRect);

//       // Draw corner indicators
//       _drawCornerIndicators(canvas, frameRect);

//       // Draw scanning line animation
//       _drawScanningLine(canvas, frameRect);

//       // Draw field guides
//       _drawFieldGuides(canvas, frameRect);
//     }

//     // Restore the canvas state
//     canvas.restore();
//   }

//   void _drawOverlayBackground(Canvas canvas, Size size, Rect frameRect) {
//     final overlayPaint = Paint()
//       ..color = Colors.black.withValues(alpha: 0.6)
//       ..style = PaintingStyle.fill;

//     // Draw overlay with cutout for KTP frame
//     final overlayPath = Path()
//       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
//       ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)))
//       ..fillType = PathFillType.evenOdd;

//     canvas.drawPath(overlayPath, overlayPaint);
//   }

//   void _drawKTPFrame(Canvas canvas, Rect frameRect) {
//     final framePaint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.8)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;

//     // Animated pulsing effect
//     final pulseValue = pulseAnimation.value;
//     final adjustedRect = Rect.fromCenter(
//       center: frameRect.center,
//       width: frameRect.width * pulseValue,
//       height: frameRect.height * pulseValue,
//     );

//     // Draw rounded rectangle frame
//     final rrect = RRect.fromRectAndRadius(
//       adjustedRect,
//       const Radius.circular(12),
//     );
//     canvas.drawRRect(rrect, framePaint);

//     // Draw inner guide frame (slightly smaller)
//     final innerFramePaint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.3)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;

//     final innerRect = adjustedRect.deflate(8);
//     final innerRRect = RRect.fromRectAndRadius(
//       innerRect,
//       const Radius.circular(8),
//     );
//     canvas.drawRRect(innerRRect, innerFramePaint);
//   }

//   void _drawCornerIndicators(Canvas canvas, Rect frameRect) {
//     final cornerPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round;

//     const cornerLength = 20.0;
//     const cornerRadius = 12.0;

//     // Top-left corner
//     canvas.drawLine(
//       Offset(frameRect.left + cornerRadius, frameRect.top),
//       Offset(frameRect.left + cornerRadius + cornerLength, frameRect.top),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.left, frameRect.top + cornerRadius),
//       Offset(frameRect.left, frameRect.top + cornerRadius + cornerLength),
//       cornerPaint,
//     );

//     // Top-right corner
//     canvas.drawLine(
//       Offset(frameRect.right - cornerRadius - cornerLength, frameRect.top),
//       Offset(frameRect.right - cornerRadius, frameRect.top),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.right, frameRect.top + cornerRadius),
//       Offset(frameRect.right, frameRect.top + cornerRadius + cornerLength),
//       cornerPaint,
//     );

//     // Bottom-left corner
//     canvas.drawLine(
//       Offset(frameRect.left + cornerRadius, frameRect.bottom),
//       Offset(frameRect.left + cornerRadius + cornerLength, frameRect.bottom),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.left, frameRect.bottom - cornerRadius - cornerLength),
//       Offset(frameRect.left, frameRect.bottom - cornerRadius),
//       cornerPaint,
//     );

//     // Bottom-right corner
//     canvas.drawLine(
//       Offset(frameRect.right - cornerRadius - cornerLength, frameRect.bottom),
//       Offset(frameRect.right - cornerRadius, frameRect.bottom),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.right, frameRect.bottom - cornerRadius - cornerLength),
//       Offset(frameRect.right, frameRect.bottom - cornerRadius),
//       cornerPaint,
//     );
//   }

//   void _drawScanningLine(Canvas canvas, Rect frameRect) {
//     final scanLinePaint = Paint()
//       ..shader = LinearGradient(
//         colors: [
//           Colors.transparent,
//           Colors.red.withValues(alpha: 0.8),
//           Colors.red.withValues(alpha: 0.4),
//           Colors.transparent,
//         ],
//         stops: const [0.0, 0.4, 0.6, 1.0],
//       ).createShader(frameRect)
//       ..strokeWidth = 2.5;

//     // Animated scanning line that moves horizontally
//     final slideOffset = slideAnimation.value;
//     final lineX =
//         frameRect.left +
//         (frameRect.width * 0.5) +
//         (slideOffset.dx * frameRect.width * 0.3);

//     canvas.drawLine(
//       Offset(lineX, frameRect.top + 10),
//       Offset(lineX, frameRect.bottom - 10),
//       scanLinePaint,
//     );
//   }

//   void _drawFieldGuides(Canvas canvas, Rect frameRect) {
//     final guidePaint = Paint()
//       ..color = Colors.red.withValues(alpha: 0.7)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.8;

//     final textPaint = TextPainter(
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.left,
//     );

//     // Define field regions based on KTP layout
//     final fields = [
//       {'name': 'NIK', 'top': 0.15, 'height': 0.07},
//       {'name': 'Nama', 'top': 0.22, 'height': 0.07},
//       {'name': 'TTL', 'top': 0.29, 'height': 0.07},
//       {'name': 'Alamat', 'top': 0.43, 'height': 0.22},
//     ];

//     for (final field in fields) {
//       final fieldTop =
//           frameRect.top + (frameRect.height * (field['top']! as double)) + 25;

//       // Draw subtle guide line
//       canvas.drawLine(
//         Offset(frameRect.left + 30, fieldTop),
//         Offset(frameRect.right - 10, fieldTop),
//         guidePaint,
//       );

//       // Draw field label (optional, only show if space permits)
//       if (frameRect.width > 300) {
//         textPaint.text = TextSpan(
//           text: field['name'] as String,
//           style: TextStyle(
//             color: Colors.red.withValues(alpha: 0.9),
//             fontSize: 11.sp,
//             fontWeight: FontWeight.w500,
//           ),
//         );
//         textPaint.layout();
//         textPaint.paint(canvas, Offset(frameRect.left + 8, fieldTop - 12));
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant OverlayPainterKtpLandscape oldDelegate) {
//     return oldDelegate.pulseAnimation != pulseAnimation ||
//         oldDelegate.slideAnimation != slideAnimation;
//   }
// }

// class OverlayPainterKtpPortrait extends CustomPainter {
//   final Animation<double> pulseAnimation;
//   final Animation<Offset> slideAnimation;

//   OverlayPainterKtpPortrait({
//     required this.pulseAnimation,
//     required this.slideAnimation,
//   }) : super(repaint: pulseAnimation);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final screenWidth = size.width;
//     final screenHeight = size.height;

//     // KTP aspect ratio (approximately 3.37:2.12)
//     const ktpAspectRatio = 3.37 / 2.12;

//     // Calculate KTP frame dimensions
//     const margin = 10.0;
//     final frameWidth = screenWidth - (margin * 2);
//     final frameHeight = frameWidth / ktpAspectRatio;

//     // Center the frame
//     final frameLeft = margin;
//     final frameTop = (screenHeight - frameHeight) / 2;
//     final frameRect = Rect.fromLTWH(
//       frameLeft,
//       frameTop,
//       frameWidth,
//       frameHeight,
//     );

//     // Draw overlay background (dimmed area)
//     _drawOverlayBackground(canvas, size, frameRect);

//     // Draw KTP frame with animated border
//     _drawKTPFrame(canvas, frameRect);

//     // Draw corner indicators
//     _drawCornerIndicators(canvas, frameRect);

//     // Draw scanning line animation
//     _drawScanningLine(canvas, frameRect);

//     // Draw field guides
//     _drawFieldGuides(canvas, frameRect);
//   }

//   void _drawOverlayBackground(Canvas canvas, Size size, Rect frameRect) {
//     final overlayPaint = Paint()
//       ..color = Colors.black.withValues(alpha: 0.65)
//       ..style = PaintingStyle.fill;

//     // Draw overlay with cutout for KTP frame
//     final overlayPath = Path()
//       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
//       ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(12)))
//       ..fillType = PathFillType.evenOdd;

//     canvas.drawPath(overlayPath, overlayPaint);
//   }

//   void _drawKTPFrame(Canvas canvas, Rect frameRect) {
//     final framePaint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.8)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;

//     // Animated pulsing effect
//     final pulseValue = pulseAnimation.value;
//     final adjustedRect = Rect.fromCenter(
//       center: frameRect.center,
//       width: frameRect.width * pulseValue,
//       height: frameRect.height * pulseValue,
//     );

//     // Draw rounded rectangle frame
//     final rrect = RRect.fromRectAndRadius(
//       adjustedRect,
//       const Radius.circular(12),
//     );
//     canvas.drawRRect(rrect, framePaint);

//     // Draw inner guide frame (slightly smaller)
//     final innerFramePaint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.3)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;

//     final innerRect = adjustedRect.deflate(8);
//     final innerRRect = RRect.fromRectAndRadius(
//       innerRect,
//       const Radius.circular(8),
//     );
//     canvas.drawRRect(innerRRect, innerFramePaint);
//   }

//   void _drawCornerIndicators(Canvas canvas, Rect frameRect) {
//     final cornerPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 4.0
//       ..strokeCap = StrokeCap.round;

//     const cornerLength = 20.0;
//     const cornerRadius = 12.0;

//     // Top-left corner
//     canvas.drawLine(
//       Offset(frameRect.left + cornerRadius, frameRect.top),
//       Offset(frameRect.left + cornerRadius + cornerLength, frameRect.top),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.left, frameRect.top + cornerRadius),
//       Offset(frameRect.left, frameRect.top + cornerRadius + cornerLength),
//       cornerPaint,
//     );

//     // Top-right corner
//     canvas.drawLine(
//       Offset(frameRect.right - cornerRadius - cornerLength, frameRect.top),
//       Offset(frameRect.right - cornerRadius, frameRect.top),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.right, frameRect.top + cornerRadius),
//       Offset(frameRect.right, frameRect.top + cornerRadius + cornerLength),
//       cornerPaint,
//     );

//     // Bottom-left corner
//     canvas.drawLine(
//       Offset(frameRect.left + cornerRadius, frameRect.bottom),
//       Offset(frameRect.left + cornerRadius + cornerLength, frameRect.bottom),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.left, frameRect.bottom - cornerRadius - cornerLength),
//       Offset(frameRect.left, frameRect.bottom - cornerRadius),
//       cornerPaint,
//     );

//     // Bottom-right corner
//     canvas.drawLine(
//       Offset(frameRect.right - cornerRadius - cornerLength, frameRect.bottom),
//       Offset(frameRect.right - cornerRadius, frameRect.bottom),
//       cornerPaint,
//     );
//     canvas.drawLine(
//       Offset(frameRect.right, frameRect.bottom - cornerRadius - cornerLength),
//       Offset(frameRect.right, frameRect.bottom - cornerRadius),
//       cornerPaint,
//     );
//   }

//   void _drawScanningLine(Canvas canvas, Rect frameRect) {
//     final scanLinePaint = Paint()
//       ..shader = LinearGradient(
//         colors: [
//           Colors.transparent,
//           Colors.red.withValues(alpha: 0.95),
//           Colors.red.withValues(alpha: 0.55),
//           Colors.transparent,
//         ],
//         stops: const [0.0, 0.4, 0.6, 1.0],
//       ).createShader(frameRect)
//       ..strokeWidth = 2.5;

//     // Animated scanning line that moves horizontally
//     final slideOffset = slideAnimation.value;
//     final lineX =
//         frameRect.left +
//         (frameRect.width * 0.5) +
//         (slideOffset.dx * frameRect.width * 0.3);

//     canvas.drawLine(
//       Offset(lineX, frameRect.top + 10),
//       Offset(lineX, frameRect.bottom - 10),
//       scanLinePaint,
//     );
//   }

//   void _drawFieldGuides(Canvas canvas, Rect frameRect) {
//     final guidePaint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.4)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;

//     final textPaint = TextPainter(
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.left,
//     );

//     // Define field regions based on KTP layout
//     final fields = [
//       {'name': 'NIK', 'top': 0.15, 'height': 0.07},
//       {'name': 'Nama', 'top': 0.22, 'height': 0.07},
//       {'name': 'TTL', 'top': 0.29, 'height': 0.07},
//       {'name': 'Alamat', 'top': 0.43, 'height': 0.22},
//     ];

//     for (final field in fields) {
//       final fieldTop =
//           frameRect.top + (frameRect.height * (field['top']! as double));

//       // Draw subtle guide line
//       canvas.drawLine(
//         Offset(frameRect.left + 20, fieldTop),
//         Offset(frameRect.right - 20, fieldTop),
//         guidePaint,
//       );

//       // Draw field label (optional, only show if space permits)
//       if (frameRect.width > 300) {
//         textPaint.text = TextSpan(
//           text: field['name'] as String,
//           style: TextStyle(
//             color: Colors.white.withValues(alpha: 0.6),
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//           ),
//         );
//         textPaint.layout();
//         textPaint.paint(canvas, Offset(frameRect.left + 8, fieldTop - 12));
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant OverlayPainterKtpPortrait oldDelegate) {
//     return oldDelegate.pulseAnimation != pulseAnimation ||
//         oldDelegate.slideAnimation != slideAnimation;
//   }
// }
