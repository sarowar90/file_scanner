import 'package:flutter/material.dart';
import 'services/file_history_service.dart';
import 'screens/scanner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final FileHistoryService _historyService = FileHistoryService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _historyService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900, Colors.black]),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 24),
                Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
        ),
      );
    }

    return ScannerScreen(historyService: _historyService);
  }
}
