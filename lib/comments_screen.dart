import 'dart:convert';
import 'package:flutter/material.dart';
import 'AppConstants.dart';
import 'CommonHelper.dart';
import 'DatabaseHelper.dart';
import 'models/CommentsDTO.dart';
import 'models/UserDTO.dart';
import 'rest_util.dart';
import 'widgets/ProfileAvatar.dart';
import 'widgets/app_bar.dart';

class CommentsScreen extends StatefulWidget {
  final int questionId;
  final bool isEmbedded; // Add this parameter

  CommentsScreen({required this.questionId, this.isEmbedded = false});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  bool _isLoading = true;
  List<CommentDTO> _comments = [];
  UserDTO? _currentUser;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final HiveDatabaseHelper dbHelper = HiveDatabaseHelper.instance;
    _currentUser = await dbHelper.getCurrentUser("cuser");
    await _fetchComments(parentId: 0);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchComments({required int parentId}) async {
    if (_currentUser?.userID == null) {
      _showSnackBar('User not found. Please login again.');
      return;
    }

    final Map<String, dynamic> payload = {
      'question_id': widget.questionId,
      'parent_id': parentId,
      'user_id': _currentUser?.userID,
      'question_comments_limit': 20,
      'comment_comments_limit': 20,
    };

    final restUtil = RESTUtil(
      baseUrl: AppConstants.GET_COMMENTS,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    try {
      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _processCommentsResponse(data, parentId);
      } else {
        CommonHelper.logDebug("Failed to load comments");
      }
    } catch (e) {
      CommonHelper.logDebug("Error fetching comments: $e");
    }
  }

  void _processCommentsResponse(Map<String, dynamic> data, int parentId) {
    List<CommentDTO> fetchedComments = [];
    if (data['comments'] != null && data['comments'].isNotEmpty) {
      if (parentId == 0) {
        fetchedComments = (data['comments'] as List)
            .map((e) => CommentDTO.fromJson(e))
            .toList();
      } else {
        var parentComment = data['comments'][0];
        if (parentComment['comments'] != null) {
          fetchedComments = (parentComment['comments'] as List)
              .map((e) => CommentDTO.fromJson(e))
              .toList();
        }
      }
    }

    setState(() {
      if (parentId == 0) {
        _comments = fetchedComments;
      } else {
        _addReplies(parentId, fetchedComments);
      }
      _stopLoadingReplies(parentId);
    });
  }

