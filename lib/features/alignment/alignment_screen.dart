import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../widgets/reticle_painter.dart';

class AlignmentScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const AlignmentScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<AlignmentScreen> createState() => _AlignmentScreenState();
}

class _AlignmentScreenState extends State<AlignmentScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  
  Offset? _liveCentroid = const Offset(200, 300);
  final Offset _referencePoint = const Offset(200, 200);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _errorMessage = "No cameras detected on this device.";
      });
      return;
    }
    
    try {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() {
        _errorMessage = "Failed to initialize camera: $e";
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state if initialization failed
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laser Alignment Tracker')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Show loading spinner while initializing
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera stream...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Laser Alignment Tracker')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          CustomPaint(
            painter: ReticlePainter(
              centroid: _liveCentroid,
              referencePoint: _referencePoint,
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Status: Tracking Active | Delta X: +12px, Delta Y: -5px',
                style: TextStyle(color: Colors.greenAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}