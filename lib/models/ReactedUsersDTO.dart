class ReactedUsersDTO {
  String? photo;
  String? fullName;
  String? phone;
  String? userId;
  String? ratedPoints;
  String? isFriend;

  ReactedUsersDTO(
      {this.photo,
        this.fullName,
        this.phone,
        this.userId,
        this.ratedPoints,
        this.isFriend});

  ReactedUsersDTO.fromJson(Map json) {
    photo = json['photo'];
    fullName = json['full_name'];
    phone = json['phone'];
    userId = json['user_id'];
    ratedPoints = json['rated_points'];
    isFriend = json['is_friend'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['photo'] = this.photo;
    data['full_name'] = this.fullName;
    data['phone'] = this.phone;
    data['user_id'] = this.userId;
    data['rated_points'] = this.ratedPoints;
    data['is_friend'] = this.isFriend;
    return data;
  }
}
