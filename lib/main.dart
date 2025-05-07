import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'text_recognition_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // حمّل .env من الـ assets
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera OCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
     home: const TestRecognitionPage(),  
       );
  }
}
