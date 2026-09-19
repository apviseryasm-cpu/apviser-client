import 'dart:convert';

import 'AppConstants.dart';
import 'CommonHelper.dart';
import 'main.dart';
import 'package:flutter/material.dart';

import './models/PostsDTO.dart';
import 'models/CommentsDTO.dart';
import 'pages/create_post.dart';
import 'rest_util.dart';
import 'widgets/CommentTile.dart';
import 'widgets/cards/answer_card.dart';
import 'widgets/cards/custom_poll_card.dart';
import 'widgets/cards/handshake_card.dart';
import 'widgets/cards/normal_poll_card.dart';
import 'widgets/cards/post_card_base.dart';
//import 'models.dart';

class Post extends StatefulWidget {
  final PostDTO post;
  final bool? showMenu;
  final bool? showReportAbuse;
  final VoidCallback onDelete;
  final VoidCallback onEdit; // Add onEdit callback

  Post({required this.post, this.showMenu, required this.onDelete, required this.onEdit, this.showReportAbuse=false});

  @override
  _PostState createState() => _PostState();
}

class _PostState extends State<Post> {
  bool isPostHidden=false;

  @override
  Widget build(BuildContext context) {
    if(widget.post.type == 1){
      return
        Column(
          children: <Widget>[
            if(widget.showMenu!)
            buildMenu(widget.post, context),

            // if(widget.showReportAbuse!)
            //   _reportAbuseButton(),

          NormalCard(widget.post, showReportAbuse: widget.showReportAbuse,)
          ],
        );
    }
    else if(widget.post.type == 2){
      return
        Column(
        children: <Widget>[
          if(widget.showMenu!)
          buildMenu(widget.post, context),
          // if(widget.showReportAbuse!)
          //   _reportAbuseButton(),
          AnswerCard(widget.post, showReportAbuse: widget.showReportAbuse,)
        ],
      );

    } else if(widget.post.type == 3){
      return
        Column(
          children: <Widget>[
            if(widget.showMenu!)
              buildMenu(widget.post, context),
            CustomPollCard(widget.post, showReportAbuse: widget.showReportAbuse,)
          ],
        );

        // SingleChildScrollView(
        //   scrollDirection: Axis.horizontal,
        //   child:
    // Row(
    //         children: [
    //           Flexible(
    //             child: CustomPollCard(widget.post),
    //           ),
    //           if (widget.showMenu!)
    //             Padding(
    //               padding: const EdgeInsets.only(right: 2.0),
    //               child: buildMenu(widget.post, context),
    //             ),
    //
    //           if (widget.showReportAbuse!)
    //             Padding(
    //               padding: const EdgeInsets.only(right: 2.0),
    //               child: _reportAbuseButton(),
    //             ),
    //
    //           // Make the card expand only if there is space
    //
    //         ],
    //       );
        // );


    }else if(widget.post.type == 4){
      return
      Column(
        children: <Widget>[
          if(widget.showMenu!)
            buildMenu(widget.post, context),
          HandshakePollCard(widget.post, showReportAbuse: widget.showReportAbuse,)
        ],
      );

    }
    else {
      return NormalCard(widget.post, showReportAbuse: widget.showReportAbuse,);
    }
  }

  // Widget to build the latest comment section
  Widget _buildLatestCommentSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 0), // Left margin for indentation
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CommentTile(
                comment: CommentDTO(commentatorName: widget.post.commentatorName, title: widget.post.commentatorTitle, descr: widget.post.latestAnswer, photo: widget.post.commentatorPhoto, updatedOn: widget.post.commentDate),
            ),
          ),
        ],
      ),
    );
  }
