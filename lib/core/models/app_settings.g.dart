// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      biometricEnabled: fields[0] as bool,
      notificationsEnabled: fields[1] as bool,
      darkModeEnabled: fields[2] as bool,
      dailyScreenTimeLimit: fields[3] as int,
      strictModeEnabled: fields[4] as bool,
      allowOverride: fields[5] as bool,
      lastSyncAt: fields[6] as String?,
      offlineModeEnabled: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.biometricEnabled)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.darkModeEnabled)
      ..writeByte(3)
      ..write(obj.dailyScreenTimeLimit)
      ..writeByte(4)
      ..write(obj.strictModeEnabled)
      ..writeByte(5)
      ..write(obj.allowOverride)
      ..writeByte(6)
      ..write(obj.lastSyncAt)
      ..writeByte(7)
      ..write(obj.offlineModeEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
