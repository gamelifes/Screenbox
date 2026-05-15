import 'package:hive/hive.dart';

part 'artist_model.g.dart';

@HiveType(typeId: 2)
class ArtistModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String? name;

  @HiveField(2)
  late int songCount;

  @HiveField(3)
  late int albumCount;
}
