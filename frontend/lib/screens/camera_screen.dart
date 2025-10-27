// lib/screens/camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/image_utils.dart';
import '../services/face_service.dart';
import '../services/face_service.dart' show ApiException;
import 'classroom_home_screen.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  final bool isVerificationMode;

  const CameraScreen({
    super.key,
    required this.camera,
    this.isVerificationMode = false,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;
  bool _isCapturing = false;

  bool _consentGiven = false;
  bool _askedConsent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _initializeControllerFuture = _controller!
        .initialize()
        .then((_) async {
          if (!mounted) return;
          await _controller?.setFlashMode(FlashMode.off);
        })
        .catchError((e) {
          _showResultDialog('เปิดกล้องไม่สำเร็จ: $e', Colors.red);
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream().catchError((_) {});
      }
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _initializeControllerFuture = _controller!
          .initialize()
          .then((_) async {
            if (!mounted) return;
            await _controller?.setFlashMode(FlashMode.off);
            setState(() {});
          })
          .catchError((e) {
            _showResultDialog('เปิดกล้องใหม่ไม่สำเร็จ: $e', Colors.red);
          });
      setState(() {});
    }
  }

  Future<void> _askForConsent() async {
    if (_askedConsent) return;
    _askedConsent = true;

    // 🔸 ถ้าเป็นโหมด verify ไม่ต้องถาม
    if (widget.isVerificationMode) {
      setState(() => _consentGiven = true);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ขออนุญาตเก็บข้อมูลใบหน้า'),
        content: const Text(
          'ระบบจะเก็บข้อมูลใบหน้าของคุณเพื่อใช้ในการยืนยันตัวตนในการเช็คชื่อในอนาคต '
          'คุณยินยอมให้ระบบบันทึกข้อมูลนี้หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ไม่ยินยอม'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยินยอม'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _consentGiven = true);
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ClassroomHomeScreen()),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() => _askForConsent());
  }

  Future<void> _captureAndProcess() async {
    if (!_consentGiven && !widget.isVerificationMode) return;

    final controller = _controller;
    if (_isProcessing || _isCapturing) return;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      setState(() => _isCapturing = true);
      await _initializeControllerFuture;

      final XFile file = await controller.takePicture();
      final normalizedPath = await normalizeAndSaveJpeg(
        file.path,
        maxWidth: 1600,
        jpegQuality: 92,
      );

      setState(() => _isProcessing = true);

      if (widget.isVerificationMode) {
        final success = await FaceService.verifyFace(normalizedPath);
        if (!mounted) return;
        _showResultDialog(
          success ? 'ยืนยันตัวตนสำเร็จ' : 'ไม่พบใบหน้าที่ตรงกัน',
          success ? Colors.green : Colors.red,
        );
      } else {
        final resp = await FaceService.uploadFace(normalizedPath);
        if (!mounted) return;
        _showResultDialog('อัปโหลดใบหน้าสำเร็จ', Colors.green);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showResultDialog(e.message, Colors.red);
    } catch (e) {
      if (!mounted) return;
      _showResultDialog('เกิดข้อผิดพลาด: $e', Colors.red);
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isCapturing = false;
      });
    }
  }

  void _showResultDialog(String message, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message, style: TextStyle(color: color)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ClassroomHomeScreen()),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isVerificationMode
              ? 'ยืนยันตัวตนด้วยใบหน้า'
              : 'เพิ่มรูปภาพใบหน้า',
        ),
      ),
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!_consentGiven && !widget.isVerificationMode) {
                  return const Center(
                    child: Text(
                      'กรุณายืนยันการเก็บข้อมูลใบหน้าก่อนเริ่มการถ่ายภาพ...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return Stack(
                  children: [
                    // 🔸 กล้องเต็มจอ
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.previewSize!.height,
                          height: controller.value.previewSize!.width,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),

                    // 🔹 ปุ่ม Skip (มุมขวาบน)
                    Positioned(
                      top: 40,
                      right: 16,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ClassroomHomeScreen()),
                          );
                        },
                        child: const Text(
                          'ข้าม',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // 🔸 ปุ่มถ่ายภาพ
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: FloatingActionButton(
                          onPressed: (_isProcessing || _isCapturing)
                              ? null
                              : _captureAndProcess,
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Icon(Icons.camera_alt),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
