import 'package:flutter/material.dart';

import 'PostsDTO.dart';

class NotificationDTO {
  int? id;
  int? type;
  int? userId;
  String? notificationDescr;
  String? questionDescr;

  String? timestamp;
  int? reviewId;
  int? status;
  int? questionType;
  int? isHandshakeInterested;
  int? questionId;
  int? friendId;
  List<int>? expertise;
  String? friendLevel;
  String? friendName;
  String? extra;
  int? suggestedPerson;
  String? notificationAge;
  String? friendPhoto;
  int? parentId;
  List<Option>? options; // Handles the options for type 3

  NotificationDTO({
    this.id,
    this.type,
    this.userId,
    this.notificationDescr,
    this.questionDescr,
    this.timestamp,
    this.reviewId,
    this.status,
    this.questionType,
    this.isHandshakeInterested,
    this.questionId,
    this.friendId,
    this.expertise,
    this.friendLevel,
    this.friendName,
    this.extra,
    this.suggestedPerson,
    this.notificationAge,
    this.friendPhoto,
    this.parentId,
    this.options
  });

  // Factory constructor for JSON deserialization
  NotificationDTO.fromJson(Map<String, dynamic> json) {
    // NotificationDTO(
      id = int.tryParse(json['ID'] ?? '');
      type = int.tryParse(json['type'] ?? '');
      userId = int.tryParse(json['user_id'] ?? '');
      notificationDescr = json['notification'];
      questionDescr = json['question_descr'];
      timestamp = json['timestamp'];
      // reviewId = int.tryParse(json['review_id'] ?? '');
      reviewId = int.tryParse(json['review_id']?.toString() ?? "") ?? 0;
      status = int.tryParse(json['status'] ?? '');
      // questionType = int.tryParse(json['question_type'] ?? '');
      questionType = int.tryParse(json['question_type']?.toString() ?? "") ?? 0;

// Parse isHandshakeInterested safely
    isHandshakeInterested = int.tryParse(json['handshake_interested'] ?? '');

// Parse questionId safely
    questionId = int.tryParse(json['question_id'] ?? '');
// Parse friendId safely
    friendId = int.tryParse(json['friend_id'] ?? '');

// Parse expertise as a list of integers
    expertise = json['expertise'] != null
        ? (json['expertise'] as List<dynamic>)
        .map((e) => int.tryParse(e.toString()) ?? 0)
        .toList()
        : [];

    // Parse friendLevel safely
        friendLevel = json['friend_level'] ?? "";

    // Parse friendName safely
        friendName = json['friend_name'] ?? "";

    // Parse extra safely
        extra = json['extra_values'] ?? "";

    // Parse suggestedPerson safely
        suggestedPerson = json['suggested_person'] != null
            ? int.tryParse(json['suggested_person'].toString())
            : null;

    // Parse notificationAge safely
        notificationAge = json['notification_age'] ?? "";

    // Parse friendPhoto safely
        friendPhoto = json['friend_photo'] ?? "";

    // Parse parentId safely
        parentId = int.tryParse(json['parent_id'] ?? '');

    if (json['options'] != null) {
      options = <Option>[];
      json['options'].forEach((v) {
        options!.add(Option.fromJson(v));
      });
    }

      // reviewId: json['review_id'] as String?,
      // status: json['status'] as String?,
      // questionType: json['question_type'] as int?,
      // isHandshakeInterested: json['handshake_interested'] as int?,
      // questionId: json['question_id'] as int?,
      // friendId: json['friend_id'] as int?,
      // expertise: (json['expertise'] as List<dynamic>?)
      //     ?.map((e) => e as int)
      //     .toList(),
      // friendLevel: json['friend_level'] as String?,
      // friendName: json['friend_name'] as String?,
      // extra: json['extra_values'] as String?,
      // suggestedPerson: json['suggested_person'] as int?,
      // notificationAge: json['notification_age'] as String?,
      // friendPhoto: json['friend_photo'] as String?,
      // parentId: json['parent_id'] as int?,
    // );
  }

  // Method for JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'type': type,
      'user_id': userId,
      'notification': notificationDescr,
      'question_descr': questionDescr,
      'timestamp': timestamp,
      'review_id': reviewId,
      'status': status,
      'question_type': questionType,
      'handshake_interested': isHandshakeInterested,
      'question_id': questionId,
      'friend_id': friendId,
      'expertise': expertise,
      'friend_level': friendLevel,
      'friend_name': friendName,
      'extra': extra,
      'suggested_person': suggestedPerson,
      'notification_age': notificationAge,
      'friend_photo': friendPhoto,
      'parent_id': parentId,
      'options' : (options != null)? options!.map((v) => v.toJson()).toList():[],
    };
  }
}