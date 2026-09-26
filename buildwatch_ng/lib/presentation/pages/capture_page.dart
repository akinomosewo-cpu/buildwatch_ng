import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/milestone.dart';
import '../../core/theme/app_theme.dart';

/// In-app-only capture screen for progress proof.
///
/// This screen deliberately has NO gallery/file picker of any kind. The
/// only way to attach a photo or video to a milestone is to shoot it here,
/// right now, with the device camera — that is what makes the geotag and
/// timestamp trustworthy as proof of real on-site progress.
class CapturePage extends StatefulWidget {
  final String milestoneId;
  final String milestoneTitle;
  const CapturePage({super.key, required this.milestoneId, required this.milestoneTitle});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  CameraController? _controller;
  Future<void>? _initFuture;
  Position? _position;
  String? _error;
  bool _isVideoMode = false;
  bool _isRecording = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _setup();
  }

  Future<void> _setup() async {
    try {
      await _resolvePosition();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(rearCamera, ResolutionPreset.high, enableAudio: true);
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      setState(() => _error = 'Could not start camera: $e');
    }
  }

  Future<void> _resolvePosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _error = 'Turn on location services to geotag this check-in.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission is required to submit proof.');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _position = position);
    } catch (e) {
      setState(() => _error = 'Could not read GPS location: $e');
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    if (_position == null) {
      _toast('Waiting for GPS lock — try again in a moment.');
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      _finishCapture(file.path, isVideo: false);
    } catch (e) {
      _toast('Capture failed: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _toggleVideo() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_isRecording) {
      if (_position == null) {
        _toast('Waiting for GPS lock — try again in a moment.');
        return;
      }
      await controller.startVideoRecording();
      setState(() => _isRecording = true);
    } else {
      final file = await controller.stopVideoRecording();
      setState(() => _isRecording = false);
      _finishCapture(file.path, isVideo: true);
    }
  }

  void _finishCapture(String path, {required bool isVideo}) {
    final entry = ProgressEntry(
      id: const Uuid().v4(),
      milestoneId: widget.milestoneId,
      mediaPath: path,
      isVideo: isVideo,
      capturedAt: DateTime.now(),
      latitude: _position!.latitude,
      longitude: _position!.longitude,
    );
    if (mounted) Navigator.pop(context, entry);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Capture — ${widget.milestoneTitle}'),
      ),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (_error != null) {
            return _ErrorState(message: _error!, onRetry: () {
              setState(() {
                _error = null;
                _initFuture = _setup();
              });
            });
          }
          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              _GeotagOverlay(position: _position),
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: _CaptureControls(
                  isVideoMode: _isVideoMode,
                  isRecording: _isRecording,
                  capturing: _capturing,
                  onModeChanged: (v) => setState(() => _isVideoMode = v),
                  onShutter: _isVideoMode ? _toggleVideo : _capturePhoto,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GeotagOverlay extends StatelessWidget {
  final Position? position;
  const _GeotagOverlay({required this.position});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timestamp = DateFormat('EEE d MMM yyyy · HH:mm:ss').format(now);
    final coords = position == null
        ? 'Locating…'
        : '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}';
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
            const Gap(6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coords,
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                  Text(timestamp,
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CaptureControls extends StatelessWidget {
  final bool isVideoMode;
  final bool isRecording;
  final bool capturing;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onShutter;

  const _CaptureControls({
    required this.isVideoMode,
    required this.isRecording,
    required this.capturing,
    required this.onModeChanged,
    required this.onShutter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ModeChip(label: 'Photo', selected: !isVideoMode, onTap: () => onModeChanged(false)),
            const Gap(12),
            _ModeChip(label: 'Video', selected: isVideoMode, onTap: () => onModeChanged(true)),
          ],
        ),
        const Gap(20),
        GestureDetector(
          onTap: capturing ? null : onShutter,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: isRecording ? AppColors.danger : Colors.transparent,
            ),
            child: Center(
              child: Container(
                width: isRecording ? 28 : 60,
                height: isRecording ? 28 : 60,
                decoration: BoxDecoration(
                  color: capturing ? Colors.white38 : (isVideoMode ? AppColors.danger : Colors.white),
                  shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: isRecording ? BorderRadius.circular(6) : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
            const Gap(12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
            const Gap(16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
