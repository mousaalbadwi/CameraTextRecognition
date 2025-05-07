import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'cloud_vision_ocr.dart';

class TestRecognitionPage extends StatefulWidget {
  const TestRecognitionPage({super.key});
  @override
  State<TestRecognitionPage> createState() => _TestRecognitionPageState();
}

class _TestRecognitionPageState extends State<TestRecognitionPage> {
  bool _busy = false;
  List<String> _paragraphs = [];
  List<String> _lines = [];
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.awaitSpeakCompletion(true);
    _tts.setSpeechRate(0.4);
  }

  Future<void> _analyzeImage() async {
    setState(() => _busy = true);
    try {
      // 1) حمّل البايت من الأصول
      final data = await rootBundle.load('assets/test.jpg');
      final bytes = data.buffer.asUint8List();

      // 2) استخرج النص الكامل
      final rawText = (await CloudVisionOcr.recognizeText(bytes)).trim();

      // 3) قسم إلى فقرات عبر السطر الفارغ
      final paras = rawText
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.replaceAll('\n', ' ').trim())
          .where((p) => p.isNotEmpty)
          .toList();

      // 4) قسم إلى أسطر حسب الفواصل السطرية
      final lines = rawText
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      setState(() {
        _paragraphs = paras;
        _lines = lines;
      });
    } catch (e) {
      setState(() {
        _paragraphs = ['حدث خطأ أثناء المعالجة:\n$e'];
        _lines = [];
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _readText(String text) async {
    final isAr = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    await _tts.setLanguage(isAr ? 'ar' : 'en-US');
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار تقسيم الفقرات والأسطر')),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // زرّ التحليل
          ElevatedButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.photo),
            label: Text(_busy ? 'جارٍ التحليل...' : 'حلّل الصورة'),
            onPressed: _busy ? null : _analyzeImage,
          ),

          const Divider(),

          // قائمة الفقرات
          Expanded(
            flex: 1,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : _paragraphs.isEmpty
                    ? const Center(child: Text('اضغط لتحليل الفقرات'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _paragraphs.length,
                        itemBuilder: (ctx, i) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text('فقرة ${i+1}'),
                            subtitle: Text(_paragraphs[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () => _readText(_paragraphs[i]),
                            ),
                          ),
                        ),
                      ),
          ),

          const Divider(),

          // قائمة الأسطر
          Expanded(
            flex: 1,
            child: _busy
                ? const SizedBox() // أو ابقّي ProgressIndicator
                : _lines.isEmpty
                    ? const Center(child: Text('لا توجد أسطر حتى الآن'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _lines.length,
                        itemBuilder: (ctx, i) => Card(
                          color: Colors.grey[100],
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            title: Text('سطر ${i+1}'),
                            subtitle: Text(_lines[i]),
                            trailing: IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () => _readText(_lines[i]),
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
