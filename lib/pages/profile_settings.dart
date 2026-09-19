import 'dart:convert';

import 'package:Apviser/CommonHelper.dart';
import 'package:Apviser/DatabaseHelper.dart';
import 'package:Apviser/pages/suggested_expertise_management.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../AppConstants.dart'; // Replace with your constants class
import '../colours.dart';
import '../models.dart';
import '../models/PostsDTO.dart';
import '../models/UserDTO.dart'; // Replace with your DTO model class
import '../post.dart';
import '../rest_util.dart';
import 'package:flutter/foundation.dart';
import '../widgets/select_expertise2.dart';
import 'expertise_management.dart';
import 'friends_management.dart';
import 'full_photo.dart';
import 'home.dart';
// Required for SystemUiOverlayStyle

class ProfileSettingsScreen extends StatefulWidget {
  final int userId;
  final int currentUserId;
  final String userName;

  ProfileSettingsScreen(
      {required this.userId,
      required this.currentUserId,
      required this.userName});

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late UserDTO userDetails;
  List<ValueItem<String>> userExpertise = [];
  List<ValueItem<String>> suggestedExpertise = [];
  List<ValueItem<String>> suggestedExpertiseNetwork = [];
  List<UserDTO> friendsList = [];
  List<Map<String, String>> socialMediaLinks = [];
  bool _isLoading = true;
  late bool isViewingOwnProfile;

  // Flag for controlling edit mode
  bool isEditing = false;

  // Controllers for inline editing
  late TextEditingController _fullNameController;
  late TextEditingController _titleController;
  late TextEditingController _aboutController;
  Uint8List? _profileImage; // To store the updated profile image

  // Original data before editing
  late String originalFullName;
  late String originalTitle;
  late String originalAbout;
  // String _currentPhotoUrl = ""; // Store the current photo URL

  //////////////////////////////

//  bool isEditing = false;
//   final TextEditingController _nameController =
//   TextEditingController(text: 'Emma Phillips');
  // final TextEditingController _titleController =
  // TextEditingController(text: 'Fashion Model');
  final TextEditingController _phoneController =
      TextEditingController(text: '');
  late TextEditingController _emailController =
      TextEditingController(text: 'emma.phillips@gmail.com');

  String? _nameError;
  String? _emailError;

  //////////////////////////////

  bool _isSendingRequest = false;
  bool _requestSent = false;

