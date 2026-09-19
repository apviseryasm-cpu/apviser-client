import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../AppConstants.dart';
import '../models/PostsDTO.dart';
import '../models/UserDTO.dart';
import 'ProfileAvatar.dart';

class NormalPollReactedUsersWidget extends StatefulWidget {
  // final List<Option> options;
  final List<UserDTO> reactedUsersList;

  const NormalPollReactedUsersWidget({Key? key, required this.reactedUsersList}) : super(key: key);

  @override
  _NormalPollReactedUsersWidgetState createState() => _NormalPollReactedUsersWidgetState();
}

class _NormalPollReactedUsersWidgetState extends State<NormalPollReactedUsersWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserDTO> allReactedUsers = [];
  List<UserDTO> goodUsers = [];
  List<UserDTO> normalUsers = [];
  List<UserDTO> badUsers = [];

  @override
  void initState() {
    super.initState();
    _segregateUsersByReaction();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs: All, Good, Normal, Bad
  }

  // Segregate users based on the rated points: 10 = Good, 5 = Normal, 0 = Bad
  void _segregateUsersByReaction() {
    allReactedUsers = widget.reactedUsersList;

    for (var user in widget.reactedUsersList) {
      switch (user.ratedPoints) {
        case 10:
          goodUsers.add(user);
          break;
        case 5:
          normalUsers.add(user);
          break;
        case 0:
          badUsers.add(user);
          break;
        default:
        // Handle other cases if needed
          break;
      }
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
            Tab(text: "All (${allReactedUsers.length})"),  // Keep the "All" tab as text
            IndicatorTab(
              color: Colors.green,  // Green for "Good"
              count: goodUsers.length,
            ),
            IndicatorTab(
              color: Colors.yellow, // Yellow for "Normal"
              count: normalUsers.length,
            ),
            IndicatorTab(
              color: Colors.red,    // Red for "Bad"
              count: badUsers.length,
            ),
          ],
          // tabs: [
          //   Tab(text: "All reactions (${allReactedUsers.length})"),  // Tab 1: All reactions
          //   Tab(text: "Good (${goodUsers.length})"),           // Tab 2: Good reactions
          //   Tab(text: "Normal (${normalUsers.length})"),         // Tab 3: Normal reactions
          //   Tab(text: "Bad (${badUsers.length})"),            // Tab 4: Bad reactions
          // ],
        ),
        SizedBox(
          height: 300,  // Give a fixed height to the TabBarView to avoid infinite expansion
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersList(allReactedUsers),  // Tab 1: All reacted users
              _buildUsersList(goodUsers),        // Tab 2: Good reactions
              _buildUsersList(normalUsers),      // Tab 3: Normal reactions
              _buildUsersList(badUsers),         // Tab 4: Bad reactions
            ],
          ),
        ),
      ],
    );
  }

  // Widget for displaying a list of users for each tab
  Widget _buildUsersList(List<UserDTO> users) {
    if (users.isEmpty) {
      return Center(child: Text("No users reacted to this option."));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: ProfileAvatar(user: user),
          title: Text(user.fullName),
          subtitle: Text(user.title),
        );
      },
    );
  }
}

class IndicatorTab extends StatelessWidget {
  final Color color;
  final int count;

  const IndicatorTab({
    super.key,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      ),
    );
  }
}