Widget _reportAbuseButton() {
    return IconButton(
      icon: Icon(Icons.report),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Report Abuse"),
              content: Text("If you believe this content violates safety policies, please email us at privacy@apviser.com."),
              actions: [
                TextButton(
                  child: Text("Close"),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            );
          },
        );
      },
    );

}
  // Widget to build the likes and replies section below the latest comment
  Widget _buildLikesAndRepliesSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0), // Same left margin for consistency
      child: Row(
        children: [
          // Likes count
          Row(
            children: [
              const Icon(Icons.thumb_up, size: 16),
              const SizedBox(width: 5),
              Text(
                "${widget.post.latestAnswerTotalLikes ?? 0} Likes",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 20), // Spacing between likes and replies

          // Replies count
          Row(
            children: [
              const Icon(Icons.comment, size: 16),
              const SizedBox(width: 5),
              Text(
                "${widget.post.latestAnswerTotalComments ?? 0} Replies",
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget buildMenu(PostDTO postDTO, BuildContext context) {
  return PopupMenuButton<String>(
    onSelected: (String value) {
      switch (value) {
        case 'edit':
          CommonHelper.logDebug("edit post ${postDTO.id}");
          _editPost(postDTO.id!, postDTO.userId!, context);
          break;
        case 'delete':
          CommonHelper.logDebug("delete post ${postDTO.id}");
          _deletePost(postDTO, context);
          // onDelete();
          break;
        case 'toggleHide':
          CommonHelper.logDebug("hide post ${postDTO.id}");
          _toggleHidePost(postDTO, context); // Call function to toggle hide/show state
          break;
      }
    },
    itemBuilder: (BuildContext context) {
      // Check if conditions for disabling "edit" are met
      bool disableEdit = false;
      // isPostHidden = widget.post.questionStatus! == 0;
      //print("${postDTO.descr} status $isPostHidden");
      switch (postDTO.type) {
        case 1:
          disableEdit = postDTO.best! > 0 ||
              postDTO.good! > 0 ||
              postDTO.poor! > 0 ||
              postDTO.answerCount! > 0 ||
              postDTO.bumpCount! > 0
          ;
          break;
        case 2:
          disableEdit = postDTO.answerCount! > 0 ||
              postDTO.bumpCount! > 0;
          break;
        case 3:
          disableEdit =
              postDTO.answerCount! > 0 ||
                  postDTO.bumpCount! > 0 ||
                  postDTO.customPollCount! > 0
          ;
          break;
        case 4:
          disableEdit = postDTO.handshakeCount! > 0 ||
              postDTO.suggestedCount! > 0 ||
              postDTO.answerCount! > 0 ||
              postDTO.bumpCount! > 0
          ;
          break;
      }

      // Build menu items conditionally
      return <PopupMenuEntry<String>>[
        if (!disableEdit)
          const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        PopupMenuItem<String>(
          value: 'toggleHide',
          child: Text(isPostHidden ? 'Show' : 'Hide'),
        ),
      ];
    },
  );
}
  void _editPost(int postID, int userId, BuildContext context) {
    widget.onEdit();
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CreatePost(postID: postID, userID: userId, questionType: AppConstants.getPollType(widget.post.type),),
    //   ),
    // );
  }

  // Function to toggle hide/show post using RESTUtil
  Future<void> _toggleHidePost(PostDTO postDTO, BuildContext context) async {
    final Map<String, dynamic> payload = {
      'user_id': postDTO.userId,
      'question_id': postDTO.id,
      // 'post_status': postDTO.questionStatus,
    };

    try {
      // Initialize RESTUtil with required credentials
      final restUtil = RESTUtil(
        baseUrl: AppConstants.TOGGLE_QUESTION,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': jsonEncode(payload)});

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // print(responseData);
        if (responseData['error'] == false) {
          setState(() {
            int? tt = int.tryParse(responseData['question_details'][0]['status']); // Toggle the post hidden state
            isPostHidden = tt == 0; // Toggle the post hidden state
            String hh = "test";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isPostHidden ? 'Post hidden successfully!' : 'Post is now visible.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to hide the post.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reach the server. Please try again.')),
        );
      }
    } catch (e) {
      CommonHelper.logDebug('Error hiding post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

  // Function to delete a post using RESTUtil
  Future<void> _deletePost(PostDTO postDTO, BuildContext context) async {
    final Map<String, dynamic> payload = {
      'user_id': postDTO.userId,
      'question_id': postDTO.id,
    };

    try {
      // Initialize RESTUtil with required credentials
      final restUtil = RESTUtil(
        baseUrl: AppConstants.DELETE_QUESTION,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': jsonEncode(payload)});

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // print(responseData);

        if (responseData['error'] == false) {
          widget.onDelete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Post deleted successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete the post.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reach the server. Please try again.')),
        );
      }
    } catch (e) {
      CommonHelper.logDebug('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
  }

}
