import 'dart:convert';

class CommentDTO {
  bool isLoadingReplies; // Track if this comment is loading replies
  int? questionID;
  int? commentID;
  int? ID;
  int? userID;
  int? type;
  int? status;
  String? descr;
  int? parentID;
  String? createdOn;
  String? updatedOn;
  String? commentatorName;
  String? email;
  String? phone;
  String? photo;
  String? title;
  bool? likedByMe;
  int? totalLikes;
  int? totalComments;
  List<CommentDTO>? children;
  bool isExpanded;

  CommentDTO({
    this.questionID,
    this.commentID,
    this.ID,
    this.userID,
    this.type,
    this.status,
    this.descr,
    this.parentID,
    this.createdOn,
    this.updatedOn,
    this.commentatorName,
    this.email,
    this.phone,
    this.photo,
    this.title,
    this.likedByMe,
    this.totalLikes,
    this.totalComments,
    this.children,
    this.isLoadingReplies = false, // Initialize to false by default
    this.isExpanded = false,
  });

  // Factory method to create a CommentDTO from JSON
  factory CommentDTO.fromJson(Map<String, dynamic> json) {
    return CommentDTO(
      questionID: json['question_id'] != null ? int.tryParse(json['question_id'].toString()) : null,
      commentID: json['commentID'] != null ? int.tryParse(json['commentID'].toString()) : null,
      ID: json['ID'] != null ? int.tryParse(json['ID'].toString()) : null,
      userID: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      type: json['type'] != null ? int.tryParse(json['type'].toString()) : null,
      status: json['status'] != null ? int.tryParse(json['status'].toString()) : null,
      descr: json['descr'],
      parentID: json['parent_id'] != null ? int.tryParse(json['parent_id'].toString()) : null,
      createdOn: json['created_on'],
      updatedOn: json['updated_on'],
      commentatorName: json['commentator_name'] ?? 'Unknown',
      email: json['email'],
      phone: json['phone'],
      photo: json['photo'] ?? '',
      title: json['title'],
      likedByMe: json['liked_by_me'] == '1',
      totalLikes: json['total_likes'] != null ? int.tryParse(json['total_likes'].toString()) : null,
      totalComments: json['total_comments'] != null ? int.tryParse(json['total_comments'].toString()) : null,
      children: (json['comments'] as List<dynamic>?)
          ?.map((e) => CommentDTO.fromJson(e as Map<String, dynamic>))
          .toList()??
          [],
      // replies: (json['comments'] as List<dynamic>?)
      //     ?.map((e) => Comment.fromJson(e))
      //     .toList() ??
      //     [],
    );
  }

  CommentDTO copyWith({
    int? questionID,
    int? commentID,
    int? ID,
    int? userID,
    int? type,
    int? status,
    String? descr,
    int? parentID,
    String? createdOn,
    String? updatedOn,
    String? commentatorName,
    String? email,
    String? phone,
    String? photo,
    String? title,
    bool? likedByMe,
    int? totalLikes,
    int? totalComments,
    List<CommentDTO>? children,
    bool? isLoadingReplies,
    bool? isExpanded,
  }) {
    return CommentDTO(
      questionID: questionID ?? this.questionID,
      commentID: commentID ?? this.commentID,
      ID: ID ?? this.ID,
      userID: userID ?? this.userID,
      type: type ?? this.type,
      status: status ?? this.status,
      descr: descr ?? this.descr,
      parentID: parentID ?? this.parentID,
      createdOn: createdOn ?? this.createdOn,
      updatedOn: updatedOn ?? this.updatedOn,
      commentatorName: commentatorName ?? this.commentatorName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      title: title ?? this.title,
      likedByMe: likedByMe ?? this.likedByMe,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
      children: children ?? this.children,
      isLoadingReplies: isLoadingReplies ?? this.isLoadingReplies,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  // Method to convert a CommentDTO to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionID': questionID,
      'commentID': commentID,
      'ID': ID,
      'userID': userID,
      'type': type,
      'status': status,
      'descr': descr,
      'parentID': parentID,
      'createdOn': createdOn,
      'updatedOn': updatedOn,
      'commentatorName': commentatorName,
      'email': email,
      'phone': phone,
      'photo': photo,
      'title': title,
      'likedByMe': likedByMe,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'children': children?.map((child) => child.toJson()).toList(),
    };
  }
}

