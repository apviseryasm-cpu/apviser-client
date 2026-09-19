import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../AppConstants.dart';
import '../models/PostsDTO.dart';
import '../models/UserDTO.dart';
import 'ProfileAvatar.dart';

class HandshakePollReactedUsersWidget extends StatefulWidget {
  // final List<Option> options;
  final List<UserDTO> reactedUsersList;

  const HandshakePollReactedUsersWidget({Key? key, required this.reactedUsersList}) : super(key: key);

  @override
  _HandshakePollReactedUsersWidgetState createState() => _HandshakePollReactedUsersWidgetState();
}

class _HandshakePollReactedUsersWidgetState extends State<HandshakePollReactedUsersWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  //List<UserDTO> allReactedUsers = [];
  List<UserDTO> readyToOfferUsers = [];
  List<UserDTO> suggestedUsers = [];

  @override
  void initState() {
    super.initState();
    _segregateUsersByReaction();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs: All, Ready to Offer, Suggested
  }

  // Segregate users based on handshake_interested values
  void _segregateUsersByReaction() {
    if (widget.reactedUsersList != null) {
      // Flatten nested list & parse users properly
      // List<UserDTO> users = (widget.postDTO!.reactedUsersList.expand((x) => x)).toList();
      //
      // allReactedUsers = users;

      for (var user in widget.reactedUsersList) {
        if (user.handshakeInterested == 1) {
          readyToOfferUsers.add(user);
        } else if (user.handshakeInterested == 2) {
          suggestedUsers.add(user);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Ensures the column wraps its children
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: "All"),      // Tab 1: All reactions
            Tab(text: "Ready to Offer"),     // Tab 2: Handshake Interested == 1
            Tab(text: "Suggested"),          // Tab 3: Handshake Interested == 2
          ],
        ),
        SizedBox(
          height: 300, // Fixed height for smooth scrolling
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersList(widget.reactedUsersList),  // Tab 1: All reacted users
              _buildUsersList(readyToOfferUsers), // Tab 2: Ready to Offer
              _buildUsersList(suggestedUsers),   // Tab 3: Suggested
            ],
          ),
        ),
      ],
    );
  }

  // Widget for displaying a list of users for each tab
  Widget _buildUsersList(List<UserDTO> users) {
    if (users.isEmpty) {
      return Center(child: Text("No users reacted in this category."));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: ProfileAvatar(user: user,cUserID: 0,)          ,
          title: Text(user.fullName),
          subtitle: Text(user.title.isNotEmpty ? user.title : "No title provided"),
        );
      },
    );
  }
}

