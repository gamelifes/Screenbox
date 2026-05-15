// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtistModelAdapter extends TypeAdapter<ArtistModel> {
  @override
  final int typeId = 2;

  @override
  ArtistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtistModel()
      ..id = fields[0] as String
      ..name = fields[1] as String?
      ..songCount = fields[2] as int
      ..albumCount = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, ArtistModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.songCount)
      ..writeByte(3)
      ..write(obj.albumCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
