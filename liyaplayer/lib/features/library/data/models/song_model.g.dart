// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongModel()
      ..id = fields[0] as String
      ..filePath = fields[1] as String
      ..title = fields[2] as String?
      ..artist = fields[3] as String?
      ..album = fields[4] as String?
      ..genre = fields[5] as String?
      ..durationMs = fields[6] as int
      ..trackNumber = fields[7] as int?
      ..year = fields[8] as int?
      ..addedAt = fields[9] as DateTime
      ..modifiedAt = fields[10] as DateTime
      ..artwork = (fields[11] as List?)?.cast<int>()
      ..artistId = fields[12] as String
      ..albumId = fields[13] as String;
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.artist)
      ..writeByte(4)
      ..write(obj.album)
      ..writeByte(5)
      ..write(obj.genre)
      ..writeByte(6)
      ..write(obj.durationMs)
      ..writeByte(7)
      ..write(obj.trackNumber)
      ..writeByte(8)
      ..write(obj.year)
      ..writeByte(9)
      ..write(obj.addedAt)
      ..writeByte(10)
      ..write(obj.modifiedAt)
      ..writeByte(11)
      ..write(obj.artwork)
      ..writeByte(12)
      ..write(obj.artistId)
      ..writeByte(13)
      ..write(obj.albumId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
