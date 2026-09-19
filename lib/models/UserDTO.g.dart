// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'UserDTO.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserDTOAdapter extends TypeAdapter<UserDTO> {
  @override
  final int typeId = 0;

  @override
  UserDTO read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserDTO(
      fullName: fields[0] as String,
      phoneNumber: fields[1] as String,
      facebookLink: fields[2] as String,
      twitterLink: fields[3] as String,
      youtubeLink: fields[4] as String,
      whatsappLink: fields[5] as String,
      city: fields[6] as String,
      country: fields[7] as String,
      state: fields[8] as String,
      coordinates: fields[9] as String,
      postalCode: fields[10] as String,
      userID: fields[11] as int,
      email: fields[12] as String,
      photo: fields[13] as String,
      title: fields[14] as String,
      createdAt: fields[15] as String,
      handShakeAvailable: fields[16] as String,
      locationLatLong: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserDTO obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.facebookLink)
      ..writeByte(3)
      ..write(obj.twitterLink)
      ..writeByte(4)
      ..write(obj.youtubeLink)
      ..writeByte(5)
      ..write(obj.whatsappLink)
      ..writeByte(6)
      ..write(obj.city)
      ..writeByte(7)
      ..write(obj.country)
      ..writeByte(8)
      ..write(obj.state)
      ..writeByte(9)
      ..write(obj.coordinates)
      ..writeByte(10)
      ..write(obj.postalCode)
      ..writeByte(11)
      ..write(obj.userID)
      ..writeByte(12)
      ..write(obj.email)
      ..writeByte(13)
      ..write(obj.photo)
      ..writeByte(14)
      ..write(obj.title)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.handShakeAvailable)
      ..writeByte(17)
      ..write(obj.locationLatLong);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserDTOAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
