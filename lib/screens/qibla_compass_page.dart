import 'dart:async';
import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:adhan/adhan.dart'; //  Added for accurate Qibla calculation
import '../theme/app_icons.dart';

/// Qibla Compass Page
/// This page calculates and displays the Qibla direction towards Mecca.
/// It uses the flutter_qiblah package for calculations and sensor data.
class QiblaCompassPage extends StatefulWidget {
  const QiblaCompassPage({super.key});

  @override
  State<QiblaCompassPage> createState() => _QiblaCompassPageState();
}

class _QiblaCompassPageState extends State<QiblaCompassPage> {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  // Stream initialized once here to avoid breaking updates on rebuild
  final _qiblahStream = FlutterQiblah.qiblahStream;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
  }

  /// Checks location permission and GPS status
  Future<void> _checkLocationStatus() async {
    final status = await Permission.locationWhenInUse.status;
    final isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    _locationStreamController.sink
        .add(LocationStatus(status, isLocationServiceEnabled));
  }

  /// Requests location permission from the user
  Future<void> _requestPermission() async {
    final status = await Permission.locationWhenInUse.request();
    _checkLocationStatus();

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إذن الموقع مطلوب'),
        content: const Text(
          'يحتاج التطبيق إلى إذن الموقع لحساب اتجاه القبلة. يرجى تفعيله من إعدادات النظام.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('الإعدادات'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اتجاه القبلة'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<LocationStatus>(
          stream: _locationStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final locationStatus = snapshot.data;
            if (locationStatus == null ||
                !locationStatus.status.isGranted ||
                !locationStatus.enabled) {
              return _buildPermissionError(locationStatus);
            }

            return FutureBuilder(
              future: FlutterQiblah.androidDeviceSensorSupport(),
              builder: (context, sensorSnapshot) {
                if (sensorSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (sensorSnapshot.data == false) {
                  return Text(
                    "البوصلة غير مدعومة على هذا الجهاز.",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                  );
                }

                return _QiblahCompassWidget(stream: _qiblahStream);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionError(LocationStatus? status) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(OctIcons.location, size: 64, color: Colors.orange),
        const SizedBox(height: 24),
        Text(
          status?.enabled == false
              ? "خدمات الموقع غير مفعلة"
              : "إذن الموقع غير مسموح به",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: status?.enabled == false
              ? _checkLocationStatus
              : _requestPermission,
          child: Text(status?.enabled == false ? "تحديث" : "السماح بالوصول"),
        ),
      ],
    );
  }
}

/// The actual compass UI component
class _QiblahCompassWidget extends StatefulWidget {
  final Stream<QiblahDirection> stream;

  const _QiblahCompassWidget({required this.stream});

  @override
  State<_QiblahCompassWidget> createState() => _QiblahCompassWidgetState();
}

class _QiblahCompassWidgetState extends State<_QiblahCompassWidget> {
  double? _manualBearing;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _calculateManualBearing();
  }

  /// Calculates the accurate Qibla bearing using the adhan package
  Future<void> _calculateManualBearing() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final coordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(coordinates);

      if (mounted) {
        setState(() {
          _manualBearing = qibla.direction;
          _isLoadingLocation = false;
        });
        debugPrint(
            'Manual Qibla Bearing: $_manualBearing at (${position.latitude}, ${position.longitude})');
      }
    } catch (e) {
      debugPrint('Error calculating manual bearing: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingLocation) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text("تحديد الموقع للحساب الدقيق...",
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return StreamBuilder<QiblahDirection>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text("خطأ: ${snapshot.error}",
                  style: TextStyle(color: colorScheme.onSurface)));
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("في انتظار بيانات المستشعرات...",
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }

        final qiblahDirection = snapshot.data!;

        // Use manual bearing if available, fallback to package calculation
        final double bearing = _manualBearing ??
            (qiblahDirection.qiblah - qiblahDirection.direction);
        final double heading = qiblahDirection.direction;

        // Debug logging
        debugPrint('Heading: $heading | Final Bearing: $bearing');

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Drawn Compass
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(300, 300),
                    painter: QiblaCompassPainter(
                      qiblaAngle: bearing +
                          heading, // Pass qiblah as (bearing + heading) so our painter logic works
                      deviceHeading: heading,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ),
            ),

            // Stats
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatTile("القبلة", "${bearing.toStringAsFixed(1)}°",
                          colorScheme),
                      _buildStatTile("الاتجاه",
                          "${heading.toStringAsFixed(1)}°", colorScheme),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Animated indicator to show data is flowing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "المستشعرات تعمل",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "قم بمعايرة جهازك عن طريق تحريكه بشكل رقم 8",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildStatTile(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            )),
      ],
    );
  }
}

