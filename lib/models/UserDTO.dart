import 'package:hive/hive.dart';
part 'UserDTO.g.dart';  // This is required for Hive to generate the adapter

@HiveType(typeId: 0)  // Specify a unique typeId for this class
class UserDTO {
  @HiveField(0)
  String fullName;

  @HiveField(1)
  String phoneNumber;

  @HiveField(2)
  String facebookLink;

  @HiveField(3)
  String twitterLink;

  @HiveField(4)
  String youtubeLink;

  @HiveField(5)
  String whatsappLink;

  @HiveField(6)
  String city;

  @HiveField(7)
  String country;

  @HiveField(8)
  String state;

  @HiveField(9)
  String coordinates;

  @HiveField(10)
  String postalCode;

  @HiveField(11)
  int userID;

  @HiveField(12)
  String email;

  @HiveField(13)
  String photo;

  @HiveField(14)
  String title;

  @HiveField(15)
  String createdAt;

  @HiveField(16)
  String handShakeAvailable;

  @HiveField(17)
  String locationLatLong;

  @HiveField(18)
  String deviceToken;

  @HiveField(19)
  String gender;

  @HiveField(20)
  int userType;

  @HiveField(21)
  String about;

  @HiveField(22)
  String requestStatusDescr;

  @HiveField(23)
  int ratedPoints;  // Added from ReactedUsersDTO

  @HiveField(24)
  int isFriend;  // Added from ReactedUsersDTO

  @HiveField(25)
  String selectedOptionName;

  @HiveField(26) // Field for user expertise as a string
  String userExpertise;

  @HiveField(27) // Field for suggested friend status
  int suggestedFriendStatus;

  @HiveField(28) // Field for user expertise as a list of integers
  List<int> userExpertiseList;

  @HiveField(29)
  int handshakeInterested;  // Added from ReactedUsersDTO

  @HiveField(30)
  String updatedOn;

  UserDTO({
    this.fullName = "",
    this.phoneNumber = "",
    this.facebookLink = "",
    this.twitterLink = "",
    this.youtubeLink = "",
    this.whatsappLink = "",
    this.city = "",
    this.country = "",
    this.state = "",
    this.coordinates = "",
    this.postalCode = "",
    this.userID = 0,
    this.email = "",
    this.photo = "",
    this.title = "",
    this.createdAt = "",
    this.handShakeAvailable = "",
    this.locationLatLong = "",
    this.deviceToken="",
    this.gender="",
    this.about="",
    this.userType=0,
    this.requestStatusDescr="",
    this.ratedPoints = 0,
    this.isFriend = 0,
    this.selectedOptionName = "",
    this.userExpertise = "",
    this.suggestedFriendStatus = 0,
    this.userExpertiseList = const [],
    this.handshakeInterested = 0,
    this.updatedOn = "",
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    // Parse user expertise as both string and list
    String expertiseString = json['user_expertise'] ?? "";
    List<int> expertiseList = expertiseString
        .split(',')
        .where((e) => e.isNotEmpty) // Avoid empty elements
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e > 0) // Filter out invalid integers
        .toList();

    return UserDTO(
      fullName: json['fullName'] ?? json['full_name'] ?? json['name'] ?? "", // Handle both cases,
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? "", // Handle both cases,
      about: json['about'] ?? "",
      facebookLink: json['facebookLink'] ?? "",
      twitterLink: json['twitterLink'] ?? "",
      youtubeLink: json['youtubeLink'] ?? "",
      whatsappLink: json['whatsappLink'] ?? "",
      city: json['city'] ?? "",
      country: json['country'] ?? "",
      state: json['state'] ?? "",
      coordinates: json['coordinates'] ?? "",
      postalCode: json['postalCode'] ?? "",
      userID: json['userID'] ??
          int.tryParse(json['ID']?.toString() ?? "") ??
          int.tryParse(json['user_id']?.toString() ?? "") ??
          int.tryParse(json['id']?.toString() ?? "") ??
          0,
      email: json['email'] ?? "",
      photo: json['photo'] ?? "",
      title: json['title'] ?? "",
      createdAt: json['createdAt'] ?? "",
      handShakeAvailable: json['handShakeAvailable'] ?? "",
      locationLatLong: json['locationLatLong'] ?? "",
      deviceToken: json['device_token'] ?? "",
      gender: json['gender'] ?? "",
      userType: int.tryParse(json['user_type']?.toString() ?? "") ?? 0,
      requestStatusDescr: json['status_descr'] ?? "",
      ratedPoints: int.tryParse(json['rated_points']?.toString() ?? "") ?? 0,
      isFriend: int.tryParse(json['is_friend']?.toString() ?? "") ?? 0,
      selectedOptionName: json['selected_option_name'] ?? "",
      userExpertise: expertiseString,
      suggestedFriendStatus: int.tryParse(json['suggested_friend_status']?.toString() ?? "0") ?? 0,
      userExpertiseList: expertiseList,
      handshakeInterested: int.tryParse(json['handshake_interested']?.toString() ?? "") ?? 0,
      updatedOn: json['updated_on'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'facebookLink': facebookLink,
      'twitterLink': twitterLink,
      'youtubeLink': youtubeLink,
      'whatsappLink': whatsappLink,
      'city': city,
      'country': country,
      'state': state,
      'coordinates': coordinates,
      'postalCode': postalCode,
      'userID': userID,
      'email': email,
      'photo': photo,
      'title': title,
      'createdAt': createdAt,
      'handShakeAvailable': handShakeAvailable,
      'locationLatLong': locationLatLong,
      'deviceToken': deviceToken,
      'gender': gender,
      'userType': userType,
      'about': about,
      'is_friend': isFriend,
      'selected_option_name': selectedOptionName,
      'user_expertise': userExpertiseList.join(','), // Convert list back to string
      'suggested_friend_status': suggestedFriendStatus,

      'handshake_interested': handshakeInterested,
      'updated_on': updatedOn,
    };
  }
}
