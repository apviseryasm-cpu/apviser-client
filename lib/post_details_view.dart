import 'dart:convert';

import 'package:Apviser/comments_screen.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import './models/PostsDTO.dart';
import 'AppConstants.dart';
import 'CommonHelper.dart';
import 'DatabaseHelper.dart';
import 'models/UserDTO.dart';
import 'rest_util.dart';
import 'widgets/Custom_Poll_Reacted_Users_Widget.dart';
import 'widgets/Handshake_Poll_Reacted_Users_Widget.dart';
import 'widgets/Normal_Poll_Reacted_Users_Widget.dart';
import 'widgets/cards/answer_card.dart';
import 'widgets/cards/custom_poll_card.dart';
import 'widgets/cards/handshake_card.dart';
import 'widgets/cards/normal_poll_card.dart';
import 'package:flutter/services.dart'; // Required for SystemUiOverlayStyle


class PostDetailsView extends StatefulWidget {
  PostDTO? postDTO;
  final bool? showReportAbuse;
  PostDetailsView({Key? key, this.postDTO, this.showReportAbuse=false}) : super(key: key);


  @override
  _PostDetailsViewState createState() => _PostDetailsViewState();
}

class _PostDetailsViewState extends State<PostDetailsView> {
  //late Future<List<UserDTO>> reactedUsersFuture;
  late Future<PostDTO> postDetails;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  // user;
  late final VoidCallback onDelete;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch related items (reacted users and created posts)
    // reactedUsersFuture = getReactedUsers(widget.postDTO.questionId!);
    // createdPostsFuture = fetchCreatedPosts(widget.postDTO.userId!);
    _initializePostDetails();
    //widget.postDTO = await getPostDetails(widget.postDTO!.questionId!); // stores informaiton in postDetails
    //print("card type is ${widget.postDTO!.type}");
  }

  Future<void> _initializePostDetails() async {
    try {
      var updatedPost = await getPostDetails(widget.postDTO!.questionId!); // Await here
      setState(() {
        // Update the UI after the data is fetched
        widget.postDTO = updatedPost;
        isLoading = false; // Mark loading as complete
        CommonHelper.logDebug("bumpCount is ${widget.postDTO?.bumpCount}");
      });
      CommonHelper.logDebug("card type is ${widget.postDTO!.type}");
    } catch (e) {
      CommonHelper.logDebug("Error fetching post details: $e");
      // Optionally, handle errors here
      setState(() {
        isLoading = false; // Mark loading as complete even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar:
      CustomAppBar(title: "${widget.postDTO!.descr!.length > 100
                                ? widget.postDTO!.descr!.substring(0, 100)+"..."
                                : widget.postDTO!.descr!}", showBackButton: true)
      ,
      body:
      Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppConstants.APP_MAX_WIDTH, // Set predefined width
                ),
                child:
                SafeArea( // Add SafeArea here
                  child: Container(
                    // padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Your existing options...
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
                          children: [
                            // Display Post Card
                            widget.postDTO!.type == 1
                                ? NormalCard(widget.postDTO, showReportAbuse: widget.showReportAbuse, tapToDetails: false,)
                                : widget.postDTO?.type == 2
                                ? AnswerCard(widget.postDTO!, showReportAbuse: widget.showReportAbuse, tapToDetails: false,)
                                : widget.postDTO?.type == 3
                                ? CustomPollCard(widget.postDTO, showReportAbuse: widget.showReportAbuse, tapToDetails: false,)
                                : widget.postDTO?.type == 4
                                ? HandshakePollCard(widget.postDTO, showReportAbuse: widget.showReportAbuse, tapToDetails: false,)
                                : NormalCard(widget.postDTO, showReportAbuse: widget.showReportAbuse, tapToDetails: false,),

                            // Display Reacted Users Section
                            _buildReactedUsersByPollType(widget.postDTO!),
                          ],
                        ),
                      ],
                    ),
                  ),
                )

              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to display the correct reacted users widget based on the poll type
  Widget _buildReactedUsersByPollType(PostDTO postDTO) {
    if (postDTO.type == 1) {
      // return NormalPollReactedUsersWidget(reactedUsersList: postDTO.reactedUsersList);
      return _buildReactedUsersSection(1);
    } else if (postDTO.type == 2) {


      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: CommentsScreen(
              isEmbedded: true,
              questionId: postDTO.questionId != null ? postDTO.questionId! : 0,
            ),
          ),
        ],
      );

    } else if (postDTO.type == 3) {

      return _buildReactedUsersSection(3);

    } else if (postDTO.type == 4) {
      // return HandshakePollReactedUsersWidget(reactedUsersList: postDTO.reactedUsersList);
      return _buildReactedUsersSection(4);
    } else {
      return Container(); // Default case if no valid poll type
    }
  }
  // 1. Reacted Users Horizontal List
  Widget _buildReactedUsersSection(int type) {
    return FutureBuilder<List<UserDTO>>(
      // future: reactedUsersFuture, // The future fetching the reacted users
      //future: widget.postDTO!.reactedUsers, // The future fetching the reacted users
      initialData: widget.postDTO!.reactedUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show loading indicator
        } else if (snapshot.hasError) {
          return Text("Error loading reacted users."); // Error message
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(left: 16.0), // Add equal padding on all sides
            child: Text("No reactions yet."),
          ); // No reactions
        } else {
          // Select widget based on poll type
          switch (type) {
            case 1: // Normal poll
              return NormalPollReactedUsersWidget(
                reactedUsersList: snapshot.data!, // Fetched users
              );
            case 2: // Another poll type
            // Add another widget for type 2 if needed
              CommonHelper.logDebug("Type 2 reacted users");
              return Text("Type 2 reacted users widget not implemented yet.");
            case 3: // Custom poll
              return CustomPollReactedUsersWidget(
                options: widget.postDTO!.options!, // Options for the custom poll
                reactedUsersList: snapshot.data!, // Fetched users
              );
            case 4: // Handshake poll (or other type)
            // Add your HandshakePollReactedUsersWidget here if applicable
              //return Text("Type 4 reacted users widget not implemented yet.");
              return HandshakePollReactedUsersWidget(
                //options: widget.postDTO!.options!, // Options for the custom poll
                reactedUsersList: snapshot.data!, // Fetched users
              );
            default: // Fallback for unhandled types
              return Text("Unsupported poll type.");
          }
        }
      }, future: null,
    );
  }

  Future<PostDTO> getPostDetails(int questionID) async {
    UserDTO? user = await _dbHelper.getCurrentUser("cuser");
    PostDTO postDTO;

    // Prepare the REST utility
    final RESTUtil restUtil = RESTUtil(
      baseUrl: AppConstants.ANSWERS_DETAILS_BY_QUESTION,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    // Prepare the payload as JSON
    final Map<String, dynamic> payload = {
      'question_id': questionID,
      'user_id': user?.userID,
    };

    try {
      // Make the POST request
      final response = await restUtil.postForm(
        restUtil.baseUrl,
        {'json': json.encode(payload)},
      );

      // Check if the response status is 200 OK
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final reactedUsersWrapper = responseData[0]['reacted_users_list'];
        postDTO = PostDTO.fromJson(responseData[0]);
        // PostDTO postDTO2 = PostDTO.fromJson(model2 as Map<String, dynamic>));
        // Ensure the first item is a list, as per your response structure
        /*if (reactedUsersWrapper is List && reactedUsersWrapper.isNotEmpty) {
          final reactedUsers = reactedUsersWrapper[0] as List<dynamic>;

          //print("reacted users");
          //print(reactedUsers[0]);

          // reactedUsersList = reactedUsers
          //     .map((model) => UserDTO.fromJson(model as Map<String, dynamic>))
          //     .toList();
        } else {
          throw Exception('Unexpected response structure.');
        }*/
      } else {
        throw Exception('Failed to fetch reacted users.');
      }
    } catch (error) {
      CommonHelper.logDebug("Error fetching reacted users: $error");
      throw Exception('Failed to fetch reacted users.');
    }

    return postDTO;
  }
}

