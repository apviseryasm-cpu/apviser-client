import '../../CommonHelper.dart';
import '../../DatabaseHelper.dart';
import '../../models/PostsDTO.dart';
import '../../AppConstants.dart';
import 'package:flutter/material.dart';
import '../../models/UserDTO.dart';
import '../../pages/create_post.dart';
import '../../post_details_view.dart';
import 'dart:convert';

import '../../rest_util.dart';
import 'post_card_base.dart';
import 'post_card_footer.dart';
import 'post_card_header.dart';


class AnswerCard extends StatefulWidget {
  final PostDTO postDTO;
  GlobalKey _cardKey = GlobalKey(); // GlobalKey to capture the widget as image
  // final bool showEditIcon; // Indicates if the menu should be shown
  final bool? showReportAbuse;
  final bool? tapToDetails;
  AnswerCard(this.postDTO, {this.showReportAbuse=false, this.tapToDetails=true});

  @override
  _AnswerCardState createState() => _AnswerCardState();
}

class _AnswerCardState extends BaseState<AnswerCard> {

  // late PostDTO postDTO;
  bool _isVoting = false; // Track whether a vote request is in progress
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  UserDTO? user;

  @override
  void initState() {
    super.initState();
    // postDTO = widget.postDTO;
    _initializeUser();  // Initialize user in initState
  }

  Future<void> _initializeUser() async {
    user = await _dbHelper.getCurrentUser("cuser");  // Get user from database
    setState(() {});  // Call setState to update the UI if needed
  }

  @override
  Widget build(BuildContext context) {
    return
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppConstants.APP_MAX_WIDTH, // Set a maximum width suitable for both web and mobile
        ),
        child:
        InkWell(
          onTap:widget.tapToDetails! ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsView(postDTO: widget.postDTO!, showReportAbuse: widget.showReportAbuse,),
              ),
            );
          }:null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: widget._cardKey, // Attach the key to the card
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppConstants.APP_MAX_WIDTH, // Define max width suitable for web and mobile
                  ),
                  child: Container(
                    // color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Header
                        PostCardHeader(postDTO: widget.postDTO!, showReportAbuse: widget.showReportAbuse),

                      ],
                    ),
                  ),
                ),
              ),

              // Footer Section
              Padding(
                padding: const EdgeInsets.only(top: 10.0), // Add spacing
                child: PostCardFooter(
                  cardKey: widget._cardKey,
                  postDTO: widget.postDTO!,
                ),
              ),
            ],
          ),
        ),
      );
  }
// @override
// VoidCallback onDelete=() {
//   // this.onDelete();
// };
}
