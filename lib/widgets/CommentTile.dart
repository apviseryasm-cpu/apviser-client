import 'package:flutter/material.dart';

import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../models/CommentsDTO.dart';
import '../models/PostsDTO.dart';

class CommentTile extends StatelessWidget {
  final CommentDTO comment;
  final Function(CommentDTO)? onLikePressed;        // Optional
  final Function(CommentDTO)? onReplyPressed;       // Optional
  final Function(CommentDTO)? onShowRepliesPressed; // Optional

  CommentTile({
    required this.comment,
    this.onLikePressed,       // Optional parameters
    this.onReplyPressed,      // Optional parameters
    this.onShowRepliesPressed // Optional parameters
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          "${AppConstants.APVISER_IMAGES_PATH_FULL}${comment.photo}",
        ),
      ),
      title: Text(comment.commentatorName ?? "Anonymous"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.descr ?? ""),
          SizedBox(width: 4.0),
          Text(
            CommonHelper.getPostAge(PostDTO(updatedOn: comment.updatedOn)),
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.thumb_up,
                  color: comment.likedByMe == true ? Colors.blue : Colors.grey,
                ),
                onPressed: onLikePressed != null ? () => onLikePressed!(comment) : null, // Trigger if provided
              ),
              Text(
                "${comment.totalLikes ?? 0} Likes",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(width: 16.0),
              IconButton(
                icon: Icon(Icons.reply, size: 16, color: Colors.grey),
                onPressed: onReplyPressed != null ? () => onReplyPressed!(comment) : null, // Trigger if provided
              ),
              TextButton(
                onPressed: onShowRepliesPressed != null ? () => onShowRepliesPressed!(comment) : null, // Trigger if provided
                child: Text(
                  "${comment.totalComments ?? 0} Replies",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
