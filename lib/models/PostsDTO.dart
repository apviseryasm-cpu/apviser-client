import 'package:Apviser/models/UserDTO.dart';

import '../CommonHelper.dart';
import 'ReactedUsersDTO.dart';

class PostDTO {
  String? photo;
  int? userId;
  String? descr;
  int? best;
  int? good;
  int? poor;
  String? createdOn;
  int? id;
  String? updatedOn;
  int? type;
  int? answerCount;
  String? latestAnswer;
  int? latestAnswerTotalComments;
  int? latestAnswerTotalLikes;
  int? latestAnswerCommentId;
  int? questionId;
  List<Option>? options; // Handles the options for type 3
  int? handshakeCount;
  int? suggestedCount;
  String? extra;
  int? isSuggestion;
  String? userFullName;
  String? userEmail;
  String? userGender;
  int? publicPrivateFlag;
  String? questionRelatedExpertise;
  String? questionRelatedExpertiseNames;
  List<ExpertiseDetails>? expertiseDetails;
  String? commentatorName;
  String? commentatorTitle;
  String? commentatorPhoto;
  String? commentDate;
  int? commentatorId;
  int? bumpCount;
  int? isBumped;
  String? postImage;
  String? friendLevel;
  int? customPollCount;
  int? questionStatus;
  List<PollCUInfo>? pollCUInfo;

  List<UserDTO>? reactedUsers;

  int? pollCUAnswer;
  int? reviewStatus;
  int? containsImage;
  int? isPostExpired;
  int? postVisibility;
  String? slug;

  PostDTO({
    this.photo,
    this.userId,
    this.descr,
    this.best,
    this.good,
    this.poor,
    this.createdOn,
    this.id,
    this.updatedOn,
    this.type,
    this.answerCount,
    this.latestAnswer,
    this.latestAnswerTotalComments,
    this.latestAnswerTotalLikes,
    this.latestAnswerCommentId,
    this.questionId,
    this.options,
    this.handshakeCount,
    this.suggestedCount,
    this.extra,
    this.isSuggestion,
    this.userFullName,
    this.userEmail,
    this.publicPrivateFlag,
    this.questionRelatedExpertise,
    this.questionRelatedExpertiseNames,
    this.expertiseDetails,
    this.commentatorName,
    this.commentatorTitle,
    this.commentatorPhoto,
    this.commentDate,
    this.commentatorId,
    this.bumpCount,
    this.isBumped,
    this.postImage,
    this.friendLevel,
    this.customPollCount,
    this.questionStatus,
    this.pollCUInfo,
    this.reactedUsers,
    this.pollCUAnswer,
    this.reviewStatus,
    this.userGender,
    this.containsImage,
    this.postVisibility,
    this.isPostExpired,
    this.slug
  });

  PostDTO.fromJson(Map<String, dynamic> json) {
    photo = json['photo'];
    userId = int.tryParse(json['user_id'] ?? '');
    containsImage = int.tryParse(json['contains_image'] ?? '');
    descr = json['descr'];
    best = int.tryParse(json['best'] ?? '');
    good = int.tryParse(json['good'] ?? '');
    poor = int.tryParse(json['poor'] ?? '');
    createdOn = json['created_on'];
    id = int.tryParse(json['ID'] ?? '');
    updatedOn = json['updated_on'];
    type = int.tryParse(json['type'] ?? '');
    answerCount = int.tryParse(json['answer_count'] ?? '');
    latestAnswer = json['latest_answer'] ?? "";
    latestAnswerTotalComments = int.tryParse(json['latest_answer_total_comments'] ?? '');
    latestAnswerTotalLikes = int.tryParse(json['latest_answer_total_likes'] ?? '');
    latestAnswerCommentId = int.tryParse(json['latest_answer_comment_id'] ?? '');
    questionId = int.tryParse(json['question_id'] ?? '');
    if (json['options'] != null) {
      options = <Option>[];
      json['options'].forEach((v) {
        options!.add(Option.fromJson(v));
      });
    }
    handshakeCount = int.tryParse(json['handshake_count'] ?? '');
    suggestedCount = int.tryParse(json['suggested_count'] ?? '');
    extra = json['extra'] ?? "";
    isSuggestion = int.tryParse(json['is_suggestion'] ?? '');
    userFullName = json['user_full_name'];
    userEmail = json['user_email'];
    userGender = json['gender'];
    publicPrivateFlag = int.tryParse(json['public_private_flag'] ?? '');
    questionRelatedExpertise = json['question_related_expertise'];
    questionRelatedExpertiseNames = json['question_related_expertise_names'];
    if (json['expertise_details'] != null) {
      expertiseDetails = <ExpertiseDetails>[];
      json['expertise_details'].forEach((v) {
        expertiseDetails!.add(ExpertiseDetails.fromJson(v));
      });
    }
    if (json['reacted_users_list'] != null && json['reacted_users_list'].isNotEmpty) {
      reactedUsers = []; // Initialize the list only when valid data exists.
      List<dynamic> usersListJSON = json['reacted_users_list'][0];
      for (var friendJSON in usersListJSON) {
        try {
          reactedUsers?.add(UserDTO.fromJson(friendJSON));
        } catch (e) {
          CommonHelper.logDebug("Error parsing reacted_users_list: $e");
        }
      }
    }

    commentatorName = json['commentator_name'] ?? "";
    commentatorTitle = json['commentator_title'] ?? "";
    commentatorPhoto = json['commentator_photo'] ?? "";
    commentDate = json['comment_date'] ?? "";
    commentatorId = int.tryParse(json['commentator_id'] ?? '');
    bumpCount = int.tryParse(json['bump_count'] ?? '');
    isBumped = int.tryParse(json['is_bumped'] ?? '');
    postImage = json['post_image'];
    friendLevel = json['friend_level'] ?? "";
    customPollCount = int.tryParse(json['custom_poll_count'] ?? '');
    questionStatus = int.tryParse(json['question_status'] ?? '');
    postVisibility = int.tryParse(json['post_visibility'] ?? '');
    isPostExpired = int.tryParse(json['post_is_expired'] ?? '');
    slug = json['slug'] ?? "";
    if (json['poll_CU_info'] != null) {
      List<dynamic> pollCUInfo = json['poll_CU_info'];
      if (pollCUInfo.isNotEmpty) {
        for (var userVote in pollCUInfo) {
          try {
            if (userVote['current_user_vote'] != null) {
              pollCUAnswer = int.parse(userVote['current_user_vote'].toString());
            }
            if (userVote['current_user_review_status'] != null) {
              reviewStatus = int.parse(userVote['current_user_review_status'].toString());
            }
          } catch (e) {
            CommonHelper.logDebug("Error parsing poll_CU_info: $e");
          }
        }
      }
    }

  }

