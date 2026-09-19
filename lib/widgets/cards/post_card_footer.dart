import 'dart:convert';

import 'package:Apviser/colours.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../AppConstants.dart';
import '../../CommonHelper.dart';
import '../../DatabaseHelper.dart';
import '../../comments_screen.dart';
import '../../models/PostsDTO.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/UserDTO.dart';
import '../../rest_util.dart';


class PostCardFooter extends StatefulWidget {
  final PostDTO postDTO;
  final GlobalKey cardKey;

  @override
  _PostCardFooterState createState() => _PostCardFooterState();

  PostCardFooter({required this.postDTO, required this.cardKey});
}

class _PostCardFooterState extends State<PostCardFooter> {
  late PostDTO postDTO;
  late GlobalKey _cardKey;

  @override
  void initState() {
    super.initState();
    postDTO = widget.postDTO;
    _cardKey=widget.cardKey;
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(15.0),
          padding: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.blue),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Keep elements evenly spaced
            // children: <Widget>[
            //   // Bump Button with Text
            //   GestureDetector(
            //     onTap: () => _handleBump(context, postDTO), // onPressed functionality added here
            //     child: Column(
            //       children: [
            //         Image.asset(
            //           'assets/images/bump_post.png',
            //           fit: BoxFit.cover,
            //           height: 40,
            //           width: 30,
            //         ),
            //         Text("Bumps (${postDTO.bumpCount})"),
            //       ],
            //     ),
            //   ),
            //
            //   // Comment Button with Text
            //   GestureDetector(
            //     onTap: () => Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => CommentsScreen(questionId: postDTO.id!),
            //       ),
            //     ),
            //     child: Column(
            //       children: [
            //         Image.asset(
            //           'assets/images/comment_post.png',
            //           fit: BoxFit.cover,
            //           height: 40,
            //           width: 40,
            //         ),
            //         Text("Comments (${postDTO.answerCount})"),
            //       ],
            //     ),
            //   ),
            //
            //   // Share Button with Text
            //   GestureDetector(
            //     onTap: () => _shareCardWithImage(postDTO, _cardKey), // onPressed functionality added
            //     child: Column(
            //       children: [
            //         Image.asset(
            //           'assets/images/share_post.png',
            //           fit: BoxFit.cover,
            //           height: 35,
            //           width: 40,
            //         ),
            //         Text("Share"),
            //       ],
            //     ),
            //   ),
            // ],
            children: <Widget>[
              // Bump Button with Text
              GestureDetector(
                onTap: () => _handleBump(context, postDTO),
                child: Column(
                  children: [
                    Icon(
                      Icons.rocket_launch, // Modern icon for "boost" or "bump"
                      size: 30,
                      color: Colors.redAccent,
                    ),
                    Text("Bumps (${postDTO.bumpCount})"),
                  ],
                ),
              ),

              // Comment Button with Text
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(questionId: postDTO.id!),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline, // Clear icon for comments
                      size: 30,
                      color: Colors.redAccent,
                    ),
                    Text("Comments (${postDTO.answerCount})"),
                  ],
                ),
              ),

              // Share Button with Text
              GestureDetector(
                onTap: () => _shareCardWithImage(postDTO, _cardKey),
                child: Column(
                  children: [
                    Icon(
                      Icons.share, // Standard share icon
                      size: 30,
                      color: Colors.redAccent,
                    ),
                    Text("Share"),
                  ],
                ),
              ),
            ],

          ),
        ),
      ],
    );
  }

  void _shareCardWithImage(PostDTO postDTO, GlobalKey key) async {
    try {
      // Delay to ensure the widget is rendered
      await Future.delayed(Duration(milliseconds: 500));

      RenderRepaintBoundary? boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      // Ensure boundary is not null
      if (boundary == null) {
        CommonHelper.logDebug("Error: RepaintBoundary is null.");
        return;
      }

      // ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      // With this:
      ui.Image image = await _captureWithWhiteBackground(boundary, pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save the image to temporary directory (Only for non-web platforms)
      if (!kIsWeb) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/poll_card_${postDTO.id}.png';
        File imgFile = File(imagePath);
        imgFile.writeAsBytesSync(pngBytes);

        // Share the image with the post link (Mobile/Non-web)
        String postLink = "${AppConstants.APVISER_WEB_LINK}/#/single/${postDTO.id}";
        // Share the file
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out this post: $postLink',
          subject: 'Poll Summary',
        );
      } else {
        // Handle web: Open email client with the poll image and link
        // String postLink = "${AppConstants.APVISER_WEB_LINK}/#/single/${postDTO.slug}";
        // String postLink = "${AppConstants.APVISER_WEB_LINK}/#/single/${postDTO.id}";
        final String pathSegment = postDTO.slug?.isNotEmpty == true
            ? postDTO.slug!
            : postDTO.id.toString();
        String postLink = "${AppConstants.APVISER_WEB_LINK}/#/single/$pathSegment";

        String emailSubject = Uri.encodeComponent('Poll Summary');
        String emailBody = Uri.encodeComponent('Check out this post: $postLink');

        // Open mailto link with the subject and body pre-filled
        // final mailtoLink = 'mailto:?subject=$emailSubject&body=$emailBody';
        // if (await canLaunch(mailtoLink)) {
        //   await launch(mailtoLink);
        // } else {
        //   CommonHelper.logDebug("Could not launch email client.");
        // }
        _showWebShareFallback(postLink);
      }
    } catch (e) {
      CommonHelper.logDebug("Error capturing and sharing poll card: $e");
    }
  }

  void _showWebShareFallback(String postLink) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        // title: Text("Sharing not supported"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text("Sharing images is not supported on web yet."),
            const SizedBox(height: 12),
            SelectableText(postLink),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.copy),
              label: Text("Copy Link"),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: postLink));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Link copied to clipboard")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<ui.Image> _captureWithWhiteBackground(RenderRepaintBoundary boundary, {double pixelRatio = 3.0}) async {
    final ui.Image original = await boundary.toImage(pixelRatio: pixelRatio);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    // Draw white background first
    canvas.drawRect(Rect.fromLTWH(0, 0, original.width.toDouble(), original.height.toDouble()), paint);

    // Draw original captured image on top
    canvas.drawImage(original, Offset.zero, Paint());

    return await recorder.endRecording().toImage(original.width, original.height);
  }

  void _handleBump(BuildContext context, PostDTO postDTO) async {
    final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
    UserDTO? user = await _dbHelper.getCurrentUser("cuser");

    if (user != null) {
      final Map<String, dynamic> payload = {
        'userID': user.userID,
        'type': postDTO.type,  // Post type from PostDTO
        'level_of_bump': 3,    // Hardcoded level_of_bump
        'question_id': postDTO.id,  // Question ID from PostDTO
        'expertise': postDTO.expertiseDetails?.map((e) => e.expertiseId).toList() ?? []  // Expertise from PostDTO
      };

      final restUtil = RESTUtil(
        baseUrl: AppConstants.BUMP_POST,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['error'] == true && responseData['error_msg'] != null) {
          String errorMsg = responseData['error_msg'].toString();

          if (errorMsg.contains("no one in your friends list with the mentioned expertise")) {
            // Show professional message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppConstants.BUMPED_MESSAGE1,
                ),
              ),
            );
          } else {
            // Other error messages
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
          }
        } else {
          setState(() {
            // Update the PostDTO with new vote information
            this.postDTO = PostDTO.fromJson(responseData['updated_vote_info'][0]);
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post bumped successfully!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to bump post. Please try again later.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found. Please login again.')),
      );
    }
  }

}
