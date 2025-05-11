import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

/// An example of using ScrollHijackSliver to concsume more space than it
/// actually takes up.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DemoSpinnerScreen(),
    );
  }
}

class DemoSpinnerScreen extends StatelessWidget {
  const DemoSpinnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ScrollHijackSliver(
            consumingSpaceSize: 800,
            builder: (context, consumingProgress) {
              return Container(
                color: Colors.grey,
                height: 300,
                child: ValueListenableBuilder(
                  valueListenable: consumingProgress,
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _SquaresPainter(
                        progress: consumingProgress.value,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          ScrollHijackSliver(
            consumingSpaceSize: 800,
            builder: (context, consumingProgress) {
              return Container(
                color: Colors.brown,
                height: 300,
                child: ValueListenableBuilder(
                  valueListenable: consumingProgress,
                  builder: (context, value, child) {
                    return CustomPaint(
                      painter: _SquaresPainter(
                        progress: consumingProgress.value,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          for (int i = 0; i < 10; i++)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(8.0),
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SquaresPainter extends CustomPainter {
  static const squareSize = 60.0;
  static const halfSquareSize = squareSize / 2;
  static const padding = 20.0;
  static const colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
  ];
  final double progress;

  _SquaresPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final moveT = progress.clamp(0.0, 0.8);

    if (moveT < 0.4) {
      _paintRotation(canvas, size);
    } else if (moveT < 0.8) {
      _paintMoving(canvas, size);
    } else {
      _paintMorphing(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _SquaresPainter oldDelegate) =>
      oldDelegate.progress != progress;

  void _paintRotation(Canvas canvas, Size size) {
    final initialPositions = [
      const Offset(padding, padding),
      Offset(size.width - squareSize - padding, padding),
      Offset(padding, size.height - squareSize - padding),
      Offset(size.width - squareSize - padding,
          size.height - squareSize - padding),
    ];
    final angle = lerpDouble(0, math.pi * 2, progress / 0.4)!;

    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i];
      final origin = initialPositions[i];

      canvas.save();
      canvas.translate(origin.dx + halfSquareSize, origin.dy + halfSquareSize);
      canvas.rotate(angle);
      canvas.translate(-halfSquareSize, -halfSquareSize);
      canvas.drawRect(const Rect.fromLTWH(0, 0, squareSize, squareSize), paint);
      canvas.restore();
    }
  }

  void _paintMoving(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final t = (progress - 0.4) / 0.4;

    final initialPositions = [
      const Offset(padding, padding),
      Offset(size.width - squareSize - padding, padding),
      Offset(padding, size.height - squareSize - padding),
      Offset(size.width - squareSize - padding,
          size.height - squareSize - padding),
    ];

    final destinationPositions = [
      Offset(centerX - squareSize, centerY - squareSize),
      Offset(centerX, centerY - squareSize),
      Offset(centerX - squareSize, centerY),
      Offset(centerX, centerY),
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i];
      final origin =
          Offset.lerp(initialPositions[i], destinationPositions[i], t)!;

      canvas.save();
      canvas.translate(origin.dx + halfSquareSize, origin.dy + halfSquareSize);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: squareSize,
          height: squareSize,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintMorphing(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final morphT = ((progress - 0.8) / 0.1).clamp(0.0, 1.0);
    final pulseT = ((progress - 0.9) / 0.1).clamp(0.0, 1.0);
    final scale = 1.0 + 0.05 * math.sin(pulseT * 2 * math.pi);
    final radius = squareSize * morphT;

    final destinations = [
      Offset(centerX - squareSize, centerY - squareSize),
      Offset(centerX, centerY - squareSize),
      Offset(centerX - squareSize, centerY),
      Offset(centerX, centerY),
    ];

    for (int i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i];
      final origin = destinations[i];

      final path = switch (i) {
        0 => _buildTopLeftMorphing(squareSize, radius),
        1 => _buildTopRightMorphing(squareSize, radius),
        2 => _buildBottomLeftMorphing(squareSize, radius),
        3 => _buildBottomRightMorphing(squareSize, radius),
        _ => Path(),
      };

      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.translate(halfSquareSize, halfSquareSize);
      canvas.scale(scale);
      canvas.translate(-halfSquareSize, -halfSquareSize);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  Path _buildTopLeftMorphing(double s, double r) {
    final path = Path();
    path.moveTo(s, 0);
    path.lineTo(r, 0);
    path.arcToPoint(
      Offset(0, r),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(0, s);
    path.lineTo(s, s);
    path.close();
    return path;
  }

  Path _buildTopRightMorphing(double s, double r) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(s - r, 0);
    path.arcToPoint(
      Offset(s, r),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(s, s);
    path.lineTo(0, s);
    path.close();
    return path;
  }

  Path _buildBottomLeftMorphing(double s, double r) {
    final path = Path();
    path.moveTo(s, 0);
    path.lineTo(0, 0);
    path.lineTo(0, s - r);
    path.arcToPoint(
      Offset(r, s),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(s, s);
    path.close();
    return path;
  }

  Path _buildBottomRightMorphing(double s, double r) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(s, 0);
    path.lineTo(s, s - r);
    path.arcToPoint(
      Offset(s - r, s),
      radius: Radius.circular(r),
      clockwise: true,
    );
    path.lineTo(0, s);
    path.close();
    return path;
  }
}
