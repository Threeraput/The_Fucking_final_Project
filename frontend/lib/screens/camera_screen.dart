// lib/screens/camera_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/image_utils.dart'; // ✅ ใช้ยูทิลหมุน/ย่อภาพก่อนอัปโหลด
import '../services/face_service.dart';
import '../services/face_service.dart'
    show ApiException; // ✅ จับ ApiException โดยตรง

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
    _controller = null; // ✅ เคลียร์อ้างอิงเสมอ
    c?.dispose();
  }

  /// จัดการ lifecycle: แอปพัก/กลับมาใหม่ ให้ reinitialize กล้อง
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
      _controller = null; // ✅ กันใช้ instance ที่ถูก dispose ไปแล้ว
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

  Future<void> _captureAndProcess() async {
    final controller = _controller;
    if (_isProcessing || _isCapturing) return; // กันกดรัว
    if (controller == null || !controller.value.isInitialized) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      await _initializeControllerFuture;

      // 1) ถ่ายรูปดิบจากกล้อง
      final XFile file = await controller.takePicture();

      // Debug ขนาดไฟล์จากกล้อง
      final rawBytes = await File(file.path).length();
      // ignore: avoid_print
      print("📸 Captured file: ${file.path} ($rawBytes bytes)");

      // 2) ✅ หมุนตาม EXIF + ย่อ + บีบอัดก่อนส่ง (ตัวเลือก A: image)
      final normalizedPath = await normalizeAndSaveJpeg(
        file.path,
        maxWidth: 1600,
        jpegQuality: 92,
      );

      final normBytes = await File(normalizedPath).length();
      // ignore: avoid_print
      print(" Normalized file: $normalizedPath ($normBytes bytes)");

      // 3) (ออปชัน) พรีวิวไฟล์ที่ normalize แล้ว
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Image.file(File(normalizedPath), cacheWidth: 1080),
        ),
      );
      if (!mounted) return;

      setState(() {
        _isProcessing = true;
      });

      // 4) อัปโหลด/ยืนยันโดยใช้ไฟล์ที่ normalize แล้ว
      if (widget.isVerificationMode) {
        final success = await FaceService.verifyFace(normalizedPath);
        if (!mounted) return;
        _showResultDialog(
          success ? 'ยืนยันตัวตนสำเร็จ' : 'ไม่พบใบหน้าที่ตรงกัน',
          success ? Colors.green : Colors.red,
        );
      } else {
        final resp = await FaceService.uploadFace(normalizedPath);
        // ignore: avoid_print
        print("✅ Upload response: $resp");
        if (!mounted) return;
        _showResultDialog('อัปโหลดใบหน้าสำเร็จ', Colors.green);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showResultDialog(e.message, Colors.red); // ✅ โชว์ข้อความจาก backend
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
              Navigator.of(context).pop(); // ปิด dialog
              Navigator.of(context).maybePop(); // กลับหน้าก่อนหน้า (ถ้าต้องการ)
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

                // ✅ เต็มจอแบบครอป (cover)
                return SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      // previewSize ของกล้องส่วนใหญ่เป็น landscape
                      // พอถือมือถือแนวตั้ง ให้ "สลับ" width/height
                      width: controller.value.previewSize!.height,
                      height: controller.value.previewSize!.width,
                      child: CameraPreview(controller),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isProcessing || _isCapturing) ? null : _captureAndProcess,
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
