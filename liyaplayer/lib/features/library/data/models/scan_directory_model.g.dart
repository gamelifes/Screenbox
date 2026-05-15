// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_directory_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanDirectoryModelAdapter extends TypeAdapter<ScanDirectoryModel> {
  @override
  final int typeId = 3;

  @override
  ScanDirectoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanDirectoryModel()
      ..path = fields[0] as String
      ..extensions = (fields[1] as List).cast<String>()
      ..addedAt = fields[2] as DateTime
      ..lastScanAt = fields[3] as DateTime?;
  }

  @override
  void write(BinaryWriter writer, ScanDirectoryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.path)
      ..writeByte(1)
      ..write(obj.extensions)
      ..writeByte(2)
      ..write(obj.addedAt)
      ..writeByte(3)
      ..write(obj.lastScanAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanDirectoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
