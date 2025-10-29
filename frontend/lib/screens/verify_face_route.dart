// lib/screens/verify_face_route.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';

class VerifyFaceRoute extends StatefulWidget {
  const VerifyFaceRoute({super.key});

  @override
  State<VerifyFaceRoute> createState() => _VerifyFaceRouteState();
}

class _VerifyFaceRouteState extends State<VerifyFaceRoute> {
  CameraDescription? _camera;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error = 'ไม่พบกล้องบนอุปกรณ์');
        return;
      }
      // เลือกกล้องหน้าเป็นอันดับแรก ถ้ามี
      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      setState(() => _camera = front);
    } catch (e) {
      setState(() => _error = 'เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ยืนยันตัวตนด้วยใบหน้า')),
        body: Center(child: Text(_error!)),
      );
    }
    if (_camera == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return CameraScreen(camera: _camera!, isVerificationMode: true);
  }
}
