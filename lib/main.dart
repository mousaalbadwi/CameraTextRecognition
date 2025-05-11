import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'text_recognition_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Camera',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TextRecognitionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
