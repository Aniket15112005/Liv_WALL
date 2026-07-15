import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/wallpaper.dart';

class AnimatedPreview extends StatefulWidget {
  final WallpaperModel wallpaper;

  const AnimatedPreview({super.key, required this.wallpaper});

  @override
  State<AnimatedPreview> createState() => _AnimatedPreviewState();
}

class _AnimatedPreviewState extends State<AnimatedPreview>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller1, _controller2, _controller3]),
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _buildPainter(),
        );
      },
    );
  }

  CustomPainter _buildPainter() {
    final colors =
        widget.wallpaper.colors.map((c) => Color(c)).toList();
    switch (widget.wallpaper.type) {
      case WallpaperType.particles:
        return _ParticlesPainter(
            _controller1.value, _controller2.value, colors);
      case WallpaperType.waves:
        return _WavesPainter(
            _controller1.value, _controller2.value, colors);
      case WallpaperType.geometric:
        return _GeometricPainter(
            _controller1.value, _controller3.value, colors);
      case WallpaperType.galaxy:
        return _GalaxyPainter(
            _controller1.value, _controller2.value, colors);
      case WallpaperType.neonPulse:
        return _NeonPulsePainter(
            _controller1.value, _controller2.value, colors);
      case WallpaperType.matrixRain:
        return _MatrixPainter(_controller3.value, colors);
      case WallpaperType.aurora:
        return _AuroraPainter(
            _controller1.value, _controller2.value, colors);
      case WallpaperType.fluidColors:
        return _FluidPainter(
            _controller1.value, _controller2.value, _controller3.value, colors);
    }
  }
}

// =================== PARTICLES ===================
class _ParticlesPainter extends CustomPainter {
  final double t1, t2;
  final List<Color> colors;
  static final _rand = math.Random(42);
  static late List<_Particle> _particles;
  static bool _initialized = false;

  _ParticlesPainter(this.t1, this.t2, this.colors) {
    if (!_initialized) {
      _particles = List.generate(
          80, (_) => _Particle(_rand.nextDouble(), _rand.nextDouble(),
              _rand.nextDouble() * 0.004 - 0.002,
              _rand.nextDouble() * 0.006 - 0.003,
              _rand.nextDouble() * 3 + 1));
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint();
    bg.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors[0], colors[1]],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (final p in _particles) {
      final x = ((p.x + t1 * p.vx * 30) % 1.0) * size.width;
      final y = ((p.y + t1 * p.vy * 20) % 1.0) * size.height;
      final glow = Paint()
        ..color = colors.last.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(x, y), p.r + 3, glow);
      final dot = Paint()
        ..color = colors.last.withOpacity(0.8 + 0.2 * math.sin(t2 * 6 + p.x));
      canvas.drawCircle(Offset(x, y), p.r, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _Particle {
  final double x, y, vx, vy, r;
  _Particle(this.x, this.y, this.vx, this.vy, this.r);
}

// =================== WAVES ===================
class _WavesPainter extends CustomPainter {
  final double t1, t2;
  final List<Color> colors;

  _WavesPainter(this.t1, this.t2, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors[0], colors[1]],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (int w = 0; w < 5; w++) {
      final wt = w / 5;
      final path = Path();
      final amplitude = size.height * (0.06 + wt * 0.04);
      final yBase = size.height * (0.3 + wt * 0.14);
      path.moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 2) {
        final y = yBase +
            math.sin((x / size.width * 2 * math.pi) + t1 * 6 + w) *
                amplitude +
            math.cos((x / size.width * math.pi) + t2 * 4 + w * 0.5) *
                (amplitude * 0.5);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      final paint = Paint()
        ..color = colors.last.withOpacity(0.12 + wt * 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);

      final strokePaint = Paint()
        ..color = colors.last.withOpacity(0.5 - wt * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// =================== GEOMETRIC ===================
class _GeometricPainter extends CustomPainter {
  final double t1, t2;
  final List<Color> colors;

  _GeometricPainter(this.t1, this.t2, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors[0], colors[1]],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 0; i < 6; i++) {
      final sides = 3 + i;
      final radius = 40.0 + i * 50.0;
      final angle = t1 * 2 * math.pi + i * 0.5;
      final path = _polygon(cx, cy, radius, sides, angle);
      final paint = Paint()
        ..color = colors.last.withOpacity(0.08 + i * 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, paint);

      final glowPaint = Paint()
        ..color = colors.last.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, glowPaint);
    }

    for (int i = 0; i < 4; i++) {
      final r = 30.0 + i * 30.0;
      final a = -t2 * 2 * math.pi + i;
      _drawDiamond(canvas, cx, cy, r, a, colors.last.withOpacity(0.15));
    }
  }

  Path _polygon(double cx, double cy, double r, int sides, double startAngle) {
    final path = Path();
    for (int i = 0; i <= sides; i++) {
      final angle = startAngle + (i * 2 * math.pi / sides);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawDiamond(
      Canvas canvas, double cx, double cy, double r, double angle, Color color) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    final pts = [
      Offset(cx + r * c, cy + r * s),
      Offset(cx + r * (-s), cy + r * c),
      Offset(cx - r * c, cy - r * s),
      Offset(cx + r * s, cy - r * c),
    ];
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy)
      ..lineTo(pts[3].dx, pts[3].dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// =================== GALAXY ===================
class _GalaxyPainter extends CustomPainter {
  final double t1, t2;
  final List<Color> colors;
  static final _rand = math.Random(99);
  static final List<_Star> _stars = List.generate(
      150,
      (_) => _Star(_rand.nextDouble(), _rand.nextDouble(),
          _rand.nextDouble() * 1.5 + 0.5));

  _GalaxyPainter(this.t1, this.t2, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [colors[1], colors[0]],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (final s in _stars) {
      final twinkle = 0.6 + 0.4 * math.sin(t2 * 8 + s.x * 20);
      final paint = Paint()
        ..color = Colors.white.withOpacity(twinkle * 0.9);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.r, paint);
    }

    // Spiral arms
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int arm = 0; arm < 3; arm++) {
      for (int i = 0; i < 60; i++) {
        final fi = i / 60.0;
        final spiral =
            fi * 4 * math.pi + (arm * 2 * math.pi / 3) + t1 * 2 * math.pi;
        final dist = fi * math.min(size.width, size.height) * 0.42;
        final x = cx + dist * math.cos(spiral);
        final y = cy + dist * math.sin(spiral) * 0.6;
        final dot = Paint()
          ..color = colors.last.withOpacity(fi * 0.5 + 0.05)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, fi * 4 + 1);
        canvas.drawCircle(Offset(x, y), fi * 2.5 + 0.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _Star {
  final double x, y, r;
  _Star(this.x, this.y, this.r);
}

// =================== NEON PULSE ===================
class _NeonPulsePainter extends CustomPainter {
  final double t1, t2;
  final List<Color> colors;

  _NeonPulsePainter(this.t1, this.t2, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = colors[0]);

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 8; i >= 0; i--) {
      final t = (t1 + i / 8) % 1.0;
      final radius = t * math.min(size.width, size.height) * 0.7;
      final opacity = (1 - t) * 0.6;

      final glow = Paint()
        ..color = colors[1].withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy), radius, glow);

      final ring = Paint()
        ..color = colors[1].withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy), radius, ring);
    }

    // Cross pulse
    final intensity = 0.5 + 0.5 * math.sin(t2 * 2 * math.pi);
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + t1 * math.pi;
      final len = math.min(size.width, size.height) * 0.35;
      final glowLine = Paint()
        ..color = colors[2].withOpacity(0.4 * intensity)
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + len * math.cos(angle), cy + len * math.sin(angle)),
        glowLine,
      );
      final line = Paint()
        ..color = colors[2].withOpacity(0.9 * intensity)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + len * math.cos(angle), cy + len * math.sin(angle)),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// =================== MATRIX RAIN ===================
class _MatrixPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  static final _rand = math.Random(7);
  static final List<_Column> _cols = [];
  static bool _colsInit = false;

  _MatrixPainter(this.t, this.colors) {
    if (!_colsInit) {
      for (int i = 0; i < 25; i++) {
        _cols.add(_Column(i * 14.0, _rand.nextDouble() * 30,
            _rand.nextDouble() * 0.3 + 0.1));
      }
      _colsInit = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = colors[0]);

    for (final col in _cols) {
      final speed = col.speed * size.height;
      final head = (t * speed * 2 + col.offset * size.height) % (size.height + 200);

      for (int row = 0; row < 20; row++) {
        final y = head - row * 18.0;
        if (y < 0 || y > size.height) continue;
        final intensity = (1 - row / 20.0);
        final isHead = row == 0;

        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(0x30A0 + _rand.nextInt(96)),
            style: TextStyle(
              color: isHead
                  ? Colors.white.withOpacity(intensity)
                  : colors[1].withOpacity(intensity * 0.7),
              fontSize: 14,
              fontWeight:
                  isHead ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(col.x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _Column {
  final double x, offset, speed;
  _Column(this.x, this.offset, this.speed);
}

// =================== AURORA ===================
class _AuroraPainter extends CustomPainter {
  final double t1, t2;
  final List<Color> colors;

  _AuroraPainter(this.t1, this.t2, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [colors[0], colors[0].withBlue(30)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Stars
    final rand = math.Random(123);
    for (int i = 0; i < 80; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height * 0.6;
      final twinkle = 0.3 + 0.7 * math.sin(t2 * 6 + i * 1.3);
      canvas.drawCircle(
          Offset(x, y), rand.nextDouble() + 0.5,
          Paint()..color = Colors.white.withOpacity(twinkle * 0.8));
    }

    // Aurora bands
    for (int band = 0; band < 4; band++) {
      final path = Path();
      final yBase = size.height * (0.15 + band * 0.1);
      path.moveTo(0, yBase);

      for (double x = 0; x <= size.width; x += 3) {
        final norm = x / size.width;
        final y = yBase +
            math.sin(norm * 3 * math.pi + t1 * 2 * math.pi + band) *
                (size.height * 0.08) +
            math.cos(norm * 2 * math.pi + t2 * math.pi + band * 0.7) *
                (size.height * 0.04);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();

      final bandColor = band.isEven ? colors[1] : colors[2];
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bandColor.withOpacity(0.0),
            bandColor.withOpacity(0.2 - band * 0.03),
            bandColor.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// =================== FLUID COLORS ===================
class _FluidPainter extends CustomPainter {
  final double t1, t2, t3;
  final List<Color> colors;

  _FluidPainter(this.t1, this.t2, this.t3, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Base gradient
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colors[0], colors[1]],
        transform: GradientRotation(t1 * 2 * math.pi),
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Fluid blobs
    for (int i = 0; i < 5; i++) {
      final fi = i / 5.0;
      final bx = size.width *
          (0.3 + 0.4 * math.sin(t1 * 2 * math.pi + fi * 7));
      final by = size.height *
          (0.3 + 0.4 * math.cos(t2 * 2 * math.pi + fi * 5));
      final br = math.min(size.width, size.height) * (0.25 + 0.15 * math.sin(t3 * math.pi + fi));

      final blob = Paint()
        ..color = colors[i % colors.length].withOpacity(0.35)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, br * 0.6);
      canvas.drawCircle(Offset(bx, by), br, blob);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
