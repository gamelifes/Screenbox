import 'package:flutter/material.dart';

class EmptyLibraryView extends StatelessWidget {
  final VoidCallback onAddDirectory;

  const EmptyLibraryView({super.key, required this.onAddDirectory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('你的音乐库是空的', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('添加音乐目录开始使用'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddDirectory,
            icon: const Icon(Icons.add),
            label: const Text('添加目录'),
          ),
        ],
      ),
    );
  }
}
