import 'package:flutter/material.dart';
import '../AppConstants.dart';
import '../DatabaseHelper.dart';
import '../models/UserDTO.dart';
import '../pages/profile_settings.dart';
//import '../pages/profile_settings_screen.dart';

class ProfileAvatar extends StatefulWidget {
  final UserDTO user;
  final double size;
  final bool isCurrentUser;
  final int cUserID;
  const ProfileAvatar({
    Key? key,
    required this.user,
    this.size = 50.0,
    this.isCurrentUser=false,
    this.cUserID=0
  }) : super(key: key);

  @override
  _ProfileAvatarState createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  UserDTO? cuser;
  int? cUserID;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    cuser = await _dbHelper.getCurrentUser("cuser");
    setState(() {
      cUserID = cuser?.userID;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cUserID == null
          ? null // Disable tap if cUserID is not loaded
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSettingsScreen(
              userId: widget.user.userID == cUserID
                  ? cUserID!
                  : widget.user.userID, // If same, use cUserID
              currentUserId: cUserID!, // Always pass current user ID
              userName: widget.user.fullName,
            ),
          ),
        );
      },
      child: CircleAvatar(
        radius: widget.size / 2,
        backgroundColor: Colors.grey[300],
        backgroundImage: widget.user.photo.isNotEmpty
            ? NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${widget.user.photo}")
            : null,
        child: widget.user.photo.isEmpty
            ? Icon(Icons.person, size: widget.size * 0.6, color: Colors.grey[700])
            : null,
      ),
    );
  }
}


/*
class ProfileAvatar extends StatelessWidget {
  final UserDTO user;
  final int? cUserID; // Current user ID passed separately
  final bool isCurrentUser;
  final double size;

  const ProfileAvatar({
    Key? key,
    required this.user,
    this.cUserID=0, // Now required
    this.isCurrentUser = false,
    this.size = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSettingsScreen(
              userId: isCurrentUser ? cUserID! : user.userID, // Correct user logic
              currentUserId: cUserID!, // Always pass current user ID
              userName: user.fullName,
            ),
          ),
        );
      },
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey[300],
        backgroundImage: user.photo.isNotEmpty
            ? NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${user.photo}")
            : null,
        child: user.photo.isEmpty
            ? Icon(Icons.person, size: size * 0.6, color: Colors.grey[700])
            : null,
      ),
    );
  }
}
*/

// class ProfileAvatar extends StatelessWidget {
//   final UserDTO user;
//   final bool isCurrentUser; // If true, pass `currentUserId` instead of `friend.userID`
//   final double size; // Allow customizable size
//   final int? friendID;
//   const ProfileAvatar({
//     Key? key,
//     required this.user,
//     this.friendID,
//     this.isCurrentUser = false,
//     this.size = 50.0, // Default size
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         // Navigate to Profile Settings
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ProfileSettingsScreen(
//               userId: isCurrentUser ? user.userID : friendID!, // Pass correct user ID
//               currentUserId: user.userID, // Always pass currentUserId
//               userName: user.fullName,
//             ),
//           ),
//         );
//       },
//       child: CircleAvatar(
//         radius: size / 2, // Adjust based on provided size
//         backgroundColor: Colors.grey[300], // Placeholder color
//         backgroundImage: user.photo.isNotEmpty
//             ? NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${user.photo}")
//             : null, // Load image if available
//         child: user.photo.isEmpty
//             ? Icon(Icons.person, size: size * 0.6, color: Colors.grey[700]) // Default icon
//             : null,
//       ),
//     );
//   }
// }
