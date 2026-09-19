import 'dart:convert';

import 'package:Apviser/colours.dart';
import 'package:Apviser/widgets/app_bar.dart';

import '../../models/PostsDTO.dart';
import '../../AppConstants.dart';
import 'package:flutter/material.dart';
import '../../post_details_view.dart';
import '../CommonHelper.dart';
import '../DatabaseHelper.dart';
import '../models/UserDTO.dart';
import '../rest_util.dart';
import '../widgets/ProfileAvatar.dart';
import 'add_friends.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb

class SuggestedReferralsPage extends StatefulWidget {
  PostDTO? postDTO;

  SuggestedReferralsPage({required this.postDTO});

  @override
  _SuggestedReferralsPageState createState() => _SuggestedReferralsPageState();
}

class _SuggestedReferralsPageState extends State<SuggestedReferralsPage> {
  bool isLoading = true;
  List<UserDTO> users = [];
  // expertiseNames;
  late String expertiseText;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  UserDTO? cuser; // Declare at class level

  @override
  void initState() {
    super.initState();
    _initializeUser(); // Load user data
  }

  Future<void> _initializeUser() async {
    cuser = await _dbHelper.getCurrentUser("cuser");
    CommonHelper.logDebug("cuser id is ${cuser?.userID}");
    setState(() {}); // Trigger UI update after fetching user

    _fetchSuggestedReferrals();
  }

  Future<void> _fetchSuggestedReferrals() async {
    late List<String?> expertiseNames =
        widget.postDTO?.expertiseDetails?.map((e) => e.name).toList() ?? [];
    expertiseText = expertiseNames.whereType<String>().join(", ");
    CommonHelper.logDebug("extertise are " + expertiseNames.toString());
    final Map<String, dynamic> payload = {
      "user_id": "${cuser?.userID}",
      "expertise": widget.postDTO?.expertiseDetails
              ?.map((e) => e.expertiseId)
              .toList() ??
          [],
      "question_id": widget.postDTO?.id,
    };

    try {
      final restUtil = RESTUtil(
        baseUrl: AppConstants.GET_SUGGESTED_REFERALS_LIST,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      if (response.statusCode == 200) {
        // final responseData = json.decode(response.body);
        final responseData = json.decode(response.body) as List<dynamic>;
        // if (responseData['error'] == false) {
        setState(() {
          users = responseData.map((user) => UserDTO.fromJson(user)).toList();
          isLoading = false;
        });
        // }
      } else {
        throw Exception("Failed to fetch data");
      }
    } catch (e) {
      CommonHelper.logDebug("Error fetching suggested referrals: $e");
      setState(() => isLoading = false);
    }
  }

  void _handleRefer(
      BuildContext context, int revId, int suggestedUserID) async {
    final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
    UserDTO? user = await _dbHelper.getCurrentUser("cuser");
    if (user != null) {
      final Map<String, dynamic> payload = {
        'rev_id': revId,
        'user_giving_review': user.userID,
        'public_private_flag': 1,
        'handshake': 2, // hard coded for referral
        'review_type': 4,
        'answer': suggestedUserID
      };

      final restUtil = RESTUtil(
        baseUrl: AppConstants.SUBMIT_REVIEW,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );
      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['error'] == false) {
          setState(() {
            // Update the PostDTO with new vote information
            widget.postDTO =
                PostDTO.fromJson(responseData['updated_vote_info'][0]);
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('suggested successfully!')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit. Please try again.')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found. Please login again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Suggested Referrals",
        showBackButton: true,
        actions: [
          if (!kIsWeb) // Show only if NOT Web
            IconButton(
              icon: Icon(
                Icons.person_add,
                color: AppColors.secondary,
              ), // Use an "Add Friend" icon

              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactsPage(
                      referrerID: cuser!.userID,
                      showSkip: false,
                      expertise: widget.postDTO?.getExpertiseIds(),
                      questionID: widget.postDTO?.questionId,
                    ),
                  ),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    setState(() {
                      _fetchSuggestedReferrals(); // Refresh the previous screen
                    });
                  }
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: !kIsWeb // Mobile Only
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0), // Add spacing above the button
                              child: Text(
                                "No one in your friends list has the expertise $expertiseText.\nFind new friends from your contacts!",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w400),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.person_add), // "Add Friend" icon
                              label: Text("Find Friends from Contacts"),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactsPage(
                                      referrerID: cuser!.userID,
                                      showSkip: false,
                                      expertise:
                                          widget.postDTO?.getExpertiseIds(),
                                      questionID: widget.postDTO?.questionId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      : Text.rich(
                          TextSpan(
                            text:
                                "No one in your friends list has the expertise ",
                            children: [
                              TextSpan(
                                text: expertiseText,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold), // Bold text
                              ),
                              TextSpan(text: ". Try expanding your network."),
                            ],
                            style:
                                TextStyle(fontSize: 16), // Default text style
                          ),
                          textAlign: TextAlign.center, // Center align text
                        ),
                )
              :
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH), // Set max width
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading:
                // CircleAvatar(
                //   backgroundImage: NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${user.photo}"),
                // )
                ProfileAvatar(
                  size: 70,
                  user: UserDTO(userID: user.userID, photo: user.photo),
                  isCurrentUser: false,
                  cUserID: cuser!.userID,
                ),
                title: Text(user.fullName),
                subtitle: Text(user.title),
                trailing: IconButton(
                  icon: Icon(
                    user.suggestedFriendStatus == 1
                        ? Icons.check_circle
                        : Icons.person_add,
                    color: user.suggestedFriendStatus == 1
                        ? Colors.green
                        : Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      user.suggestedFriendStatus =
                      user.suggestedFriendStatus == 1 ? 0 : 1;
                    });

                    // Handle friend referral API calls
                    _handleRefer(context, widget.postDTO!.questionId!,
                        user.userID);
                  },
                ),
              );
            },
          ),
        ),
      )
      ,
    );
  }
}
