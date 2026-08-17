import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Selfie capture screen for identity verification.
///
/// A plain front-camera viewfinder — no face detection, no crop, no overlay
/// magic. The preview always keeps the camera's own aspect ratio (never
/// stretched) and the photo is taken with the shutter button, just like
/// photographing a passport with the stock camera app.
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
  bool _initializing = true;
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

      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();

      if (!mounted) return;
      setState(() => _initializing = false);
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
      final controller = CameraController(front, ResolutionPreset.high,
          enableAudio: false);
      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (_) {}
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

    // CameraPreview sizes itself to the camera's own aspect ratio. Centered on
    // a black background it can never be stretched, whatever the device.
    final preview = Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        // Hint text.
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: AppTheme.spaceSm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Cadrez votre visage puis appuyez',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        // Shutter button.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: GestureDetector(
              onTap: _capture,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                padding: const EdgeInsets.all(6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
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
                      : const Center(
                          child: Icon(
                            Icons.photo_camera_rounded,
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
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}