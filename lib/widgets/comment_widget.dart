// import 'package:flutter/material.dart';
// // Assuming Hive is used for local storage
// import 'dart:convert';
//
// import '../AppConstants.dart';
// import '../DatabaseHelper.dart';
// import '../models/CommentsDTO.dart';
// import '../models/UserDTO.dart';
// import '../rest_util.dart';
//
// // Comment Widget with Load Replies
// class CommentWidget extends StatefulWidget {
//   List<CommentDTO> commentsArr=[];
//   final CommentDTO comment;
//   final Function(CommentDTO) onToggleReplies;
//   final Function(CommentDTO, String)? onSendReply;
//   final int level;
//   final bool isLastChild;
//
//   CommentWidget({
//     required this.commentsArr,
//     required this.comment,
//     required this.onToggleReplies,
//     this.onSendReply,
//     this.level = 0,
//     this.isLastChild = false,
//   });
//
//   @override
//   _CommentWidgetState createState() => _CommentWidgetState();
// }
//
// class _CommentWidgetState extends State<CommentWidget> {
//   TextEditingController _replyController = TextEditingController();
//   bool _isReplying = false;
//   bool _isSubmitting = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Tree Line for Nested Replies
//             if (widget.level > 0)
//               SizedBox(
//                 width: 30,
//                 child: CustomPaint(
//                   size: Size(30, 50),
//                   painter: TreeLinePainter(isLastChild: widget.isLastChild),
//                 ),
//               ),
//
//             Expanded(
//               child: ListTile(
//                 leading: CircleAvatar(
//                   backgroundImage: widget.comment.photo!.isNotEmpty
//                       ? NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${widget.comment.photo}")
//                       : AssetImage('assets/images/default_avatar.png') as ImageProvider,
//                 ),
//                 title: Text(widget.comment.commentatorName!, style: TextStyle(fontWeight: FontWeight.bold)),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(widget.comment.descr!),
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: Icon(
//                             widget.comment.likedByMe! ? Icons.thumb_up : Icons.thumb_up_off_alt,
//                             color: widget.comment.likedByMe! ? Colors.blue : Colors.grey,
//                           ),
//                           onPressed: () {}, // Implement Like Logic
//                         ),
//                         Text("${widget.comment.totalLikes}"),
//                         TextButton(
//                           onPressed: () => widget.onToggleReplies(widget.comment),
//                           child: widget.comment.isExpanded
//                               ? Text('Hide Replies')
//                               : Text(widget.comment.totalComments! > 0 ? 'View Replies (${widget.comment.totalComments})' : 'View Replies'),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             setState(() {
//                               _isReplying = !_isReplying; // Toggle reply field visibility
//                             });
//                           },
//                           child: Text('Reply'),
//                         ),
//                       ],
//                     ),
//                     if (_isReplying) _buildReplyInput(),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//
//         // Replies Section
//         if (widget.comment.isExpanded)
//           if (widget.comment.isLoadingReplies)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: CircularProgressIndicator(),
//             )
//           else
//             Padding(
//               padding: const EdgeInsets.only(left: 20.0),
//               child: Column(
//                 children: widget.comment.children!.asMap().entries.map((entry) {
//                   int index = entry.key;
//                   CommentDTO reply = entry.value;
//                   return CommentWidget(
//                     commentsArr: [],
//                     comment: reply,
//                     onToggleReplies: widget.onToggleReplies,
//                     onSendReply: widget.onSendReply,
//                     level: widget.level + 1,
//                     isLastChild: index == widget.comment.children!.length - 1,
//                   );
//                 }).toList(),
//               ),
//             ),
//       ],
//     );
//   }
//
//   // Reply Input Field
//   Widget _buildReplyInput() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 40.0, top: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _replyController,
//               decoration: InputDecoration(
//                 hintText: 'Write a reply...',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: _isSubmitting ? CircularProgressIndicator() : Icon(Icons.send, color: Colors.blue),
//             onPressed: _isSubmitting ? null : () => _submitReply(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Submit Reply to API
//   Future<void> _submitReply() async {
//     String replyText = _replyController.text.trim();
//     if (replyText.isEmpty) return;
//
//     setState(() => _isSubmitting = true);
//
//     final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
//     UserDTO? user = await _dbHelper.getCurrentUser("cuser");
//
//     if (user != null) {
//       final Map<String, dynamic> payload = {
//         'user_id': user.userID,
//         'question_id': widget.comment.questionID ?? 0,
//         'descr': replyText,
//         'expression_type': 2, // Hardcoded
//         'comment_action': 'add', // Hardcoded
//         'parent_id': widget.comment.ID, // Parent Comment ID
//       };
//
//       final restUtil = RESTUtil(
//         baseUrl: AppConstants.LIKES_AND_COMMENTS,
//         username: AppConstants.CREDENTIALS_USERNAME,
//         password: AppConstants.CREDENTIALS_PASSWORD,
//       );
//
//       final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//
//         if (responseData["error"] == false) {
//           // ✅ Extract new comment from response
//           CommentDTO newComment = CommentDTO.fromJson(responseData["result"][0]);
//
//           setState(() {
//             _isReplying = false;
//             _replyController.clear();
//             if (widget.comment.ID == 0) {
//               widget.commentsArr.insert(0, newComment); // Append at the top if it's a parent comment
//             } else {
//               _addReplies(widget.comment.ID!, [newComment]); // Add as a child reply
//             }
//           });
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Reply posted successfully!')),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to post reply. Try again!')),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error posting reply.')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('User not found. Please login again.')),
//       );
//     }
//
//     setState(() => _isSubmitting = false);
//   }
//
//   // Add Replies to the Correct Parent
//   void _addReplies(int parentId, List<CommentDTO> newReplies) {
//     bool addReply(List<CommentDTO> commentsList) {
//       for (var comment in commentsList) {
//         if (comment.ID == parentId) {
//           Set<int?> existingIds = comment.children!.map((c) => c.ID).toSet();
//           List<CommentDTO> uniqueReplies = newReplies.where((c) => !existingIds.contains(c.ID)).toList();
//
//           if (uniqueReplies.isNotEmpty) {
//             comment.children!.addAll(uniqueReplies);
//             comment.isExpanded = true;
//           }
//           return true;
//         }
//
//         if (comment.children!.isNotEmpty) {
//           bool found = addReply(comment.children!);
//           if (found) return true;
//         }
//       }
//       return false;
//     }
//
//     setState(() {
//       addReply(widget.commentsArr);
//     });
//   }
//
//   // Add Comment Field at the Bottom
//   Widget _buildCommentInputField() {
//     TextEditingController _commentController = TextEditingController();
//     bool _isSubmitting = false;
//
//     return Padding(
//       padding: EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _commentController,
//               decoration: InputDecoration(
//                 hintText: "Write a comment...",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           IconButton(
//             icon: _isSubmitting ? CircularProgressIndicator() : Icon(Icons.send, color: Colors.blue),
//             onPressed: _isSubmitting ? null : () async {
//               String commentText = _commentController.text.trim();
//               if (commentText.isEmpty) return;
//
//               setState(() => _isSubmitting = true);
//               await _submitReply(); // Root-level comment
//               _commentController.clear(); // Clear field
//               setState(() => _isSubmitting = false);
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
// }
//
// class TreeLinePainter extends CustomPainter {
//   final bool isLastChild;
//
//   TreeLinePainter({required this.isLastChild});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.grey
//       ..strokeWidth = 1.5;
//
//     // Draw vertical line (if it's not the last child)
//     if (!isLastChild) {
//       canvas.drawLine(Offset(size.width / 2, 0),
//           Offset(size.width / 2, size.height), paint);
//     }
//
//     // Draw horizontal line (for indentation)
//     canvas.drawLine(Offset(size.width / 2, size.height / 2),
//         Offset(size.width, size.height / 2), paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }