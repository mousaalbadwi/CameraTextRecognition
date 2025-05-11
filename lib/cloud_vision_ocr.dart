import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudVisionOcr {
  static Future<String> recognizeText(Uint8List imageBytes) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );
    final base64Image = base64Encode(imageBytes);
    final payload = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'DOCUMENT_TEXT_DETECTION'}
          ],
        }
      ]
    });

    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (res.statusCode != 200) {
      throw Exception('Cloud Vision API error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    return data['responses'][0]?['fullTextAnnotation']?['text'] as String? ?? '';
  }
}
