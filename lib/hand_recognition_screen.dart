import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HandRecognitionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HandRecognitionScreen({super.key, required this.cameras});

  @override
  State<HandRecognitionScreen> createState() => _HandRecognitionScreenState();
}

class _HandRecognitionScreenState extends State<HandRecognitionScreen> {
  late CameraController controller;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await controller.initialize();

    await controller.startImageStream((CameraImage image) {
      if (isDetecting) return;

      isDetecting = true;

      print("Frame Captured");

      // هنا لاحقاً بنضيف MediaPipe

      isDetecting = false;
    });

    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Hand Recognition")),

      body: CameraPreview(controller),
    );
  }
}
