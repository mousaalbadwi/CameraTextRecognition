import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'cloud_vision_ocr.dart';

class TextRecognitionPage extends StatefulWidget {
  const TextRecognitionPage({super.key});
  @override
  State<TextRecognitionPage> createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends State<TextRecognitionPage> {
  CameraController? _camCtrl;
  bool _cameraReady = false;
  bool _processing = false;
  bool _flashOn = false;
  List<String> _paragraphs = [];
  List<String> _lines = [];
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    dotenv.load(fileName: '.env');
    _initCamera();
    _tts.awaitSpeakCompletion(true);
    _tts.setSpeechRate(0.4);
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final back = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cams.first,
    );
    _camCtrl = CameraController(
      back,
      ResolutionPreset.max,          // أقصى دقة
      enableAudio: false,
    );
    await _camCtrl!.initialize();

    // autofocus & auto exposure
    await _camCtrl!.setFocusMode(FocusMode.auto);
    await _camCtrl!.setExposureMode(ExposureMode.auto);

    if (!mounted) return;
    setState(() => _cameraReady = true);
  }

  Future<void> _toggleFlash() async {
    if (!_cameraReady) return;
    _flashOn = !_flashOn;
    await _camCtrl!.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _captureAndProcess() async {
    if (_processing || !_cameraReady) return;
    setState(() => _processing = true);

    try {
      final tmp = await getTemporaryDirectory();
      final path = join(tmp.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final XFile file = await _camCtrl!.takePicture();
      await file.saveTo(path);
      final Uint8List bytes = await File(path).readAsBytes();

      final rawText = (await CloudVisionOcr.recognizeText(bytes)).trim();

      final allLines = rawText
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final paras = <String>[];
      var buffer = '';
      for (final line in allLines) {
        buffer = buffer.isEmpty ? line : '$buffer $line';
        if (RegExp(r'[\.؟!\?]$').hasMatch(line)) {
          paras.add(buffer.trim());
          buffer = '';
        }
      }
      if (buffer.isNotEmpty) paras.add(buffer.trim());

      setState(() {
        _lines = allLines;
        _paragraphs = paras;
      });
    } catch (e) {
      setState(() {
        _lines = [];
        _paragraphs = ['حدث خطأ أثناء المعالجة:\n$e'];
      });
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _speak(String text) async {
    final isAr = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    await _tts.setLanguage(isAr ? 'ar' : 'en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Camera'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_cameraReady)
            AspectRatio(
              aspectRatio: _camCtrl!.value.aspectRatio,
              child: CameraPreview(_camCtrl!),
            )
          else
            Container(
              height: 200,
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            icon: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(_processing ? 'جارٍ المعالجة...' : 'التقاط وقراءة'),
            onPressed: (!_cameraReady || _processing) ? null : _captureAndProcess,
          ),

          const Divider(),

          // الفقرات
          Expanded(
            child: _paragraphs.isEmpty
                ? const Center(child: Text('اضغط "التقاط وقراءة" لبدء'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _paragraphs.length,
                    itemBuilder: (ctx, i) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('فقرة ${i + 1}'),
                        subtitle: Text(_paragraphs[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _speak(_paragraphs[i]),
                        ),
                      ),
                    ),
                  ),
          ),

          const Divider(),

          // الأسطر
          Expanded(
            child: _lines.isEmpty
                ? const Center(child: Text('لا توجد أسطر بعد'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _lines.length,
                    itemBuilder: (ctx, i) => Card(
                      color: Colors.grey[100],
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        title: Text('سطر ${i + 1}'),
                        subtitle: Text(_lines[i]),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _speak(_lines[i]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
