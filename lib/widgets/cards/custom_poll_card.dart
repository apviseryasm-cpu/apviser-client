import 'dart:convert';
import 'package:Apviser/colours.dart';
import '../../models/UserDTO.dart';
import '../../DatabaseHelper.dart';
import '../../models/PostsDTO.dart';
import '../../AppConstants.dart';
import 'package:flutter/material.dart';
import '../../post_details_view.dart';
import '../../rest_util.dart';
import '../../widgets/cards/post_card_footer.dart';
import '../../widgets/cards/post_card_header.dart';
import 'post_card_base.dart';

class CustomPollCard extends StatefulWidget {
  PostDTO? postDTO;
  final bool? showReportAbuse;
  // final bool showEditIcon; // Indicates if the menu should be shown
  final bool? tapToDetails;
  CustomPollCard(this.postDTO, {this.showReportAbuse=false, this.tapToDetails=true});

  @override
  _CustomPollCardState createState() => _CustomPollCardState();
}
class _CustomPollCardState extends BaseState<CustomPollCard> {
  // late PostDTO postDTO;
  GlobalKey _cardKey = GlobalKey(); // GlobalKey to capture the widget as image

  bool isPostHidden = false; // Track if the post is hidden

  @override
  void initState() {
    super.initState();
    // postDTO = widget.postDTO;
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
                key: _cardKey, // Attach the key to the card
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600, // Maximum width for responsive layout
                  ),
                  child: Container(
                    // color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post Header
                        PostCardHeader(postDTO: widget.postDTO!, showReportAbuse: widget.showReportAbuse),

                        // Bar Chart Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0), // Add spacing
                          child: _buildBarChartWithLabels(context),
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

  Widget _buildBarChartWithLabels(BuildContext context) {
    double totalCount = widget.postDTO!.options!.fold(0, (sum, item) {
      return sum + (double.tryParse(item.count.toString() ?? '0') ?? 0.0);
    });

    // Generate the chart lines
    List<Widget> chartLines = widget.postDTO!.options!.map((option) {
      double count = double.tryParse(option.count.toString() ?? '0') ?? 0.0;
      double rate = totalCount > 0 ? count / totalCount : 0.01;

      return ChartLine(
        title: option.option ?? 'Unknown',
        number: count.toInt(),
        rate: rate > 0 ? rate : 0.01,
        onVote: () =>
            _handleVote(context, option.option!, widget.postDTO!.id!, option.optionId!),
      );
    }).toList();

    // Adjust container height based on the number of bars
    double containerHeight = (chartLines.length * 78).toDouble();

    return Container(
      padding: const EdgeInsets.only(
          left: 20.0, right: 100.0), // Add left and right padding
      alignment: Alignment.centerLeft, // Align content to the left
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalCount == 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No votes yet. Be the first to vote!',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ...chartLines, // Let chartLines define the height dynamically
        ],
      ),
    )
    ;
  }


  void _handleVote(BuildContext context, String vote, int revId, int optionId) async {
    final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
    // final user = await hiveHelper.getCurrentUser('cuser');
    UserDTO? user = await _dbHelper.getCurrentUser("cuser");
    if (user != null) {
      final Map<String, dynamic> payload = {
        'vote': vote,
        'rev_id': revId,
        'user_giving_review': user.userID,
        'review_type': 3,
        'selected_option': optionId,
        'public_private_flag': 1,
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

  @override
  VoidCallback onDelete=() {
    // this.onDelete();
  };

}
class ChartLine extends StatelessWidget {
  const ChartLine({
    Key? key,
    required this.rate,
    required this.title,
    required this.number,
    required this.onVote,
  })  : assert(rate != null),
        assert(rate > 0),
        assert(rate <= 1),
        super(key: key);

  final double rate;
  final String title;
  final int number;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // Use the app's primary color

    return LayoutBuilder(builder: (context, constraints) {
      final lineWidth = constraints.maxWidth * rate;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(minWidth: lineWidth),
              child: IntrinsicWidth(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Add the vote icon button
                    IconButton(
                      icon: Icon(Icons.thumb_up),
                      onPressed: onVote,
                      color: Colors.blue,
                    ),
                    if (number > 0) // Display number in brackets in front of the like button
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '($number)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: primaryColor, // Set the bar color to the primary color of the app
                borderRadius: BorderRadius.circular(15), // Make the bars rounded
              ),
              height: 20, // Set a thinner height for the bars
              width: lineWidth,
            ),
          ],
        ),
      );
    });
  }
}