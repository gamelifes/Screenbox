import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String filePath;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? artist;

  @HiveField(4)
  String? album;

  @HiveField(5)
  String? genre;

  @HiveField(6)
  late int durationMs;

  @HiveField(7)
  int? trackNumber;

  @HiveField(8)
  int? year;

  @HiveField(9)
  late DateTime addedAt;

  @HiveField(10)
  late DateTime modifiedAt;

  @HiveField(11)
  List<int>? artwork;

  @HiveField(12)
  late String artistId;

  @HiveField(13)
  late String albumId;
}
