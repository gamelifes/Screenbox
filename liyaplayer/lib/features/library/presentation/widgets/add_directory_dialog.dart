import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AddDirectoryDialog extends StatefulWidget {
  final Future<void> Function(String path) onAdd;

  const AddDirectoryDialog({super.key, required this.onAdd});

  @override
  State<AddDirectoryDialog> createState() => _AddDirectoryDialogState();
}

class _AddDirectoryDialogState extends State<AddDirectoryDialog> {
  String? _selectedPath;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _selectedPath = result;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = '选择目录失败: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedPath == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onAdd(_selectedPath!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = '添加目录失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加音乐目录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '选择一个包含音乐文件的目录',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedPath ?? '未选择目录',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickDirectory,
                icon: const Icon(Icons.folder_open),
                label: const Text('浏览'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _selectedPath == null || _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
    );
  }
}