  String getExpertiseIds() {
    return this.expertiseDetails
        !.where((expertise) => expertise.expertiseId != null) // Ensure not null
        .map((expertise) => expertise.expertiseId.toString()) // Convert to String
        .join(','); // Join with commas
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['photo'] = photo;
    data['user_id'] = userId;
    data['contains_image'] = containsImage;
    data['descr'] = descr;
    data['best'] = best;
    data['good'] = good;
    data['poor'] = poor;
    data['created_on'] = createdOn;
    data['ID'] = id;
    data['updated_on'] = updatedOn;
    data['type'] = type;
    data['answer_count'] = answerCount;
    data['latest_answer'] = latestAnswer;
    data['latest_answer_total_comments'] = latestAnswerTotalComments;
    data['latest_answer_total_likes'] = latestAnswerTotalLikes;
    data['latest_answer_comment_id'] = latestAnswerCommentId;
    data['question_id'] = questionId;
    if (options != null) {
      data['options'] = options!.map((v) => v.toJson()).toList();
    }
    data['handshake_count'] = handshakeCount;
    data['suggested_count'] = suggestedCount;
    data['extra'] = extra;
    data['is_suggestion'] = isSuggestion;
    data['user_full_name'] = userFullName;
    data['user_email'] = userEmail;
    data['public_private_flag'] = publicPrivateFlag;
    data['question_related_expertise'] = questionRelatedExpertise;
    data['question_related_expertise_names'] = questionRelatedExpertiseNames;
    if (expertiseDetails != null) {
      data['expertise_details'] = expertiseDetails!.map((v) => v.toJson()).toList();
    }
    if (reactedUsers != null) {
      data['reacted_users_list'] = reactedUsers!.map((v) => v.toJson()).toList();
    }
    data['commentator_name'] = commentatorName;
    data['commentator_title'] = commentatorTitle;
    data['commentator_photo'] = commentatorPhoto;
    data['comment_date'] = commentDate;
    data['commentator_id'] = commentatorId;
    data['bump_count'] = bumpCount;
    data['is_bumped'] = isBumped;
    data['post_image'] = postImage;
    data['friend_level'] = friendLevel;
    data['custom_poll_count'] = customPollCount;
    data['question_status'] = questionStatus;
    if (pollCUInfo != null) {
      data['poll_CU_info'] = pollCUInfo!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ExpertiseDetails {
  int? expertiseId;
  String? name;

  ExpertiseDetails({this.expertiseId, this.name});

  ExpertiseDetails.fromJson(Map<String, dynamic> json) {
    expertiseId = int.tryParse(json['expertise_id'] ?? '');
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['expertise_id'] = expertiseId;
    data['name'] = name;
    return data;
  }
}

class PollCUInfo {
  String? currentUserVote;
  String? currentUserReviewStatus;

  PollCUInfo({this.currentUserVote, this.currentUserReviewStatus});

  PollCUInfo.fromJson(Map<String, dynamic> json) {
    currentUserVote = json['current_user_vote'];
    currentUserReviewStatus = json['current_user_review_status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['current_user_vote'] = currentUserVote;
    data['current_user_review_status'] = currentUserReviewStatus;
    return data;
  }
}

class Option {
  int? optionId;
  String? option;
  int? count;

  Option({this.optionId, this.option, this.count});

  Option.fromJson(Map<String, dynamic> json) {
    optionId = int.tryParse(json['option_id'] ?? '');
    option = json['option'];
    count = int.tryParse(json['count'] ?? '0'); // Handle count as an integer
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['option_id'] = optionId;
    data['option'] = option;
    data['count'] = count;
    return data;
  }
}
