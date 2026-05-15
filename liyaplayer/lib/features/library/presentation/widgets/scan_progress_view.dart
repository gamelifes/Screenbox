import 'package:flutter/material.dart';
import 'package:liyaplayer/features/library/domain/repositories/library_repository.dart';

/// View displaying scan progress
class ScanProgressView extends StatelessWidget {
  final ScanProgress progress;
  final VoidCallback? onCancel;

  const ScanProgressView({
    super.key,
    required this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress.progress * 100).toInt();

    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scanning...',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.progress,
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$percentage%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progress.foundCount} files found',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Current:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 300,
                child: Text(
                  progress.currentFile,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
