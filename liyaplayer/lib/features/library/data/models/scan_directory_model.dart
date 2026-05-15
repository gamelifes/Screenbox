import 'package:hive/hive.dart';

part 'scan_directory_model.g.dart';

@HiveType(typeId: 3)
class ScanDirectoryModel extends HiveObject {
  @HiveField(0)
  late String path;

  @HiveField(1)
  late List<String> extensions;

  @HiveField(2)
  late DateTime addedAt;

  @HiveField(3)
  DateTime? lastScanAt;
}
