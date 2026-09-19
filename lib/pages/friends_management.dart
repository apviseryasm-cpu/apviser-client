import 'package:Apviser/colours.dart';
import 'package:Apviser/pages/home.dart';
import 'package:Apviser/pages/profile_settings.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../DatabaseHelper.dart';
import '../models/UserDTO.dart';
import '../rest_util.dart';
import '../widgets/ProfileAvatar.dart';
import 'add_friends.dart'; // Ensure this path is correct
import 'package:flutter/foundation.dart'; // Import kIsWeb


final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

class FriendsManagementScreen extends StatefulWidget {
  @override
  _FriendsManagementScreenState createState() => _FriendsManagementScreenState();
}

class _FriendsManagementScreenState extends State<FriendsManagementScreen> {
  List<UserDTO> friendsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _initializeUser();
  }

  Future<void> _initializeUser() async {
    user = await _dbHelper.getCurrentUser("cuser"); // Get user from database
    _fetchFriendsList();
    setState(() {}); // Call setState to update the UI if needed
  }

  Future<void> _fetchFriendsList() async {
    try {
      final restUtil = RESTUtil(
        baseUrl: '${AppConstants.URL_FRIEND_LIST}${user?.userID}/0/',
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );
      final response = await restUtil.get(restUtil.baseUrl);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as List<dynamic>;
        setState(() {
          friendsList = responseData
              .map((friend) => UserDTO.fromJson(friend))
              .toList();
          _isLoading = false;
        });
      } else {
        _showErrorToast("Failed to load friends list");
      }
    } catch (e) {
      _showErrorToast("Error fetching friends: $e");
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(title: "Friends Management", showBackButton: true, actions: [
        if (!kIsWeb) // Show only if NOT Web
          IconButton(
            icon: Icon(Icons.person_add, color: AppColors.secondary,), // Use an "Add Friend" icon
            onPressed: () async {
              final bool? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactsPage(referrerID: user!.userID, showSkip: false,), // Pass userId to ContactsPage
                ),
              );

              // Check if the result is a bool and if the photo was changed
              if (result == true) {
                //_fetchUserProfile(); // Reload the profile to reflect the updated photo
                setState(() {
                  _fetchFriendsList();
                });
              }
            },
          ),
      ],),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
          child: friendsList.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child:
            Text(
              AppConstants.TEXT_NO_FRIENDS,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
            ,
          )
              : ListView.builder(
            itemCount: friendsList.length,
            itemBuilder: (context, index) {
              return _buildFriendItem(friendsList[index]);
            },
          ),
        ),
      ),
      // ListView.builder(
      //   itemCount: friendsList.length,
      //   itemBuilder: (context, index) {
      //     return _buildFriendItem(friendsList[index]);
      //   },
      // ),
    );
  }
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar:
  //     CustomAppBar(title: "Friends Management", showBackButton: true, actions: [
  //           if (!kIsWeb) // Show only if NOT Web
  //             IconButton(
  //               icon: Icon(Icons.person_add, color: AppColors.secondary,), // Use an "Add Friend" icon
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => ContactsPage(referrerID: user!.userID, showSkip: false,), // Pass userId to ContactsPage
  //                   ),
  //                 );
  //               },
  //             ),
  //     ],),
  //
  //     body: _isLoading
  //         ? Center(child: CircularProgressIndicator())
  //         : Center(
  //       child: ConstrainedBox(
  //         constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH), // Set max width
  //         child: ListView.builder(
  //           itemCount: friendsList.length,
  //           itemBuilder: (context, index) {
  //             return _buildFriendItem(friendsList[index]);
  //           },
  //         ),
  //       ),
  //     ),
  //     // ListView.builder(
  //     //   itemCount: friendsList.length,
  //     //   itemBuilder: (context, index) {
  //     //     return _buildFriendItem(friendsList[index]);
  //     //   },
  //     // ),
  //   );
  // }

  Widget _buildFriendItem(UserDTO friend) {
    return Card(
      elevation: 2, // Light shadow effect
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Aligns top
              children: [
                // A1, A2: Profile Picture spanning two rows
                // ProfileAvatar(size: 80, user: friend),
                ProfileAvatar(size:80, user: UserDTO(userID: friend.userID, photo: friend.photo), isCurrentUser: false, cUserID: user!.userID ,),
                SizedBox(width: 10), // Space between picture & text

                // B1 & B2: User Name & Buttons
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // B1: User Name
                      Text(
                        friend.fullName.isEmpty ? friend.phoneNumber : friend.fullName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      // B2: Buttons
                      SizedBox(height: 5), // Small spacing before buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start, // Align buttons left
                        children: _getActionButtons(friend),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


// Method to determine action buttons based on status_descr
  List<Widget> _getActionButtons(UserDTO friend) {
    List<Widget> buttons = [];

    if (friend.requestStatusDescr == "Unfriend") {
      buttons.add(
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: Size(120, 40), // Consistent button size
          ),
          icon: Icon(Icons.person_remove),
          label: Text("Unfriend"),
          onPressed: () => _unfriendFriend(friend),
        ),
      );
    }

    if (friend.requestStatusDescr == "Accept Request") {
      buttons.addAll([
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: Size(100, 40),
          ),
          icon: Icon(Icons.check_circle),
          label: Text("Accept"),
          onPressed: () => _acceptFriendRequest(friend),
        ),
        SizedBox(width: 10), // Space between buttons
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            minimumSize: Size(100, 40),
          ),
          icon: Icon(Icons.cancel),
          label: Text("Reject"),
          onPressed: () => _rejectFriendRequest(friend),
        ),
      ]);
    }

    if (friend.requestStatusDescr == "Cancel Request") {
      buttons.add(
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: Size(120, 40),
          ),
          icon: Icon(Icons.cancel),
          label: Text("Cancel"),
          onPressed: () => _cancelFriendRequest(friend),
        ),
      );
    }

    return buttons;
  }


  // Method to handle menu selection
  void _handleMenuSelection(String value, UserDTO friend) {
    switch (value) {
      case 'View Profile':
        _navigateToProfile(friend);
        break;
      case 'Unfriend':
        _unfriendFriend(friend);
        break;
      case 'Cancel Request':
        _cancelFriendRequest(friend);
        break;
      case 'Accept Request':
        _acceptFriendRequest(friend);
        break;
      case 'Reject Request':
        _rejectFriendRequest(friend);
        break;
    }
  }

  // Popup menu items based on friend status
  List<PopupMenuEntry<String>> _getPopupMenuItems(String status_descr) {
    List<PopupMenuEntry<String>> menuItems = [
      PopupMenuItem<String>(
        value: 'View Profile',
        child: Text('View Profile'),
      ),
    ];

    if (status_descr == 'Unfriend') {
      menuItems.addAll([
        PopupMenuItem<String>(
          value: 'Unfriend',
          child: Text('Unfriend'),
        ),
      ]);
    } else if (status_descr == 'Cancel Request') {
      menuItems.addAll([
        PopupMenuItem<String>(
          value: 'Cancel Request',
          child: Text('Cancel Request'),
        ),
      ]);
    } else if (status_descr == 'Accept Request') {
      menuItems.addAll([
        PopupMenuItem<String>(
          value: 'Accept Request',
          child: Text('Accept Request'),
        ),
        PopupMenuItem<String>(
          value: 'Reject Request',
          child: Text('Reject Request'),
        ),
      ]);
    }

    return menuItems;
  }

  // Function to navigate to the friend's profile
  void _navigateToProfile(UserDTO friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSettingsScreen(userId: friend.userID, currentUserId: user!.userID, userName: friend.fullName,),
      ),
    );
  }

  // Function to unfriend a friend
  void _unfriendFriend(UserDTO friend) async {
    if (user == null) {
      Fluttertoast.showToast(
        msg: "User not logged in.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    Map<String, dynamic> requestData = {
      "friendID": friend.userID.toString(), // ID of the user to be unfriended
      "userID": user!.userID, // Current user ID
      "action": "unfriend", // API action
    };

    try {
      final RESTUtil _apiUtil = RESTUtil(
        baseUrl: AppConstants.APPROVE_FRIEND,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": json.encode(requestData),
      });

      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        // Fluttertoast.showToast(
        //   msg: responseData['error_msg'] ?? "Unfriended successfully",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        CommonHelper.showMessage(context, "Unfriended successfully", 5);
        // Refresh the UI by updating the friends list
        setState(() {
          friendsList.removeWhere((u) => u.userID == friend.userID);
        });
      } else {
        // Fluttertoast.showToast(
        //   msg: responseData['error_msg'] ?? "Failed to unfriend. Try again.",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.red,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        CommonHelper.showMessage(context, "Failed to unfriend. Try again.", 5);
      }
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');
      Fluttertoast.showToast(
        msg: "An error occurred. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }


  // Function to cancel friend request
  void _cancelFriendRequest(UserDTO friend) async {
    if (user == null) {
      // Fluttertoast.showToast(
      //   msg: "User not logged in.",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );
      CommonHelper.showMessage(context, "User not logged in.", 5);
      return;
    }

    Map<String, dynamic> requestData = {
      "friendID": friend.userID.toString(), // ID of the user to be unfriended
      "userID": user!.userID, // Current user ID
      "action": "cancel", // API action
    };

    try {
      final RESTUtil _apiUtil = RESTUtil(
        baseUrl: AppConstants.APPROVE_FRIEND,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": json.encode(requestData),
      });

      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        // Fluttertoast.showToast(
        //   msg: responseData['error_msg'] ?? "Cancelled successfully",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        CommonHelper.showMessage(context, "Cancelled successfully", 5);
        // Refresh the UI by updating the friends list
        setState(() {
          friendsList.removeWhere((u) => u.userID == friend.userID);
        });
      } else {
        // Fluttertoast.showToast(
        //   msg: responseData['error_msg'] ?? "Failed to unfriend. Try again.",
        //   toastLength: Toast.LENGTH_SHORT,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.red,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );
        CommonHelper.showMessage(context, "Failed to cancel. Try again.", 5);
      }
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');
      // Fluttertoast.showToast(
      //   msg: "An error occurred. Please try again.",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );

      CommonHelper.showMessage(context, "An error occurred. Please try again.", 5);
    }
  }

  // Function to accept friend request
  void _acceptFriendRequest(UserDTO friend) async{
    // Logic to accept friend request
    // Logic to reject friend request
    if (user == null) {
      CommonHelper.showMessage(context, "User not logged in.", 5);
      return;
    }

    Map<String, dynamic> requestData = {
      "friendID": friend.userID.toString(), // ID of the user to be unfriended
      "userID": user!.userID, // Current user ID
      "action": "accept", // API action
    };

    try {
      final RESTUtil _apiUtil = RESTUtil(
        baseUrl: AppConstants.APPROVE_FRIEND,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": json.encode(requestData),
      });

      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        CommonHelper.showMessage(context, "Request Accepted!", 5);
        // Refresh the UI by updating the friends list
        setState(() {
          friendsList.removeWhere((u) => u.userID == friend.userID);
        });
      } else {
        CommonHelper.showMessage(context, "Failed to Accept. Try again.", 5);
      }
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');

      CommonHelper.showMessage(context, "An error occurred. Please try again.", 5);
    }
  }

  // Function to reject friend request
  void _rejectFriendRequest(UserDTO friend) async{
    // Logic to reject friend request
    if (user == null) {
      CommonHelper.showMessage(context, "User not logged in.", 5);
      return;
    }

    Map<String, dynamic> requestData = {
      "friendID": friend.userID.toString(), // ID of the user to be unfriended
      "userID": user!.userID, // Current user ID
      "action": "reject", // API action
    };

    try {
      final RESTUtil _apiUtil = RESTUtil(
        baseUrl: AppConstants.APPROVE_FRIEND,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": json.encode(requestData),
      });

      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        CommonHelper.showMessage(context, "Request Rejected successfully", 5);
        // Refresh the UI by updating the friends list
        setState(() {
          friendsList.removeWhere((u) => u.userID == friend.userID);
        });
      } else {
        CommonHelper.showMessage(context, "Failed to Reject. Try again.", 5);
      }
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');

      CommonHelper.showMessage(context, "An error occurred. Please try again.", 5);
    }
  }
}
