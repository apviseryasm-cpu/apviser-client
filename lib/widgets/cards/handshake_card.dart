import '../../CommonHelper.dart';
import '../../models/PostsDTO.dart';
import '../../AppConstants.dart';
import 'package:flutter/material.dart';
import '../../pages/suggested_referrals.dart';
import '../../post_details_view.dart';
import 'post_card_base.dart';
import 'post_card_footer.dart';
import 'post_card_header.dart';
import 'dart:convert';
import '../../models/UserDTO.dart';
import '../../DatabaseHelper.dart';
import '../../rest_util.dart';

class HandshakePollCard extends StatefulWidget {
  PostDTO? postDTO;
  final bool? showReportAbuse;
  //GlobalKey _cardKey = GlobalKey(); // GlobalKey to capture the widget as image
  // final bool showEditIcon; // Indicates if the menu should be shown
  final bool? tapToDetails;
  HandshakePollCard(this.postDTO, {this.showReportAbuse=false, this.tapToDetails=true});

  @override
  _HandshakePollCardState createState() => _HandshakePollCardState();
}
class _HandshakePollCardState extends BaseState<HandshakePollCard> {

  // late PostDTO postDTO;
  GlobalKey _cardKey = GlobalKey(); // GlobalKey to capture the widget as image

  @override
  void initState() {
    super.initState();
    // postDTO = widget.postDTO;
  }

  String setPostImage() {
    String _postImage = "${widget.postDTO?.postImage}";

    if (_postImage == null) {
      return "";
    } else {
      return "${AppConstants.APVISER_IMAGES_PATH_FULL}$_postImage";
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppConstants.APP_MAX_WIDTH, // Set a maximum width suitable for both web and mobile
        ),
        child: InkWell(
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
                key: _cardKey, // Attach the key to the card
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
                        PostCardHeader(postDTO: widget.postDTO!, showReportAbuse: widget.showReportAbuse,),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                icon: Icon(Icons.person_add, color: Colors.blue),
                                label: Text("Refer Someone"),
                                onPressed: _handleReferSomeone,
                              ),
                              TextButton.icon(
                                icon: Icon(
                                  widget.postDTO?.reviewStatus == 1 ? Icons.check_circle : Icons.local_offer,
                                  color: widget.postDTO?.reviewStatus == 1 ? Colors.blue : Colors.green,
                                ),
                                label: Text(widget.postDTO?.reviewStatus == 1 ? "Offer Made" : "Make an Offer"),
                                onPressed: () {
                                  setState(() {
                                    widget.postDTO?.pollCUAnswer = widget.postDTO?.pollCUAnswer == 1 ? 0 : 1;
                                    widget.postDTO?.reviewStatus = widget.postDTO?.reviewStatus == 1 ? 0 : 1;
                                  });

                                  if (widget.postDTO?.reviewStatus == 1) {
                                    CommonHelper.logDebug("Offer made to ${widget.postDTO?.questionId}!");
                                    _handleVote(context, widget.postDTO!.questionId!);
                                  } else {
                                    CommonHelper.logDebug("Offer withdrawn for ${widget.postDTO?.questionId}!");
                                    _handleVote(context, widget.postDTO!.questionId!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        // Information Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Wrap(
                            spacing: 20, // Margin between items
                            runSpacing: 10, // Margin between rows
                            children: [
                              Text("${widget.postDTO?.suggestedCount} Suggestions"),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),

              // Footer Section
              Padding(
                padding: const EdgeInsets.only(top: 10.0), // Add spacing
                child: PostCardFooter(
                  cardKey: _cardKey,
                  postDTO: widget.postDTO!,
                ),
              ),
            ],
          ),
        ),
      );

  }

  // void onReferPressed() {
  // }
  void _handleReferSomeone() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuggestedReferralsPage(postDTO: widget.postDTO!,),
      ),
    );
  }

  void _handleVote(BuildContext context, int revId) async {
    final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
    // final user = await hiveHelper.getCurrentUser('cuser');
    UserDTO? user = await _dbHelper.getCurrentUser("cuser");
    if (user != null) {
      final Map<String, dynamic> payload = {

        'rev_id': revId,
        'user_giving_review': user.userID,
        'public_private_flag': 1,
        'handshake':1,
        'review_type': 4,
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
            // Update the PostDTO with new vote information
            widget.postDTO = PostDTO.fromJson(responseData['updated_vote_info'][0]);
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vote submitted successfully!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit vote. Please try again.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not found. Please login again.')));
    }
  }

  // void _handleMakeOffer() {
  //   // Implement the action for the "Make an Offer" button
  //   // ScaffoldMessenger.of(context).showSnackBar(
  //   //   SnackBar(content: Text('Make an Offer pressed!')),
  //   // );
  // }
  // @override
  // VoidCallback onDelete=() {
  //   // this.onDelete();
  // };
}