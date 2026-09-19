import 'dart:convert';


import '../../DatabaseHelper.dart';
import '../../models/PostsDTO.dart';
import '../../AppConstants.dart';
import 'package:flutter/material.dart';
import '../../models/UserDTO.dart';
import '../../post_details_view.dart';
import '../../rest_util.dart';
import 'post_card_base.dart';
import 'post_card_footer.dart';
import 'post_card_header.dart';

class NormalCard extends StatefulWidget {
  PostDTO? postDTO;
  final bool? showReportAbuse;
  final bool? tapToDetails;
  final bool? isSelectable;
  GlobalKey _cardKey = GlobalKey(); // GlobalKey to capture the widget as image
  // final bool showEditIcon; // Indicates if the menu should be shown
  // final VoidCallback onDelete;

  NormalCard(this.postDTO, {this.showReportAbuse=false, this.tapToDetails=true, this.isSelectable=true});

  @override
  _NormalCardState createState() => _NormalCardState();
}

class _NormalCardState extends BaseState<NormalCard> {
  // late PostDTO postDTO;
  bool _isVoting = false; // Track whether a vote request is in progress
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  UserDTO? user;
  GlobalKey _cardKey1 = GlobalKey(); // GlobalKey to capture the widget as image
  @override
  void initState() {
    super.initState();
    _initializeUser();  // Initialize user in initState
  }

  Future<void> _initializeUser() async {
    user = await _dbHelper.getCurrentUser("cuser");  // Get user from database
    setState(() {});  // Call setState to update the UI if needed
  }

  // Helper method to send vote to the server
  void _submitVote(String vote, int optionValue) async {
    setState(() {
      _isVoting = true; // Show progress while voting
    });


    // user = await _dbHelper.getCurrentUser("cuser");

    if (user != null) {
      final Map<String, dynamic> payload = {
        'vote': vote,
        'rev_id': widget.postDTO?.id, // Post ID from postDTO
        'user_giving_review': user?.userID,
        'public_private_flag': 1,
        'review_type': 1,
      };

      final restUtil = RESTUtil(
        baseUrl: AppConstants.SUBMIT_REVIEW,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['error'] == false) {
          setState(() {
            // Update the postDTO with new vote info
            widget.postDTO = PostDTO.fromJson(responseData['updated_vote_info'][0]);

            // Highlight the voted option
            if (optionValue == 10) {
              widget.postDTO?.pollCUAnswer = 10; // Green vote
            } else if (optionValue == 5) {
              widget.postDTO?.pollCUAnswer = 5; // Yellow vote
            } else if (optionValue == 0) {
              widget.postDTO?.pollCUAnswer = 0; // Red vote
            }

            _isVoting = false; // Reset the voting state
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote submitted successfully!')));
        }
      } else {
        setState(() {
          _isVoting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit vote. Please try again.')));
      }
    }
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
          }: null,  // Disables tap when false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _cardKey1, // Attach the key to the card
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppConstants.APP_MAX_WIDTH, // Maximum width for responsive layout
                  ),
                  child: Container(
                    // color: AppColors.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostCardHeader(postDTO: widget.postDTO!, showReportAbuse: widget.showReportAbuse,), // Header with constraints
                        _buildVoteButtons(), // Buttons
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Section
              Padding(
                padding: const EdgeInsets.only(top: 10.0), // Add spacing
                child: PostCardFooter(
                  cardKey: _cardKey1,
                  postDTO: widget.postDTO!,
                ),
              ),
            ],
          ),
        ),
      );

  }

  // Widget to build vote buttons
  Widget _buildVoteButtons() {
    int best = widget.postDTO?.best ?? 0;
    int good = widget.postDTO?.good ?? 0;
    int poor = widget.postDTO?.poor ?? 0;

    int maxVote = [best, good, poor].reduce((a, b) => a > b ? a : b);

    bool allZero = (best == 0 && good == 0 && poor == 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildVoteOption("Good", "assets/images/green_poll.png", 10, best == maxVote, allZero),
        _buildVoteOption("Normal", "assets/images/yellow_poll.png", 5, good == maxVote, allZero),
        _buildVoteOption("Bad", "assets/images/red_poll.png", 0, poor == maxVote, allZero),
      ],
    );
  }

  Widget _buildVoteOption(String label, String imagePath, int voteValue, bool isHighlighted, bool allZero) {
    return Stack(
      children: <Widget>[
        InkWell(
          onTap: _isVoting ? null : () => _submitVote(label, voteValue),
          child: Opacity(
            opacity: allZero ? 0.3 : (isHighlighted ? 1.0 : 0.3), // Fade all if all are zero
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              height: 80,
              width: 80,
            ),
          ),
        ),
        if (widget.postDTO?.pollCUAnswer == voteValue) _buildUserVoteIcon(),
      ],
    );
  }

  // Widget to show user photo after vote submission
  Widget _buildUserVoteIcon() {
    return Positioned(
      bottom: 5,
      left: 30,
      height: 20,
      width: 20,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff7c94b6),
          image: DecorationImage(
            image: NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${user?.photo}"), // Use user photo from postDTO
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
          border: Border.all(
            color: Colors.black,
            width: 1,
          ),
        ),
      ),
    );
  }
}