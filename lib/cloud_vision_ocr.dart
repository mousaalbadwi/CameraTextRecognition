import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudVisionOcr {
  /// أرسل الصورة إلى Cloud Vision وأرجع النص الكامل
  static Future<String> recognizeText(List<int> imageBytes) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? "";
    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );
    final base64Image = base64Encode(imageBytes);
    final payload = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
          ]
        }
      ]
    };
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Cloud Vision API error ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    return data['responses'][0]?['fullTextAnnotation']?['text'] ?? "";
  }

  /// أرسل الصورة وأرجع قائمة الفقرات كما في الورقة بالضبط
  static Future<List<String>> recognizeParagraphs(List<int> imageBytes) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? "";
    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );
    final base64Image = base64Encode(imageBytes);
    final payload = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
          ]
        }
      ]
    };
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Cloud Vision API error ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final pages = json['responses'][0]?['fullTextAnnotation']?['pages'] as List? ?? [];
    final List<String> paras = [];
    for (var page in pages) {
      final blocks = page['blocks'] as List<dynamic>;
      for (var block in blocks) {
        final paragraphs = block['paragraphs'] as List<dynamic>;
        for (var para in paragraphs) {
          var text = StringBuffer();
          final words = para['words'] as List<dynamic>;
          for (var w in words) {
            final symbols = w['symbols'] as List<dynamic>;
            for (var s in symbols) {
              text.write(s['text']);
              // نتعامل مع فواصل الكلمات كما جاء في الاستجابة
              final prop = s['property']?['detectedBreak'];
              if (prop != null) {
                switch (prop['type']) {
                  case 'SPACE':
                    text.write(' ');
                    break;
                  case 'EOL_SURE_SPACE':
                  case 'LINE_BREAK':
                    text.write('\n');
                    break;
                  case 'HYPHEN':
                    text.write('-');
                    break;
                }
              }
            }
          }
          paras.add(text.toString().trim());
        }
      }
    }
    return paras;
  }
}
