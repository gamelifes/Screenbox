import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class TitleBarTestPage extends ConsumerStatefulWidget {
  const TitleBarTestPage({super.key});

  @override
  ConsumerState<TitleBarTestPage> createState() => _TitleBarTestPageState();
}

class _TitleBarTestPageState extends ConsumerState<TitleBarTestPage> {
  TitleBarStyle _currentStyle = TitleBarStyle.normal;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWindowManager();
  }

  Future<void> _initializeWindowManager() async {
    await windowManager.ensureInitialized();
    // We'll assume it's initialized after ensureInitialized
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _setTitleBarStyle(TitleBarStyle style) async {
    await windowManager.setTitleBarStyle(style);
    setState(() {
      _currentStyle = style;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Manager Title Bar Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Window Manager Title Bar Style Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Window Manager Initialized: $_isInitialized',
              style: TextStyle(
                color: _isInitialized ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current Title Bar Style: $_currentStyle',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              'Test Buttons:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isInitialized 
                      ? () => _setTitleBarStyle(TitleBarStyle.hidden) 
                      : null,
                  child: const Text('Hidden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStyle == TitleBarStyle.hidden 
                        ? Colors.blue 
                        : null,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isInitialized 
                      ? () => _setTitleBarStyle(TitleBarStyle.normal) 
                      : null,
                  child: const Text('Normal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStyle == TitleBarStyle.normal 
                        ? Colors.blue 
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. Click buttons to change title bar style\n'
              '2. Observe if the title bar of this window changes\n'
              '3. Note: This test page must be run in a desktop window\n'
              '   (Windows, macOS, or Linux) to see the effect',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}