  void _stopLoadingReplies(int parentId) {
    for (var comment in _comments) {
      if (comment.ID == parentId) {
        comment.isLoadingReplies = false;
        break;
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addReplies(int parentId, List<CommentDTO> newReplies) {
    bool addReply(List<CommentDTO> commentsList) {
      for (var comment in commentsList) {
        if (comment.ID == parentId) {
          final existingIds = comment.children!.map((c) => c.ID).toSet();
          final uniqueReplies =
          newReplies.where((c) => !existingIds.contains(c.ID)).toList();
          if (uniqueReplies.isNotEmpty) {
            comment.children!.addAll(uniqueReplies);
            comment.isExpanded = true;
          }
          return true;
        }
        if (comment.children!.isNotEmpty) {
          final found = addReply(comment.children!);
          if (found) return true;
        }
      }
      return false;
    }

    setState(() => addReply(_comments));
  }

  void _toggleReplies(CommentDTO comment) {
    setState(() => comment.isExpanded = !comment.isExpanded);
    if (comment.isExpanded && comment.children!.isEmpty) {
      setState(() => comment.isLoadingReplies = true);
      _fetchComments(parentId: comment.ID!)
          .then((_) => setState(() => comment.isLoadingReplies = false));
    }
  }

  void _handleDeleteComment(int commentId) {
    setState(() => _removeComment(_comments, commentId));
  }

  bool _removeComment(List<CommentDTO> commentList, int commentId) {
    for (int i = 0; i < commentList.length; i++) {
      if (commentList[i].ID == commentId) {
        commentList.removeAt(i);
        return true;
      } else if (commentList[i].children != null) {
        if (_removeComment(commentList[i].children!, commentId)) return true;
      }
    }
    return false;
  }

  Future<void> _submitComment(int parentId,
      {CommentDTO? editingComment}) async {
    String replyText =
    _commentController.text.trim(); // Capture text before clearing
    if (replyText.isEmpty) {
      if (editingComment != null) {
        replyText = editingComment.descr!;
      } else {
        return;
      }
    }

    setState(() => _isSubmittingComment = true);

    final payload = {
      'user_id': _currentUser!.userID,
      'question_id': widget.questionId,
      'descr': replyText,
      'expression_type': 2,
      'comment_action': editingComment == null ? 'add' : 'update',
      'parent_id': parentId,
      if (editingComment != null) 'comment_id': editingComment.ID,
    };

    final restUtil = RESTUtil(
      baseUrl: AppConstants.LIKES_AND_COMMENTS,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    try {
      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData["error"] == false) {
        final newComment = CommentDTO.fromJson(responseData["result"][0]);
        setState(() {
          if (editingComment == null) {
            _commentController.clear(); // Clear only for add operations
            if (parentId == 0) {
              _comments.insert(0, newComment);
            } else {
              _addReplies(parentId, [newComment]);
            }
          } else {
            _updateCommentInList(_comments, newComment);
          }
        });
        _showSnackBar(editingComment == null
            ? 'Comment posted successfully!'
            : 'Comment updated successfully!');
      } else {
        _showSnackBar(
            'Failed to ${editingComment == null ? 'post' : 'update'} comment. Try again!');
      }
    } catch (e) {
      _showSnackBar(
          'Error ${editingComment == null ? 'posting' : 'updating'} comment.');
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  void _updateCommentInList(
      List<CommentDTO> commentList, CommentDTO updatedComment) {
    for (int i = 0; i < commentList.length; i++) {
      if (commentList[i].ID == updatedComment.ID) {
        commentList[i] = updatedComment;
        return;
      } else if (commentList[i].children != null) {
        _updateCommentInList(commentList[i].children!, updatedComment);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    CommonHelper.logDebug("CommentsScreen isEmbedded: ${widget.isEmbedded}");

    if (widget.isEmbedded) {
      return
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppConstants.APP_MAX_WIDTH, // Set predefined width
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min, // Important!
                  children: [
                    Flexible(
                      // Important!
                      fit: FlexFit.loose, // Important!
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) => CommentWidget(
                          comment: _comments[index],
                          onToggleReplies: _toggleReplies,
                          onDeleteComment: _handleDeleteComment,
                          cuserID: _currentUser!.userID,
                          onEditComment: (comment) => _editComment(comment),
                        ),
                      ),
                    ),
                    _buildCommentInputField(),
                  ],
                )
              ],
            ),
          ),
        )
      ;
    } else {
      // Modal/Drawer Mode: Return the Scaffold
      return Scaffold(
        // appBar: AppBar(title: Text('Comments')),
        appBar:
        CustomAppBar(title: "Comments", showBackButton: true),
        body:

        SafeArea(
          child: Column(
            children: [
              // Comments List or Empty State
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'No comments yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
                    : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(), // Better than null
                  itemCount: _comments.length,
                  itemBuilder: (context, index) => CommentWidget(
                    comment: _comments[index],
                    onToggleReplies: _toggleReplies,
                    onDeleteComment: _handleDeleteComment,
                    cuserID: _currentUser!.userID,
                    onEditComment: _editComment,
                  ),
                ),
              ),

              // Comment Input Field
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppConstants.APP_MAX_WIDTH,
                ),
                child: _buildCommentInputField(),
              ),
            ],
          ),
        )


      );
    }
  }

  Widget _buildCommentInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child:
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: "Write a comment...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _isSubmittingComment ? null : _submitComment(0),
            ),
          ),
          IconButton(
            icon: _isSubmittingComment
                ? const CircularProgressIndicator()
                : const Icon(Icons.send, color: Colors.blue),
            onPressed: _isSubmittingComment ? null : () => _submitComment(0),
          ),
        ],
      ),
      // Row(
      //   children: [
      //     Expanded(
      //       child: TextField(
      //         controller: _commentController,
      //         decoration: const InputDecoration(
      //             hintText: "Write a comment...", border: OutlineInputBorder()),
      //         onSubmitted: (_) =>
      //         _isSubmittingComment ? null : _submitComment(0),
      //       ),
      //     ),
      //     IconButton(
      //       icon: _isSubmittingComment
      //           ? const CircularProgressIndicator()
      //           : const Icon(Icons.send, color: Colors.blue),
      //       onPressed: _isSubmittingComment ? null : () => _submitComment(0),
      //     ),
      //   ],
      // ),
    );
  }

  void _editComment(CommentDTO comment) {
    setState(() {
      _commentController.text = comment.descr!;
    });
    _showEditInput(comment);
  }

  void _showEditInput(CommentDTO comment) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: _commentController,
                  decoration:
                  const InputDecoration(hintText: 'Edit comment...')),
              ElevatedButton(
                  onPressed: () {
                    _submitComment(comment.ID!, editingComment: comment);
                    Navigator.pop(context);
                  },
                  child: const Text('Update')),
            ]),
          );
        });
  }
}