/// Custom Painter for the Qibla Compass
/// Custom Painter for the Qibla Compass
class QiblaCompassPainter extends CustomPainter {
  final double qiblaAngle;
  final double deviceHeading;
  final ColorScheme colorScheme;

  QiblaCompassPainter({
    required this.qiblaAngle,
    required this.deviceHeading,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw outer fixed frame (Indicator for phone top)
    // Fixed indicator at the top
    final path = Path();
    path.moveTo(center.dx, center.dy - radius - 5);
    path.lineTo(center.dx - 10, center.dy - radius + 15);
    path.lineTo(center.dx + 10, center.dy - radius + 15);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700));

    // 2. DRAW THE ROTATING ROSE (Letters and Ticks)
    // Rotation = -deviceHeading (To keep North at 0 in world space)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-deviceHeading * (pi / 180));
    canvas.translate(-center.dx, -center.dy);

    // Compass Background
    final circlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorScheme.surface.withValues(alpha: 0.8),
          colorScheme.surface,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final borderPaint = Paint()
      ..color = const Color(0xFFC5A358)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Ticks
    final tickPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
    final majorTickPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.6)
      ..strokeWidth = 2.0;

    for (int i = 0; i < 360; i += 10) {
      final double angle = i * (pi / 180);
      final bool isMajor = i % 90 == 0;
      final double tickLength = isMajor ? 15 : 8;

      final start = Offset(
        center.dx + (radius - 5) * cos(angle - pi / 2),
        center.dy + (radius - 5) * sin(angle - pi / 2),
      );
      final end = Offset(
        center.dx + (radius - 5 - tickLength) * cos(angle - pi / 2),
        center.dy + (radius - 5 - tickLength) * sin(angle - pi / 2),
      );
      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }

    // Cardinal Letters (Arabic: ش=North, ج=South, شر=East, غ=West)
    _drawText(canvas, center, "ش", Offset(center.dx, center.dy - radius + 35), color: Colors.redAccent);
    _drawText(canvas, center, "ج", Offset(center.dx, center.dy + radius - 35));
    _drawText(canvas, center, "شر", Offset(center.dx + radius - 35, center.dy), fontSize: 17);
    _drawText(canvas, center, "غ", Offset(center.dx - radius + 35, center.dy));

    canvas.restore(); // Rose is done

    // 3. DRAW THE QIBLA NEEDLE
    // In logs: qiblah - deviceHeading = constant bearing to Mecca.
    // We want the needle at (bearing - deviceHeading) relative to phone.

    final double bearing = qiblaAngle - deviceHeading;
    final double needleRotation = (bearing - deviceHeading) * (pi / 180);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(needleRotation);

    // Needle shape (Diamond)
    final needlePath = Path();
    needlePath.moveTo(0, -radius + 50); // Top tip
    needlePath.lineTo(14, 0); // Right
    needlePath.lineTo(0, radius - 50); // Bottom tip
    needlePath.lineTo(-14, 0); // Left
    needlePath.close();

    // Red half (Top)
    final redPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.redAccent, Color(0xFFD32F2F)],
      ).createShader(Rect.fromLTWH(-14, -radius, 28, radius));

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-20, -radius, 40, radius));
    canvas.drawPath(needlePath, redPaint);
    canvas.restore();

    // Theme-aware half (Bottom)
    final bottomPaint =
        Paint()..color = colorScheme.onSurface.withValues(alpha: 0.7);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(-20, 0, 40, radius));
    canvas.drawPath(needlePath, bottomPaint);
    canvas.restore();

    // 4. Draw Kaaba Icon at needle tip
    final kaabaPaint = Paint()..color = Colors.black;
    final kaabaBorderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final kaabaRect = Rect.fromCenter(
      center: Offset(0, -radius + 50),
      width: 12,
      height: 12,
    );
    canvas.drawRect(kaabaRect, kaabaPaint);
    canvas.drawRect(kaabaRect, kaabaBorderPaint);

    canvas.restore();

    // 5. Draw center dot
    final centerDotPaint = Paint()..color = colorScheme.onSurface;
    final centerDotBorderPaint = Paint()
      ..color = colorScheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, 7, centerDotPaint);
    canvas.drawCircle(center, 7, centerDotBorderPaint);
  }

  void _drawText(Canvas canvas, Offset center, String text, Offset position, {Color? color, double? fontSize}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? colorScheme.onSurface,
          fontSize: fontSize ?? 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
                color: colorScheme.surface.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(1, 1))
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant QiblaCompassPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.deviceHeading != deviceHeading ||
        oldDelegate.colorScheme != colorScheme;
  }
}

/// Helper class to track location status
class LocationStatus {
  final PermissionStatus status;
  final bool enabled;

  LocationStatus(this.status, this.enabled);
}
