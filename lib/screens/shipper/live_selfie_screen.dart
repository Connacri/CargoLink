import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../core/theme/app_theme.dart';

/// Selfie capture screen for identity verification.
///
/// Opens the front camera with a face-shaped oval guide in the center. ML Kit
/// (on-device, free — no cloud call) continuously checks that a human face is
/// present, roughly centered and correctly scaled inside the guide. When the
/// conditions are met, the guide turns green and the photo is captured
/// automatically (also available via the shutter button).
class LiveSelfieScreen extends StatefulWidget {
  const LiveSelfieScreen({super.key});

  /// Resolves with the captured photo file path, or null if cancelled.
  static Future<String?> capture(BuildContext context) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const LiveSelfieScreen()),
    );
    return path;
  }

  @override
  State<LiveSelfieScreen> createState() => _LiveSelfieScreenState();
}

class _LiveSelfieScreenState extends State<LiveSelfieScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  FaceDetector? _detector;
  bool _initializing = true;
  bool _processing = false;
  bool _valid = false;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _restartCamera();
    }
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      CameraDescription front = cameras.isNotEmpty ? cameras.first : throw StateError('Pas de caméra');
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }

      _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: false,
          enableLandmarks: false,
          enableContours: false,
          enableTracking: false,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();

      if (!mounted) return;
      setState(() => _initializing = false);

      await controller.startImageStream(_onImage);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Impossible d\'ouvrir la caméra: $e';
      });
    }
  }

  Future<void> _restartCamera() async {
    try {
      final cameras = await availableCameras();
      CameraDescription front = cameras.first;
      for (final c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }
      final controller = CameraController(front, ResolutionPreset.medium,
          enableAudio: false);
      _controller = controller;
      await controller.initialize();
      await controller.startImageStream(_onImage);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  /// Converts a raw [CameraImage] (YUV) into an [InputImage] for ML Kit.
  /// The planes are concatenated so the buffer is laid out as NV21 YUV
  /// (Y plane + interleaved UV), which is the format ML Kit expects on
  /// Android camera streams.
  InputImage _imageFromCamera(CameraImage image) {
    final width = image.width;
    final height = image.height;

    // Concatenate all planes (Y, U, V).
    final buffer = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      buffer.add(plane.bytes);
    }
    final bytes = buffer.toBytes();

    final rotation = _controller?.description.sensorOrientation ?? 90;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: InputImageRotation.values.firstWhere(
          (r) => r.rawValue == rotation,
          orElse: () => InputImageRotation.rotation90deg,
        ),
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Future<void> _onImage(CameraImage image) async {
    if (_processing || _capturing) return;
    final detector = _detector;
    if (detector == null) return;

    _processing = true;
    try {
      final faces = await detector.processImage(_imageFromCamera(image));
      if (!mounted) {
        return;
      }
      final ok = _faceMatchesGuide(faces, image);
      setState(() {
        _valid = ok;
      });
    } catch (_) {
    } finally {
      _processing = false;
    }
  }

  /// True when a single face is detected, roughly centered in the guide area
  /// and filling a sensible portion of it (too small = too far, too large =
  /// too close).
  bool _faceMatchesGuide(List<Face> faces, CameraImage image) {
    if (faces.length != 1) return false;
    final box = faces.first.boundingBox;
    final imgWidth = image.width.toDouble();
    final imgHeight = image.height.toDouble();

    final center = Offset(box.center.dx, box.center.dy);
    final imgCenter = Offset(imgWidth / 2, imgHeight / 2);

    // Allow a bit of tolerance for centering.
    final centerOffset = (center - imgCenter).distance;
    final maxCenterDistance = min(imgWidth, imgHeight) * 0.12;
    if (centerOffset > maxCenterDistance) return false;

    final boxWidth = box.width;
    final minFaceW = imgWidth * 0.18;
    final maxFaceW = imgWidth * 0.55;
    if (boxWidth < minFaceW || boxWidth > maxFaceW) return false;

    // Reject strongly tilted faces.
    final eulerZ = faces.first.headEulerAngleZ ?? 0;
    if (eulerZ.abs() > 25) return false;

    return true;
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (e) {
      if (mounted) {
        _showError('Capture impossible: $e');
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? _buildError()
                : _buildCamera(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                size: 56, color: Colors.white54),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              _error ?? 'Erreur',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final preview = CameraPreview(controller);

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        // Dark overlay + face guide.
        CustomPaint(
          painter: _SelfieOverlayPainter(
            valid: _valid,
            color: _valid ? const Color(0xFF2ECC71) : Colors.white,
          ),
        ),
        // Status + hint.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceSm,
                  ),
                  decoration: BoxDecoration(
                    color: (_valid ? const Color(0xFF2ECC71) : Colors.white)
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _valid
                            ? Icons.check_circle_rounded
                            : Icons.person_rounded,
                        size: 18,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _valid
                            ? 'Visage détecté'
                            : 'Placez votre visage dans le cadre',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                const Text(
                  'Regardez la caméra, gardez le visage au centre',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        // Shutter button.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 96),
            child: GestureDetector(
              onTap: _valid ? _capture : null,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _valid ? const Color(0xFF2ECC71) : Colors.white,
                    width: 4,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _valid
                        ? const Color(0xFF2ECC71).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  child: _capturing
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            _valid
                                ? Icons.check_rounded
                                : Icons.photo_camera_rounded,
                            size: 30,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        // Close button.
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws a darkened frame with an oval guide for the face in the center. Turns
/// green once the face is detected and correctly placed.
class _SelfieOverlayPainter extends CustomPainter {
  const _SelfieOverlayPainter({required this.valid, required this.color});

  final bool valid;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width;
    final dy = size.height;
    final guideWidth = dx * 0.62;
    final guideHeight = guideWidth * 1.28;
    final guide = Rect.fromCenter(
      center: Offset(dx / 2, dy / 2 - dy * 0.04),
      width: guideWidth,
      height: guideHeight,
    );

    // Dim the surrounding area.
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, dx, dy)),
      Path()..addOval(guide),
    );
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Face outline (oval) guide.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    canvas.drawOval(guide, paint);

    // Corner brackets for a professional look.
    final inner = guide.deflate(10);
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    const len = 26.0;
    canvas.drawLine(inner.topLeft, inner.topLeft + const Offset(len, 0), bracket);
    canvas.drawLine(inner.topLeft, inner.topLeft + const Offset(0, len), bracket);
    canvas.drawLine(inner.topRight, inner.topRight - const Offset(len, 0), bracket);
    canvas.drawLine(inner.topRight, inner.topRight + const Offset(0, len), bracket);
    canvas.drawLine(inner.bottomLeft, inner.bottomLeft + const Offset(len, 0), bracket);
    canvas.drawLine(inner.bottomLeft, inner.bottomLeft - const Offset(0, len), bracket);
    canvas.drawLine(inner.bottomRight, inner.bottomRight - const Offset(len, 0), bracket);
    canvas.drawLine(inner.bottomRight, inner.bottomRight - const Offset(0, len), bracket);

    final centerDot = Paint()
      ..color = color.withValues(alpha: valid ? 0.0 : 0.5);
    canvas.drawCircle(guide.center, 4, centerDot);
  }

  @override
  bool shouldRepaint(covariant _SelfieOverlayPainter oldDelegate) =>
      oldDelegate.valid != valid || oldDelegate.color != color;
}