import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';

/// 媒体项实体
class MediaItem extends Equatable {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? duration;
  final String? artUri;
  final MediaType type;
  final String filePath;
  final DateTime? dateAdded;
  final int playCount;
  final DateTime? lastPlayed;

  const MediaItem({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.duration,
    this.artUri,
    required this.type,
    required this.filePath,
    this.dateAdded,
    this.playCount = 0,
    this.lastPlayed,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        albumArtist,
        duration,
        artUri,
        type,
        filePath,
        dateAdded,
        playCount,
        lastPlayed,
      ];

  MediaItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    int? duration,
    String? artUri,
    MediaType? type,
    String? filePath,
    DateTime? dateAdded,
    int? playCount,
    DateTime? lastPlayed,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      duration: duration ?? this.duration,
      artUri: artUri ?? this.artUri,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      dateAdded: dateAdded ?? this.dateAdded,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }

  MediaItem incrementPlayCount() {
    return copyWith(
      playCount: playCount + 1,
      lastPlayed: DateTime.now(),
    );
  }
}