class CommentWidget extends StatefulWidget {
  final CommentDTO comment;
  final Function(CommentDTO) onToggleReplies;
  final Function(int commentId)? onDeleteComment;
  final Function(CommentDTO) onEditComment; // Add edit function
  final int level;
  final int cuserID;
  final bool isLastChild;

  const CommentWidget({
    required this.comment,
    required this.onToggleReplies,
    required this.onDeleteComment,
    required this.cuserID,
    required this.onEditComment, // Add edit function
    this.level = 0,
    this.isLastChild = false,
  });

  @override
  _CommentWidgetState createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;
  bool _isSubmittingReply = false;

  final TextEditingController _editController = TextEditingController();
  bool _isEditing = false; // Track if the comment is being edited

  @override
  void initState() {
    super.initState();
    _editController.text =
    widget.comment.descr!; // Initialize with existing text
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.level > 0)
                  SizedBox(
                    width: 30,
                    child: CustomPaint(
                      size: const Size(30, 50),
                      painter: TreeLinePainter(isLastChild: widget.isLastChild),
                    ),
                  ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 48.0,
                          height: 48.0,
                          child: ProfileAvatar(
                            user: UserDTO(
                                userID: widget.comment.userID!,
                                photo: widget.comment.photo!
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.comment.commentatorName!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // EDIT: Added the edit functionality here
                                    if (_isEditing)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _editController,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              _updateComment(context);
                                            },
                                            icon: const Icon(Icons.refresh, color: Colors.blue),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = false;
                                              });
                                            },
                                            icon: const Icon(Icons.cancel, color: Colors.blue),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        widget.comment.descr!,
                                        style: const TextStyle(color: Colors.black87),
                                      ),
                                  ],
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          widget.comment.likedByMe!
                                              ? Icons.thumb_up
                                              : Icons.thumb_up_off_alt,
                                          color: widget.comment.likedByMe!
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                        onPressed: _toggleLike,
                                      ),
                                      Text("${widget.comment.totalLikes}"),
                                    ],
                                  ),
                                  if (widget.cuserID == widget.comment.userID)
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            setState(() {
                                              _isEditing = true;
                                              _editController.text = widget.comment.descr!;
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteConfirmation(
                                              context, widget.comment),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (widget.comment.totalComments! > 0)
                                    TextButton(
                                      onPressed: () =>
                                          widget.onToggleReplies(widget.comment),
                                      child: Text(widget.comment.isExpanded
                                          ? 'Hide Replies'
                                          : 'View Replies (${widget.comment.totalComments})'),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isReplying = !_isReplying),
                                      child: const Text('Reply'),
                                    ),
                                  if (widget.comment.totalComments! > 0)
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _isReplying = !_isReplying),
                                      child: const Text('Reply'),
                                    ),
                                ],
                              ),
                              if (_isReplying) _buildReplyInput(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.comment.isExpanded)
              if (widget.comment.isLoadingReplies)
                const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator())
              else
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: widget.comment.children!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reply = entry.value;
                      return CommentWidget(
                        comment: reply,
                        onToggleReplies: widget.onToggleReplies,
                        onDeleteComment: widget.onDeleteComment,
                        cuserID: widget.cuserID,
                        onEditComment: widget.onEditComment,
                        level: widget.level + 1,
                        isLastChild: index == widget.comment.children!.length - 1,
                      );
                    }).toList(),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike() async {
    final payload = {
      'user_id': widget.cuserID,
      'question_id': widget.comment.questionID,
      'descr': '',
      'expression_type': 1,
      'parent_id': widget.comment.ID,
    };

    final restUtil = RESTUtil(
      baseUrl: AppConstants.LIKES_AND_COMMENTS,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    try {
      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData["error"] == false) {
        setState(() {
          widget.comment.likedByMe = !widget.comment.likedByMe!;
          widget.comment.totalLikes = widget.comment.likedByMe!
              ? (widget.comment.totalLikes ?? 0) + 1
              : (widget.comment.totalLikes ?? 1) - 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to toggle like. Try again!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error toggling like.')));
    }
  }

  void _updateComment(BuildContext context) {
    final parentState =
    context.findAncestorStateOfType<_CommentsScreenState>()!;
    parentState._submitComment(widget.comment.ID!,
        editingComment: widget.comment.copyWith(descr: _editController.text));
    setState(() {
      _isEditing = false; // Stop editing after update
    });
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, top: 8.0),
      child:
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                  hintText: 'Write a reply...', border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12)
              ),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _isSubmittingReply ? null : _submitReply(),
            ),
          ),
          IconButton(
            icon: _isSubmittingReply
                ? const CircularProgressIndicator()
                : const Icon(Icons.send, color: Colors.blue),
            onPressed: _isSubmittingReply ? null : _submitReply,
          ),
        ],
      ),
      // Row(
      //   children: [
      //     Expanded(
      //       child: TextField(
      //         controller: _replyController,
      //         decoration: const InputDecoration(
      //             hintText: 'Write a reply...', border: OutlineInputBorder()),
      //         onSubmitted: (_) => _isSubmittingReply ? null : _submitReply(),
      //       ),
      //     ),
      //     IconButton(
      //       icon: _isSubmittingReply
      //           ? const CircularProgressIndicator()
      //           : const Icon(Icons.send, color: Colors.blue),
      //       onPressed: _isSubmittingReply ? null : _submitReply,
      //     ),
      //   ],
      // ),
    );
  }

  Future<void> _submitReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;
    setState(() => _isSubmittingReply = true);

    final payload = {
      'user_id': widget.cuserID,
      'question_id': widget.comment.questionID ?? 0,
      'descr': replyText,
      'expression_type': 2,
      'comment_action': 'add',
      'parent_id': widget.comment.ID,
    };

    final restUtil = RESTUtil(
      baseUrl: AppConstants.LIKES_AND_COMMENTS,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    try {
      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData["error"] == false) {
        final newComment = CommentDTO.fromJson(responseData["result"][0]);
        setState(() {
          _isReplying = false;
          _replyController.clear();
          // Access _addReplies from the parent state
          (context.findAncestorStateOfType<_CommentsScreenState>())
              ?._addReplies(widget.comment.ID!, [newComment]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply posted successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to post reply. Try again!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error posting reply.')));
    } finally {
      setState(() => _isSubmittingReply = false);
    }
  }

  void _showDeleteConfirmation(BuildContext context, CommentDTO comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
            "Are you sure you want to delete this comment? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(CommentDTO comment) async {
    final payload = [
      {
        "tbl": "comments_and_likes",
        "key_values": [
          {"key": "ID", "value": comment.ID}
        ]
      },
      [
        {"key": "status", "value": 0}
      ]
    ];

    try {
      final restUtil = RESTUtil(
        baseUrl: AppConstants.GENERIC_UPDATE,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['error'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Comment deleted successfully!")));
        widget.onDeleteComment?.call(comment.ID!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
            Text(responseData['error_msg'] ?? "Failed to delete comment")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error deleting comment")));
    }
  }

// void _editComment(BuildContext context) {
//   final parentState = context.findAncestorStateOfType<_CommentsScreenState>()!;
//   parentState.setState(() {
//     parentState._editingComment = widget.comment;
//     parentState._commentController.text = widget.comment.descr!;
//   });
// }
}

class TreeLinePainter extends CustomPainter {
  final bool isLastChild;
  TreeLinePainter({required this.isLastChild});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5;

    if (!isLastChild) {
      canvas.drawLine(Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height), paint);
    }
    canvas.drawLine(Offset(size.width / 2, size.height / 2),
        Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
