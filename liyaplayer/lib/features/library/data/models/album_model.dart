import 'package:hive/hive.dart';

part 'album_model.g.dart';

@HiveType(typeId: 1)
class AlbumModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  String? artist;

  @HiveField(3)
  int? year;

  @HiveField(4)
  List<int>? artwork;

  @HiveField(5)
  late int songCount;

  @HiveField(6)
  late String firstSongPath;

  @HiveField(7)
  late String artistId;
}
