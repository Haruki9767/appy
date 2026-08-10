// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PomodoroSessionAdapter extends TypeAdapter<PomodoroSession> {
  @override
  final int typeId = 0;

  @override
  PomodoroSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PomodoroSession(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      type: fields[3] as SessionType,
      completed: fields[4] as bool,
      durationSeconds: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PomodoroSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionTypeAdapter extends TypeAdapter<SessionType> {
  @override
  final int typeId = 1;

  @override
  SessionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionType.focus;
      case 1:
        return SessionType.shortBreak;
      case 2:
        return SessionType.longBreak;
      default:
        return SessionType.focus;
    }
  }

  @override
  void write(BinaryWriter writer, SessionType obj) {
    switch (obj) {
      case SessionType.focus:
        writer.writeByte(0);
        break;
      case SessionType.shortBreak:
        writer.writeByte(1);
        break;
      case SessionType.longBreak:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
