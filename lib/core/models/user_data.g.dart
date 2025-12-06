// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 0;

  @override
  UserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserData(
      id: fields[0] as String,
      email: fields[1] as String,
      username: fields[2] as String?,
      avatarUrl: fields[3] as String?,
      lastLoginAt: fields[4] as DateTime,
      rememberMe: fields[5] as bool,
      points: fields[6] as int,
      unlockedBadges: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.lastLoginAt)
      ..writeByte(5)
      ..write(obj.rememberMe)
      ..writeByte(6)
      ..write(obj.points)
      ..writeByte(7)
      ..write(obj.unlockedBadges);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
