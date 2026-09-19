import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../models/PostsDTO.dart';
import '../models/UserDTO.dart';
import 'ProfileAvatar.dart';

class CustomPollReactedUsersWidget extends StatefulWidget {
  final List<Option> options;
  final List<UserDTO> reactedUsersList;

  const CustomPollReactedUsersWidget({Key? key, required this.options, required this.reactedUsersList}) : super(key: key);

  @override
  _CustomPollReactedUsersWidgetState createState() => _CustomPollReactedUsersWidgetState();
}

class _CustomPollReactedUsersWidgetState extends State<CustomPollReactedUsersWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<int, List<UserDTO>> segregatedUsers = {};
  List<UserDTO> allReactedUsers = [];

  @override
  void initState() {
    super.initState();
    _segregateUsersByOption();
    _tabController = TabController(length: widget.options.length + 1, vsync: this); // Add 1 for "All reactions"

    CommonHelper.logDebug("inside CP reacted users widget");
  }

  void _segregateUsersByOption() {
    allReactedUsers = []; // Initialize empty list for all users
    for (var option in widget.options) {
      CommonHelper.logDebug("option id is ${option.optionId} name is ${option.option}");

      int optionId = int.tryParse(option.optionId.toString()) ?? 0;
      String optionName = option.option!;

      // Filter users directly based on the selectedOptionName in UserDTO
      List<UserDTO> usersForOption = widget.reactedUsersList.where((user) {
        return user.selectedOptionName == optionName;
      }).toList();

      // Add users to segregated list
      segregatedUsers[optionId] = usersForOption;

      // Collect all users for the "All reactions" tab
      allReactedUsers.addAll(usersForOption);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,  // Ensures the column wraps its children
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: "All reactions (${widget.reactedUsersList.length})"),  // Add the "All reactions" tab
            ...widget.options.map((option) {
              return Tab(text: "${option.option} (${option.count})");
            }).toList(),
          ],
        ),
        SizedBox(
          height: 300,  // Give a fixed height to the TabBarView to avoid infinite expansion
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllReactedUsers(),  // First tab for all reacted users
              ...widget.options.map((option) {
                return _buildUsersForOption(int.tryParse(option.optionId.toString()) ?? 0);
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  // Widget for "All reactions" tab
  Widget _buildAllReactedUsers() {
    if (allReactedUsers.isEmpty) {
      return Center(child: Text("No users reacted."));
    }

    return ListView.builder(
      itemCount: allReactedUsers.length,
      itemBuilder: (context, index) {
        final user = allReactedUsers[index];
        return ListTile(
          leading: ProfileAvatar(user: user),
          title: Text(user.fullName),
          subtitle: Text(user.title),
        );
      },
    );
  }

  // Widget for users in each option
  Widget _buildUsersForOption(int optionId) {
    final List<UserDTO> users = segregatedUsers[optionId] ?? [];
    CommonHelper.logDebug("inside _buildUsersForOption $optionId length is ${users.length}");
    if (users.isEmpty) {
      return Center(child: Text("No users reacted to this option."));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading:
          ProfileAvatar(user: user),
          // CircleAvatar(
          //   backgroundImage: NetworkImage(
          //     "${AppConstants.APVISER_IMAGES_PATH_FULL}${user.photo}",
          //   ),
          // ),
          title: Text(user.fullName),
          subtitle: Text(user.title),
        );
      },
    );
  }
}