  late UserPostsModel posts;
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {

    isViewingOwnProfile = widget.userId == widget.currentUserId;
    _fetchUserProfile();
    userDetails = UserDTO(userID: widget.userId);
    // userDetails.userID=widget.userId;
    posts = UserPostsModel(userDetails);
    // posts.loadMore2();
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.offset) {
        posts.loadMore2();
      }
    });
    super.initState();
  }

  Future<void> _navigateToFullImageScreen() async {
    // Navigate to the FullImageScreen and wait for the result
    // Navigate to FullImageScreen and expect a bool return value
    final bool? isPhotoChanged = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullPhotoScreen(
          currentUserId: userDetails.userID,
          currentPhoto: userDetails.photo,
          isCurrentUser: isViewingOwnProfile, // Whether the user can edit
          screenTitle: "Profile Picture",
        ),
      ),
    );

    // Check if the result is a bool and if the photo was changed
    if (isPhotoChanged == true) {
      _fetchUserProfile(); // Reload the profile to reflect the updated photo
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final restUtil = RESTUtil(
        baseUrl:
            '${AppConstants.GET_USER_PROFILE}${widget.userId}/${widget.currentUserId}',
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.get(restUtil.baseUrl);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          userDetails = UserDTO.fromJson(responseData['user_details']);
          posts = UserPostsModel(userDetails);
          userExpertise = (responseData['expertise_details'] as List)
              .map((expertise) => ValueItem<String>.fromJson(expertise))
              .toList();

          suggestedExpertise = (responseData['suggested_expertise'] as List)
              .map((expertise) => ValueItem<String>.fromJson(expertise))
              .toList();
          suggestedExpertiseNetwork =
              (responseData['suggested_expertise_network'] as List)
                  .map((expertise) => ValueItem<String>.fromJson(expertise))
                  .toList();

          // socialMediaLinks = (responseData['social_media_details'] as List)
          //     .map((social) => social)
          //     .toList();
          friendsList = (responseData['friends_list']
                  as List<dynamic>) // Cast as List<dynamic>
              .map((friend) => UserDTO.fromJson(friend
                  as Map<String, dynamic>)) // Map each entry to a UserDTO
              .toList(); // Convert the iterable to a list
          // Initialize text controllers with current user data
          _fullNameController =
              TextEditingController(text: userDetails.fullName);
          _titleController = TextEditingController(text: userDetails.title);
          _aboutController = TextEditingController(text: userDetails.about);
          _emailController = TextEditingController(text: userDetails.email);

          // Store original values for cancel operation
          originalFullName = userDetails.fullName;
          originalTitle = userDetails.title;
          originalAbout = userDetails.about;

          _isLoading = false;
        });
      } else {
        _showErrorToast("Failed to load profile");
      }
    } catch (e) {
      _showErrorToast("Error fetching profile: $e");
    }
  }

  Future<void> _submitProfileUpdates() async {
    final payload = [
      {
        "tbl": "users",
        "key_values": [
          {"key": "ID", "value": widget.currentUserId.toString()}
        ]
      },
      [
        {"key": "full_name", "value": _fullNameController.text},
        {"key": "title", "value": _titleController.text},
        {"key": "about", "value": _aboutController.text},
        {"key": "email", "value": _emailController.text},
      ]
    ];

    try {
      final restUtil = RESTUtil(
        baseUrl: AppConstants.GENERIC_UPDATE,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['error'] == false) {
        CommonHelper.showMessage(context, "Profile updated successfully!", 5);
        _fetchUserProfile(); // Refresh the profile data after update
      } else {
        _showErrorToast(
            responseData['error_msg'] ?? "Failed to update profile");
      }
    } catch (e) {
      _showErrorToast("Error updating profile: $e");
    }
  }

  void _showErrorToast(String message) {
    CommonHelper.showMessage(
        context, "Something went wrong while fetching your profile", 5);
    CommonHelper.logDebug(message);
  }

  // Toggle the edit mode
  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  // Reset the values if cancel is pressed
  void _cancelEditing() {
    setState(() {
      _fullNameController.text = originalFullName;
      _titleController.text = originalTitle;
      _aboutController.text = originalAbout;
      isEditing = false; // Exit edit mode
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Profile Settings",
        showBackButton: true,
        actions: [
          if (isViewingOwnProfile && isEditing)
            IconButton(
              icon:
                  Icon(Icons.cancel, color: Colors.white), // Change icon color
              onPressed: () {
                _cancelEditing();
                CommonHelper.logDebug("Editing canceled");
              },
            ),
          if (isViewingOwnProfile)
            IconButton(
              icon: Icon(
                isEditing ? Icons.save : Icons.edit,
                color: Colors.white, // Change icon color
              ),
              onPressed: () {
                if (isEditing) {
                  _submitProfileUpdates();
                }
                _toggleEditMode();
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: scrollController,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        AppConstants.APP_MAX_WIDTH, // Limit the body width
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Image and Name Section
                        _buildUserProfileHeader(),
                        const SizedBox(height: 16.0),

                        // Social Media Links
                        _buildSocialMediaRow(),
                        const SizedBox(height: 16.0),

                        // Friends List Section
                        _buildFriendsList(),
                        const SizedBox(height: 16.0),
                        const Divider(),
                        // Expertise Section
                        _buildExpertiseSection(),

                        // if(!isViewingOwnProfile)...[
                        //if(!isViewingOwnProfile)
                        const SizedBox(height: 16.0),
                        const Divider(),
                        // Suggested Expertise Section
                        _buildSuggestedExpertiseNetworkSection(),
                        // ]

                        if (!isViewingOwnProfile) ...[
                          //if(!isViewingOwnProfile)
                          const SizedBox(height: 16.0),
                          const Divider(),
                          // Suggested Expertise Section
                          _buildSuggestedExpertiseSection()
                        ],

                        const Divider(), // Divider color to white

                        _showUserPosts()
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSocialMediaRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: socialMediaLinks.map((social) {
        return IconButton(
          icon: _getSocialMediaIcon(social['name']!),
          onPressed: () => _launchURL(social['link']!),
        );
      }).toList(),
    );
  }

  Widget _showUserPosts() {
    return StreamBuilder<List<PostDTO>>(
      stream: posts.stream,
      builder: (BuildContext context, AsyncSnapshot<List<PostDTO>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final postList = snapshot.data!;

        return Column(
          children: [
            for (int index = 0; index < postList.length; index++) ...[
              Post(
                post: postList[index],
                showMenu: false,
                onDelete: () {},
                onEdit: () {},
              ),
              const Divider(color: Colors.white),
            ],
            if (posts.hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppConstants.TEXT_NO_MORE_POSTS,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("🎉", style: TextStyle(fontSize: 24, color: AppColors.primary)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }


  Icon _getSocialMediaIcon(String name) {
    switch (name.toLowerCase()) {
      case "facebook":
        return Icon(Icons.facebook, color: Colors.blue);
      case "whatsapp":
        return Icon(Icons.facebook, color: Colors.green);
      case "twitter":
        return Icon(Icons.facebook, color: Colors.blue);
      case "youtube":
        return Icon(Icons.youtube_searched_for, color: Colors.red);
      default:
        return Icon(Icons.link, color: Colors.grey);
    }
  }

  Widget _buildUserProfileHeader() {
    CommonHelper.logDebug(
        "inside _buildUserProfileHeader. Image is $userDetails.photo");
    return Column(
      children: [
        const SizedBox(height: 20),
        // User Avatar
        GestureDetector(
          onTap: _navigateToFullImageScreen,
          child: CircleAvatar(
            radius: 70,
            backgroundImage: _profileImage != null
                ? MemoryImage(_profileImage!)
                : NetworkImage(
                        "${AppConstants.APVISER_IMAGES_PATH_FULL}${userDetails.photo}")
                    as ImageProvider,
          ),
        ),
        const SizedBox(height: 16),
        // Editable Name (mandatory)
        _buildEditableField('Full Name', _fullNameController,
            errorText: _nameError, editFontSize: 13, viewFontSize: 30),
        // Editable Title (optional)
        _buildEditableField('Title', _titleController,
            editFontSize: 13, viewFontSize: 13),
        // const SizedBox(height: 16),
        _buildEditableField('About', _aboutController,
            editFontSize: 13, viewFontSize: 13),
        const SizedBox(height: 16),
        // Phone Number with Copy to Clipboard
        _buildPhoneFieldWithCopyOption(),
        // Editable Email (optional with validation)
        _buildEditableFieldWithIcon(
          Icons.email,
          'Email',
          _emailController,
          errorText: _emailError,
        ),
        const SizedBox(height: 20),
        _buildFriendshipButton(context),
        // ElevatedButton(
        //   onPressed: (!isViewingOwnProfile)
        //   ? _sendOTP
        //       : null,
        //   child: Text('Continue'),
        // ),

        const SizedBox(height: 20),

        // Menu Options
        // _buildMenuOption(Icons.favorite, 'Your Favorites'),
        // _buildMenuOption(Icons.payment, 'Payment'),
        if (isViewingOwnProfile)
          _buildMenuOption(Icons.people, 'Tell Your Friend'),
        if (isViewingOwnProfile) _buildMenuOption(Icons.logout, 'Logout'),
        // _buildMenuOption(Icons.settings, 'Settings'),
        const Divider(),
      ],
    );
  }

  Widget _buildMenuOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      onTap: () {
        if (title == "Tell Your Friend") {
          _shareAppLink();
        } else if (title == "Logout") {
          _showLogoutConfirmation(context); // Show confirmation dialog
        }
      },
    );
  }

  // **1. Show App Share Options**
  void _shareAppLink() {
    const String appLink = "https://www.apviser.com"; // Update with actual link
    const String shareMessage =
        "Hey! Check out Apviser – an amazing platform. Join here: $appLink";

    Share.share(shareMessage);
  }

// **2. Logout Confirmation Dialog**
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Close dialog
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _handleLogout(context); // Proceed with logout
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// **3. Logout Function**
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Clear cache (Hive)
      // await Hive.box('userBox').clear();
      HiveDatabaseHelper.instance.clearBox();
      // Firebase logout (if using Firebase Auth)
      await FirebaseAuth.instance.signOut();

      // Show logout success message
      // Fluttertoast.showToast(
      //   msg: "Logged out successfully!",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.green,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );
      CommonHelper.showMessage(context, "Logged out successfully!", 5);
      // Redirect to Login Screen (Replace with your login screen)
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      // Handle errors
      // Fluttertoast.showToast(
      //   msg: "Error logging out: $e",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );
      CommonHelper.showMessage(context, "Error logging out", 5);
      CommonHelper.logDebug("Error logging out: $e");
    }
  }

  Widget _buildPhoneFieldWithCopyOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Icon(Icons.phone, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              userDetails.phoneNumber,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.grey),
            onPressed: _copyPhoneNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableFieldWithIcon(
      IconData icon, String label, TextEditingController controller,
      {String? errorText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: _buildEditableField(label, controller,
                errorText: errorText, editFontSize: 13, viewFontSize: 16),
          ),
        ],
      ),
    );
  }

  void _copyPhoneNumber() {
    Clipboard.setData(ClipboardData(text: userDetails.phoneNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard!')),
    );
  }

/*
Widget _buildUserProfileHeader_bkp() {
    print("inside _buildUserProfileHeader. Image is $userDetails.photo");
    return Row(
      children: [
        GestureDetector(
          onTap: _navigateToFullImageScreen,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: _profileImage != null
                ? MemoryImage(_profileImage!)
                : NetworkImage("${AppConstants.APVISER_IMAGES_PATH_FULL}${userDetails.photo}") as ImageProvider,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditableField("Full Name", _fullNameController),
              _buildEditableField("Title", _titleController),
              _buildEditableField("About", _aboutController),
              _buildReadOnlyField("Phone", userDetails.phoneNumber),
            ],
          ),
        ),
      ],
    );
  }
* */
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text(value.isNotEmpty
            ? value
            : "No phone number available"), // Show phone number or placeholder
      ],
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    String? errorText,
    double editFontSize = 16,
    double viewFontSize = 18,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing)
            Text(
              label,
              style: TextStyle(
                fontSize: editFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          if (isEditing) const SizedBox(height: 8),
          isEditing
              ? TextField(
                  controller: controller,
                  style: TextStyle(fontSize: editFontSize, color: Colors.black),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    errorText: errorText,
                  ),
                )
              : Text(
                  controller.text,
                  style: TextStyle(fontSize: viewFontSize, color: Colors.black),
                ),
        ],
      ),
    );
  }

  // Widget _buildEditableField(String label, TextEditingController controller,
  //     {String? errorText, double? fontSize=16}) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         if (isEditing) // Show label only in edit mode
  //           Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: fontSize,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.grey,
  //             ),
  //           ),
  //         if (isEditing) const SizedBox(height: 8),
  //         isEditing
  //             ? TextField(
  //           controller: controller,
  //           decoration: InputDecoration(
  //             border: OutlineInputBorder(),
  //             errorText: errorText,
  //           ),
  //         )
  //             : Text(
  //           controller.text,
  //           style: TextStyle(fontSize: fontSize, color: Colors.black),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      CommonHelper.logDebug("Could not launch $url");
    }
  }

  Widget _buildFriendsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Friends List",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isViewingOwnProfile)
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("Manage Friends"),
                onPressed: () {
                  // Navigate to add friends screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FriendsManagementScreen(), // Replace with your settings screen
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140, // Adjust height to accommodate profile picture and text
          child: ScrollConfiguration(
            behavior: ScrollBehavior(), // Ensure proper scroll behavior
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Scroll horizontally
              child: Row(
                children: friendsList.map((friend) {
                  return _buildFriendTile(friend);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendTile(UserDTO friend) {
    return GestureDetector(
      onTap: () {
        // Navigate to the ProfileSettingsScreen with friend's ID and current user ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSettingsScreen(
              userId: friend.userID, // Friend's ID
              // currentUserId: user!.userID,  // Current user's ID
              currentUserId: widget.currentUserId, // Current user's ID
              userName: friend.fullName,
            ),
          ),
        );
      },
      child: Container(
        width: 100, // Static width for each item
        margin:
            EdgeInsets.symmetric(horizontal: 8), // Equal spacing between items
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                "${AppConstants.APVISER_IMAGES_PATH_FULL}${friend.photo}",
              ),
            ),
            const SizedBox(height: 4),
            Text(
              friend.fullName.isNotEmpty ? friend.fullName : friend.phoneNumber,
              textAlign: TextAlign.center,
              maxLines: 2, // Allow up to 2 lines for long names
              overflow: TextOverflow
                  .ellipsis, // Show ellipsis if the name is too long
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertiseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Expertise",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (isViewingOwnProfile)
              TextButton.icon(
                icon: Icon(Icons.edit),
                label: Text("Manage Expertise"),
                onPressed: () {
                  // Navigate to add friends screen
                  _navigateToExpertiseManagement();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        SelectExpertiseWidget2(
          userId: widget.userId,
          initialSelectedOptions: userExpertise,
          onSelectionChanged: (options) {
            setState(() {
              userExpertise = options;
            });
          },
          isEditable:
              false, // Allow editing only if viewing own profile and in edit mode
        ),
      ],
    );
  }

  Widget _buildSuggestedExpertiseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Suggested Expertise By Me",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            //if (isViewingOwnProfile)
            if (!isViewingOwnProfile)
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text("Tag Expertise"),
                onPressed: () {
                  // Navigate to add friends screen
                  _navigateToSuggestedExpertiseManagement();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        SelectExpertiseWidget2(
          userId: widget.userId,
          initialSelectedOptions: suggestedExpertise,
          onSelectionChanged: (options) {
            setState(() {
              suggestedExpertise = options;
            });
          },
          isEditable:
              false, // Allow editing only if viewing own profile and in edit mode
        ),
      ],
    );
  }

  Widget _buildSuggestedExpertiseNetworkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Suggested Expertise By Network",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            //if (isViewingOwnProfile)
            // if(!isViewingOwnProfile)
            // TextButton.icon(
            // icon: Icon(Icons.add),
            // label: Text("Tag Expertise"),
            // onPressed: () {
            // // Navigate to add friends screen
            // _navigateToSuggestedExpertiseManagement();
            // },
            // ),
          ],
        ),
        const SizedBox(height: 8),
        SelectExpertiseWidget2(
          userId: widget.userId,
          initialSelectedOptions: suggestedExpertiseNetwork,
          onSelectionChanged: (options) {
            setState(() {
              suggestedExpertiseNetwork = options;
            });
          },
          isEditable:
              false, // Allow editing only if viewing own profile and in edit mode
        ),
      ],
    );
  }

  Widget _buildFriendshipButton(BuildContext context) {
    if (!isViewingOwnProfile) {
      if (userDetails.isFriend == 0) {
        return Row(
          children: [
            // ElevatedButton.icon(
            //   onPressed: () {
            //     _sendFriendRequest();
            //   },
            //   icon: const Icon(Icons.person_add),
            //   label: const Text('Send Friend Request'),
            // ),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // TODO: Implement friend request logic
            //     // Fluttertoast.showToast(
            //     //   msg: "Friend request sent (logic pending)",
            //     //   toastLength: Toast.LENGTH_SHORT,
            //     // );
            //     _sendFriendRequest();
            //   },
            //   icon: Icon(Icons.person_add, color: Colors.white),
            //   label: Text("Send Friend Request"),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Theme.of(context).primaryColor,
            //     foregroundColor: Colors.white,
            //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //     textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            //   ),
            // ),
            ElevatedButton.icon(
              onPressed: _isSendingRequest || _requestSent
                  ? null
                  : () => _sendFriendRequest(),
              icon: _isSendingRequest
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.person_add, color: Colors.white),
              label: Text(
                _requestSent ? "Friend Request Sent" : "Send Friend Request",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      } else if (userDetails.isFriend == 1) {
        return const Align(
          alignment: Alignment.topLeft,
          child: Text(
            'You are already friends',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _sendFriendRequest() async {
    final RESTUtil _apiUtil = RESTUtil(
      baseUrl: AppConstants.URL_FRIENDS_REQUEST,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    setState(() => _isSendingRequest = true);

    final payload = [
      {
        "friend": {
          "mDisplayName": userDetails.fullName ?? '',
          "mPhone": userDetails.phoneNumber.replaceAll(' ', ''),
        },
        "requesting_user_full_name": '', // Can pass current user's name
        "referrerID": widget.currentUserId,
        "expertise": [],
        "send_notification": true
      }
    ];

    CommonHelper.logDebug(json.encode(payload));

    try {
      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": json.encode(payload),
      });

      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        setState(() {
          _requestSent = true;
          _isSendingRequest = false;
        });

        Fluttertoast.showToast(
          msg: "Friend request sent!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        throw Exception(responseData['error_msg'] ?? "Unknown error");
      }
    } catch (e) {
      setState(() => _isSendingRequest = false);

      Fluttertoast.showToast(
        msg: "Failed to send request. Try again.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // This method handles navigation to Expertise Management page and updates the expertise list after returning
  Future<void> _navigateToExpertiseManagement() async {
    final updatedExpertise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpertiseManagementPage(
          userId: widget.userId,
          initialSelectedExpertise: userExpertise,
        ),
      ),
    );

    // If the user updates the expertise, reload the expertise area
    if (updatedExpertise != null) {
      setState(() {
        userExpertise = updatedExpertise;
      });
    }
  }

  Future<void> _navigateToSuggestedExpertiseManagement() async {
    final updatedSuggestedExpertise = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SuggestedExpertiseManagementPage(
          userId: widget.userId,
          // referrerId: widget.currentUserId,
          initialSelectedExpertise: suggestedExpertise,
        ),
      ),
    );

    // If the user updates the suggested expertise, reload the suggested expertise area
    if (updatedSuggestedExpertise != null) {
      setState(() {
        suggestedExpertise = updatedSuggestedExpertise;
      });
    }
  }

  // void _sendFriendRequest() {
  //       var list = [{
  //     "friend": {
  //   "mDisplayName": userDetails.fullName ?? '',
  //   "mPhone": userDetails.phoneNumber,
  //   },
  //   "requesting_user_full_name": '',
  //   "referrerID": widget.currentUserId,
  //   "expertise": [],
  //   "send_notification":true
  // }];
  //   CommonHelper.logDebug(json.encode(list));
  // }
}
