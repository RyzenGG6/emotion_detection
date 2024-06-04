import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EmotionDetection(),
    );
  }
}

class EmotionDetection extends StatefulWidget {
  @override
  _EmotionDetectionState createState() => _EmotionDetectionState();
}

class _EmotionDetectionState extends State<EmotionDetection> {
  CameraController? _controller;
  bool _isDetecting = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {});
    _controller!.startImageStream((CameraImage img) {
      if (!_isDetecting) {
        _isDetecting = true;
        _runModelOnFrame(img).then((_) {
          _isDetecting = false;
        });
      }
    });
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
    );
  }

  Future<void> _runModelOnFrame(CameraImage img) async {
    var recognitions = await Tflite.runModelOnFrame(
      bytesList: img.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: img.height,
      imageWidth: img.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResults: 5,
      threshold: 0.5,
      asynch: true,
    );

    setState(() {
      _result = recognitions?.map((res) => res.toString()).join(', ') ?? 'No results';
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Emotion Detection')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Center(
            child: Text(
              _result,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
