class VideoModel {
  final String id;
  final String filePath;
  final String? title;
  final int durationMs;
  final DateTime addedAt;
  final DateTime modifiedAt;
  final int? width;
  final int? height;

  VideoModel({
    required this.id,
    required this.filePath,
    this.title,
    required this.durationMs,
    required this.addedAt,
    required this.modifiedAt,
    this.width,
    this.height,
  });

  String get durationFormatted {
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileName {
    return filePath.split('\\').last.split('/').last;
  }
}