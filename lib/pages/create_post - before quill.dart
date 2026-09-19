// import 'dart:convert';
//
// import 'package:Apviser/CommonHelper.dart';
// import 'package:Apviser/widgets/app_bar.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../AppConstants.dart';
// import '../DatabaseHelper.dart';
// import '../colours.dart';
// import '../models/UserDTO.dart';
// import '../models/PostsDTO.dart';
// import '../rest_util.dart';
// // import '../widgets/multiselect_dropdown.dart';
// // Assuming AppConstants has the user photo path
// import 'package:image_cropper/image_cropper.dart';
// import 'package:image/image.dart' as img;
//
// import '../widgets/select_expertise2.dart';
// import 'custom_poll_options.dart';
// import 'package:http/http.dart' as http;
//
// class CreatePost extends StatefulWidget {
//   final String questionType;
//   final TabController? tabController;
//   final PostDTO? postData;
//   final int postID;
//   final int userID;
//
//   CreatePost(
//       {this.questionType = "",
//       this.tabController,
//       this.postData,
//       this.postID = 0,
//       this.userID = 0});
//
//   @override
//   _CreatePostState createState() => _CreatePostState();
// }
//
// class _CreatePostState extends State<CreatePost> {
//   Uint8List? _postImage;
//   final TextEditingController _questionController = TextEditingController();
//   File? _selectedImage; // To store the image file
//
//   List<ValueItem<String>> selectedExpertise = [];
//   // List<String> newExpertiseList = [];
//   bool _showError = false;
//   bool _showExpertiseError = false;
//   UserDTO? user; // Declare the user at the class level
//   final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
//
//   // Simulating current user info from Hive or another source
//   String userName = ""; // Replace with actual user data
//   String imageName = ""; // Replace with actual user data
//   String userPhoto =
//       "${AppConstants.APVISER_IMAGES_PATH_FULL}user_photo.png"; // Replace with actual user photo
//   // UserDTO? user = await _dbHelper.getCurrentUser("cuser");
//   // List<ValueItem<String>> selectedExpertise = [];
//   bool _isLoading = true;
//   bool _isSubmitting = false;
//
//   String _postVisibility = "public"; // Default: Public visibility
//   int _postDuration = 2000; // Default: 7 days
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeUser();
//     if (widget.postID > 0) {
//       _fetchPostDetails(widget.postID,
//           widget.userID); // Fetch post details if we are in edit mode
//     } else {
//       _isLoading = false;
//       _initializeForEdit();
//     }
//   }
//
//   void _initializeForEdit() {
//     if (widget.postData != null) {
//       _questionController.text = widget.postData!.descr!;
//       if (widget.postData!.postImage != null) {
//         _postImage = base64Decode(widget.postData!.postImage!);
//       }
//     }
//   }
//
//   Future<void> _fetchPostDetails(int postID, int userID) async {
//     try {
//       final restUtil = RESTUtil(
//         baseUrl: AppConstants.ANSWERS_DETAILS_BY_QUESTION,
//         username: AppConstants.CREDENTIALS_USERNAME,
//         password: AppConstants.CREDENTIALS_PASSWORD,
//       );
//
//       final Map<String, dynamic> payload = {
//         'question_id': postID ?? '',
//         'user_id': userID,
//       };
//
//       print("_fetchPostDetails payload ${payload.toString()}");
//
//       final response = await restUtil
//           .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//         if (responseData.isNotEmpty) {
//           var postDetails = responseData[0];
//           _populateFields(postDetails);
//         }
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to load post details",
//           backgroundColor: Colors.red,
//         );
//       }
//     } catch (e) {
//       print("Error fetching post details: $e");
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _populateFields(Map<String, dynamic> postDetails) {
//     _questionController.text = postDetails['descr'] ?? '';
//     if (postDetails['post_image'] != null && postDetails['post_image'] != "") {
//       print(postDetails['post_image']);
//       //_postImage = base64Decode(AppConstants.APVISER_IMAGES_PATH_FULL+postDetails['post_image']);
//       String imageUrl =
//           "${AppConstants.APVISER_IMAGES_PATH_FULL}${postDetails['post_image']}";
//       downloadImageAsBase64(imageUrl);
//     }
//     selectedExpertise = (postDetails['expertise_details'] as List)
//         .map((expertise) => ValueItem<String>.fromJson(expertise))
//         .toList();
//     print("selected expertise are $selectedExpertise");
//
//     userName = postDetails['user_full_name'];
//     imageName = postDetails['post_image'];
//   }
//
//   Future<void> downloadImageAsBase64(String imageUrl) async {
//     try {
//       final response = await http.get(Uri.parse(imageUrl));
//
//       if (response.statusCode == 200) {
//         setState(() {
//           _postImage = response.bodyBytes; // Store image bytes as Uint8List
//         });
//       } else {
//         print("Error downloading image: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("Error: $e");
//     }
//   }
//
//   Future<void> _initializeUser() async {
//     user = await _dbHelper.getCurrentUser("cuser"); // Get user from database
//     print("cuser id is ${user?.userID}");
//     userPhoto =
//         "${AppConstants.APVISER_IMAGES_PATH_FULL + user!.photo}"; // Replace with actual user photo
//     setState(() {}); // Call setState to update the UI if needed
//   }
//
//   // Future<void> _selectImage() async {
//   //   final picker = ImagePicker();
//   //   final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//   //
//   //   if (pickedFile != null) {
//   //     setState(() {
//   //       _selectedImage = File(pickedFile.path);
//   //     });
//   //   }
//   // }
//
//   /*void _onExpertiseSelected(List<ValueItem<String>> expertise) {
//     setState(() {
//       selectedExpertise = expertise;
//       _showExpertiseError = selectedExpertise.isEmpty;
//     });
//   }*/
// /*
//   Future<void> _submitQuestion() async {
//     // Validation
//     if (_questionController.text.isEmpty) {
//       setState(() => _showError = true);
//       return;
//     }
//
//     if (selectedExpertise.isEmpty) {
//       setState(() => _showExpertiseError = true);
//       return;
//     }
//
//     // Prepare data
//     String base64Image = _postImage != null ? base64Encode(_postImage!) : '';
//     String description = _questionController.text;
//     final List<int> expertiseIds = selectedExpertise.map((option) => option.value.toInt()).toList();
//     Map<String, dynamic> requestData = {
//       "userID": user!.userID, // Replace with the actual user ID
//       "expertise": expertiseIds,
//       "new_expertise": [],
//       "description": description,
//       "post_image": base64Image,
//       "type": widget.postID > 0 ? widget.postData?.type : AppConstants.getPollType(widget.questionType),
//       "options": [],
//       //"question_id": widget.postID,
//       if (widget.postID > 0) "question_id": widget.postID,
//       "image_name": imageName, // Add question_id conditionally
//     };
//
//     // print("requestData is ${widget.postData?.type} -- ${widget.postID}");
//     // print("requestData is ${requestData.toString()}");
//     // return;
//     if (AppConstants.getPollType(widget.questionType) == 3 || widget.postData?.type == 3) {
//       // If it's a custom poll, navigate to options screen instead of sending the request
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => CustomPollOptionsScreen(userID: user!.userID, description: description, expertise: expertiseIds, base64Image: base64Image, postData: widget.postData,)),
//       );
//     } else {
//       // print(requestData);
//       // Send the request for normal, answer, or handshake type polls
//       _createPost(requestData);
//
//     }
//   }
// */
//   Future<void> _submitQuestion() async {
//     if (_isSubmitting) return; // Prevent duplicate submissions
//
//     setState(() => _isSubmitting = true); // Disable form interaction
//
//     // Validation
//     if (_questionController.text.isEmpty) {
//       setState(() {
//         _showError = true;
//         _isSubmitting = false; // Re-enable form interaction
//       });
//       return;
//     }
//
//     if (selectedExpertise.isEmpty) {
//       setState(() {
//         _showExpertiseError = true;
//         _isSubmitting = false; // Re-enable form interaction
//       });
//       return;
//     }
//
//     // Prepare data
//     String base64Image = _postImage != null ? base64Encode(_postImage!) : '';
//     int hasImage = base64Image.isNotEmpty ? 1 : 0;
//     String description = _questionController.text;
//     final List<int> expertiseIds =
//         selectedExpertise.map((option) => option.value.toInt()).toList();
//
//     final List<String> newExpertiseList = selectedExpertise
//         .where((expertise) => expertise.value == -1) // Filter newly added expertise
//         .map((expertise) => expertise.label) // Extract the label (name)
//         .toList();
//
//     Map<String, dynamic> requestData = {
//       "userID": user!.userID,
//       "expertise": expertiseIds,
//       "new_expertise": newExpertiseList,
//       "description": description,
//       "post_image": base64Image,
//       "type": widget.postID > 0
//           ? widget.postData?.type
//           : AppConstants.getPollType(widget.questionType),
//       "options": [],
//       if (widget.postID > 0) "question_id": widget.postID,
//       "image_name": imageName,
//       "contains_image": hasImage,
//       "expiry_in_days": _postDuration == 2000 ? -1 : _postDuration,
//       "post_visibility": (_postVisibility == "public" ? 0 : 1),
//     };
//     // print(requestData);
//     // return;
//     if (AppConstants.getPollType(widget.questionType) == 3 ||
//         widget.postData?.type == 3) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CustomPollOptionsScreen(
//             userID: user!.userID,
//             description: description,
//             expertise: expertiseIds,
//             newExpertiseList: newExpertiseList,
//             hasImage: hasImage,
//             postDuration: _postDuration == 2000 ? -1 : _postDuration,
//             postVisibility: (_postVisibility == "public" ? 0 : 1),
//             base64Image: base64Image,
//             postData: widget.postData,
//           ),
//         ),
//       );
//       setState(() => _isSubmitting = false); // Re-enable form interaction
//     } else {
//       await _createPost(requestData); // Submit post
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double fieldWidth = MediaQuery.of(context).size.width * 0.9; // Adjust width dynamically
//
//     return Scaffold(
//       appBar:
//       CustomAppBar(title: 'Create ${widget.questionType}', actions: [
//             // IconButton(
//             //   icon: Icon(
//             //     widget.postID > 0
//             //         ? (widget.postData?.type == 3
//             //         ? Icons.navigate_next // Existing "Custom Poll" goes to the next screen
//             //         : Icons.update) // Other types are updated
//             //         : (AppConstants.getPollType(widget.questionType) == 3
//             //         ? Icons.navigate_next // New "Custom Poll" goes to the next screen
//             //         : Icons.check), // New questions of other types are created
//             //   ),
//             //   color: AppColors.secondary, // Icon color to match the theme
//             //   onPressed: _isSubmitting ? null : _submitQuestion, // Disable during submission
//             // )
//
//         // Visibility Drawer Button (☰)
//         IconButton(
//           icon: Icon(Icons.visibility, color: AppColors.secondary),
//           onPressed: _showPostVisibilityDrawer,
//         ),
//
//         // Duration Picker Button (⏳)
//         IconButton(
//           icon: Icon(Icons.timer, color: AppColors.secondary),
//           onPressed: _showDurationPicker,
//         ),
//
//         // Submit Button (✔ or ➡️)
//         IconButton(
//           icon: Icon(
//             widget.postID > 0
//                 ? (widget.postData?.type == 3
//                 ? Icons.navigate_next
//                 : Icons.update)
//                 : (AppConstants.getPollType(widget.questionType) == 3
//                 ? Icons.navigate_next
//                 : Icons.check),
//           ),
//           color: AppColors.secondary,
//           onPressed: _isSubmitting ? null : _submitQuestion,
//         ),
//
//       ], showBackButton: true,),
//       // AppBar(
//       //   title: Text(
//       //     'Create ${widget.questionType}',
//       //     style: TextStyle(
//       //       color: Colors.white, // Change font color
//       //       fontSize: 18, // Adjust font size if needed
//       //       fontWeight: FontWeight.bold, // Optional: make it bold
//       //     ),
//       //   ),
//       //   backgroundColor: AppColors.primary, // Change AppBar background color
//       //   iconTheme: IconThemeData(color: Colors.white), // Change icons color
//       //   actions: [
//       //     IconButton(
//       //       icon: Icon(
//       //         widget.postID > 0
//       //             ? (widget.postData?.type == 3
//       //             ? Icons.navigate_next // Existing "Custom Poll" goes to the next screen
//       //             : Icons.update) // Other types are updated
//       //             : (AppConstants.getPollType(widget.questionType) == 3
//       //             ? Icons.navigate_next // New "Custom Poll" goes to the next screen
//       //             : Icons.check), // New questions of other types are created
//       //       ),
//       //       color: AppColors.secondary, // Icon color to match the theme
//       //       onPressed: _isSubmitting ? null : _submitQuestion, // Disable during submission
//       //     )
//       //   ],
//       // ),
//       // AppBar(
//       //   automaticallyImplyLeading: false, // Prevent default layout issues
//       //   flexibleSpace: Center(
//       //     child: Container(
//       //       color: AppColors.primary, // Set AppBar background color
//       //       child: ConstrainedBox(
//       //         constraints: BoxConstraints(
//       //           maxWidth: AppConstants.APP_MAX_WIDTH, // Limit AppBar width
//       //         ),
//       //         child: Padding(
//       //           padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add left & right padding
//       //           child: Row(
//       //             children: [
//       //               BackButton(color: AppColors.secondary), // Back button color
//       //               Expanded(
//       //                 child: Text(
//       //                   'Create ${widget.questionType}', // Title dynamically based on question type
//       //                   style: TextStyle(
//       //                     fontSize: 16,
//       //                     color: AppColors.secondary, // Text color
//       //                   ),
//       //                   overflow: TextOverflow.ellipsis, // Handle long titles gracefully
//       //                 ),
//       //               ),
//       //               IconButton(
//       //                 icon: Icon(
//       //                   widget.postID > 0
//       //                       ? (widget.postData?.type == 3
//       //                       ? Icons.navigate_next // Existing "Custom Poll" goes to the next screen
//       //                       : Icons.update) // Other types are updated
//       //                       : (AppConstants.getPollType(widget.questionType) == 3
//       //                       ? Icons.navigate_next // New "Custom Poll" goes to the next screen
//       //                       : Icons.check), // New questions of other types are created
//       //                 ),
//       //                 color: AppColors.secondary, // Icon color to match the theme
//       //                 onPressed: _isSubmitting ? null : _submitQuestion, // Disable during submission
//       //               ),
//       //             ],
//       //           ),
//       //         ),
//       //       ),
//       //     ),
//       //   ),
//       //   backgroundColor: Colors.transparent, // Prevent default full-width background
//       //   elevation: 0, // Remove default AppBar shadow
//       // ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Stack(
//         children: [
//           SingleChildScrollView(
//             child: Center(
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   maxWidth: AppConstants.APP_MAX_WIDTH, // Set predefined width
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.only(left: 16.0, right: 16.0), // Add left & right padding
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
//                     mainAxisSize: MainAxisSize.min, // Minimize vertical space
//                     children: [
//                       // User Info Row
//                       Row(
//                         children: [
//                           CircleAvatar(
//                             backgroundImage: NetworkImage(userPhoto),
//                             radius: 30.0,
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             userName,
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 16.0),
//
//                       // Question Text Area
//                       SizedBox(
//                         width: fieldWidth,
//                         child: TextField(
//                           controller: _questionController,
//                           maxLines: 5,
//                           decoration: InputDecoration(
//                             labelText: "What's on your mind?",
//                             errorText: _showError ? 'Question is required' : null,
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 16.0),
//
//                       // Image Upload Section
//                       Center(
//                         child: GestureDetector(
//                           onTap: _pickImage,
//                           child: Container(
//                             width: 400,
//                             height: 200,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[200],
//                               image: _postImage != null
//                                   ? DecorationImage(
//                                 image: MemoryImage(_postImage!),
//                                 fit: BoxFit.cover,
//                               )
//                                   : null,
//                             ),
//                             child: _postImage == null
//                                 ? Icon(
//                               Icons.camera_alt,
//                               size: 50,
//                               color: Colors.grey[800],
//                             )
//                                 : null,
//                           ),
//                         ),
//                       ),
//
//                       if (_postImage != null)
//                         Column(
//                           children: [
//                             SizedBox(height: 10),
//                             Center(
//                               child: ElevatedButton.icon(
//                                 onPressed: _removeImage,
//                                 icon: Icon(Icons.delete, color: Colors.white),
//                                 label: Text('Remove Image'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.red,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(height: 16.0),
//                           ],
//                         ),
//
//                       // Expertise Selection with Padding
//                       SizedBox(
//                         width: fieldWidth,
//                         child: AbsorbPointer(
//                           absorbing: _isSubmitting, // Disable interaction when form is submitting
//                           child: SelectExpertiseWidget2(
//                             userId: user!.userID,
//                             initialSelectedOptions: selectedExpertise,
//                             isEditable: true,
//                             labelText: "Tag Relevant Expertise",
//                             onSelectionChanged: (options) {
//                               setState(() {
//                                 selectedExpertise = options;
//                               });
//                             },
//                           ),
//                         ),
//                       ),
//
//                       if (_showExpertiseError)
//                         Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Text(
//                             'Please select at least one expertise.',
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       SizedBox(height: 16.0),
//
//                       if (_selectedImage != null)
//                         SizedBox(
//                           width: fieldWidth,
//                           child: Container(
//                             height: 200,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               image: DecorationImage(
//                                 image: FileImage(_selectedImage!),
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//
//
// /*
//   Widget build(BuildContext context) {
//     final double fieldWidth = MediaQuery.of(context).size.width * 0.9; // Adjust the width here
//     //print("poll type is ${AppConstants.getPollType(widget.questionType)}");
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Create ${widget.questionType}'), // Show the type of question in the title
//         actions: [
//           IconButton(
//             icon: Icon(
//               widget.postID > 0
//                   ? (widget.postData?.type == 3
//                   ? Icons.navigate_next // Existing "Custom Poll" goes to the next screen
//                   : Icons.update)       // Other types are updated
//                   : (AppConstants.getPollType(widget.questionType) == 3
//                   ? Icons.navigate_next // New "Custom Poll" goes to the next screen
//                   : Icons.check
//               ),       // New questions of other types are created
//             ),
//             //onPressed: _submitQuestion,
//             onPressed: _isSubmitting ? null : _submitQuestion, // Disable during submission
//           ),
//         ],
//       ),
//       body:_isLoading
//           ? Center(child: CircularProgressIndicator())
//           :  SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center, // Align content centrally
//           children: [
//             // Current User Info
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start, // Align user info to the start
//               children: [
//                 CircleAvatar(
//                   backgroundImage: NetworkImage(userPhoto),
//                   radius: 30.0,
//                 ),
//                 SizedBox(width: 10),
//                 Text(
//                   userName,
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//
//
//             SizedBox(height: 16.0),
//
//             // Question Text Area
//             SizedBox(
//               width: fieldWidth, // Ensure the same width for description field
//               child: TextField(
//                 controller: _questionController,
//                 maxLines: 5,
//                 decoration: InputDecoration(
//                   labelText: 'Type your question here...',
//                   errorText: _showError ? 'Question is required' : null,
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16.0),
//
//             SizedBox(height: 16.0),
//
//             // Image Upload Section
//             Center(
//               child: GestureDetector(
//                 onTap: _pickImage,
//                 child: Container(
//                   width: 400, // Fit the screen width
//                   height: 200, // Make it a square
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200], // Background color
//                     image: _postImage != null
//                         ? DecorationImage(
//                       image: MemoryImage(_postImage!),
//                       fit: BoxFit.cover, // Ensure the image covers the area
//                     )
//                         : null,
//                   ),
//                   child: _postImage == null
//                       ? Icon(
//                     Icons.camera_alt,
//                     size: 50,
//                     color: Colors.grey[800],
//                   )
//                       : null,
//                 ),
//               ),
//             ),
//
//             if (_postImage != null) // Show remove button if image is uploaded
//               Column(
//                 children: [
//                   SizedBox(height: 10),
//                   ElevatedButton.icon(
//                     onPressed: _removeImage, // Remove image action
//                     icon: Icon(Icons.delete, color: Colors.white),
//                     label: Text('Remove Image'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red, // Red color for delete button
//                     ),
//                   ),
//                 ],
//               ),
//
//             // Expertise Selection with Padding
//             SizedBox(
//               width: fieldWidth, // Ensure the width matches other components
//               child:SelectExpertiseWidget2(
//                 userId: user!.userID,
//                 initialSelectedOptions: selectedExpertise,
//                 isEditable: true,
//                 onSelectionChanged: (options) {
//                   setState(() {
//                     selectedExpertise = options;
//                   });
//                 },
//               ),
//             ),
//             if (_showExpertiseError)
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   'Please select at least one expertise.',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             SizedBox(height: 16.0),
//
//             if (_selectedImage != null)
//               SizedBox(
//                 width: fieldWidth, // Match the width of the selected image preview
//                 child: Container(
//                   height: 200,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     image: DecorationImage(
//                       image: FileImage(_selectedImage!),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// */
//   void _removeImage() {
//     setState(() {
//       _postImage = null; // Remove the uploaded image
//     });
//   }
//
//   Future<void> _pickImage() async {
//     final ImagePicker _picker = ImagePicker();
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//
//     if (image != null) {
//       // Crop the image
//       CroppedFile? croppedFile = await ImageCropper().cropImage(
//         sourcePath: image.path,
//         uiSettings: [
//           AndroidUiSettings(
//             toolbarTitle: 'Crop Image',
//             toolbarColor: AppColors.primary,
//             toolbarWidgetColor: AppColors.secondary,
//             initAspectRatio: CropAspectRatioPreset.square,
//             lockAspectRatio: false,
//           ),
//           IOSUiSettings(
//             minimumAspectRatio: 1.0,
//           ),
//           WebUiSettings(
//             context: context,
//             presentStyle: WebPresentStyle.dialog,
//             size: const CropperSize(
//               height: 300,
//             ),
//           ),
//         ],
//       );
//
//       if (croppedFile != null) {
//         Uint8List croppedBytes = await croppedFile.readAsBytes();
//
//         // Decode the image to check its dimensions
//         final img.Image? decodedImage = img.decodeImage(croppedBytes);
//
//         if (decodedImage != null) {
//           // Resize the image only if necessary
//           Uint8List resizedBytes;
//           if (croppedBytes.lengthInBytes > 5 * 1024 * 1024) {
//             // Compress or resize the image to meet the size limit
//             final resizedImage = img.copyResize(decodedImage,
//                 width: 300); // Adjust dimensions as needed
//             resizedBytes = Uint8List.fromList(
//                 img.encodeJpg(resizedImage, quality: 85)); // Quality adjustment
//           } else {
//             // Use the original cropped image if under size limit
//             resizedBytes = croppedBytes;
//           }
//
//           // Update the state with the processed image
//           setState(() {
//             _postImage = resizedBytes;
//           });
//         } else {
//           Fluttertoast.showToast(
//             msg: "Failed to process the image. Please try again.",
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         }
//       }
//     } else {
//       Fluttertoast.showToast(
//         msg: "No image selected. Please try again.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//     }
//   }
//
//   Future<void> _createPost(Map<String, dynamic> payload) async {
//     try {
//       // Call the web service
//       final restUtil = RESTUtil(
//         baseUrl: widget.postID > 0
//             ? AppConstants.UPDATE_QUESTION
//             : AppConstants.ASK_FOR_REVIEW_NEW,
//         username: AppConstants.CREDENTIALS_USERNAME,
//         password: AppConstants.CREDENTIALS_PASSWORD,
//       );
//
//       final response = await restUtil
//           .postForm(restUtil.baseUrl, {'json': json.encode(payload)});
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//
//         if (responseData['error'] == false) {
//           // Determine the message based on whether it's a new post or an update
//           final actionMessage = widget.postID > 0 ? "updated" : "created";
//
//           // Fluttertoast.showToast(
//           //   msg: "Post $actionMessage successfully!",
//           //   toastLength: Toast.LENGTH_LONG, // Ensure the toast stays longer
//           //   gravity: ToastGravity.BOTTOM,
//           //   backgroundColor: Colors.green,
//           //   textColor: Colors.white,
//           //   fontSize: 16.0,
//           // );
//
//           CommonHelper.showMessage(
//               context, "Post $actionMessage successfully!", 5);
//           // ScaffoldMessenger.of(context).showSnackBar(
//           //   SnackBar(content: Text('Post $actionMessage successfully!')),
//           // );
//
//           if (widget.postID > 0) {
//             // updated
//             // Get the updated post from the response
//             final updatedPost =
//                 PostDTO.fromJson(responseData['updated_vote_info'][0]);
//             print("updated descr is ${updatedPost.descr}");
//             // Redirect user to "My Posts" tab after successful submission
//             widget.tabController?.index = 1; // Switch to the "My Posts" tab
//             Navigator.pop(context, updatedPost);
//           } else {
//             // created
//             // print("updated descr is ${updatedPost.descr}");
//             // Redirect user to "My Posts" tab after successful submission
//             // widget.tabController?.index = 1; // Switch to the "My Posts" tab
//             final updatedPost =
//                 PostDTO.fromJson(responseData['updated_vote_info'][0]);
//             //Navigator.pop(context);
//             Navigator.pop(context, updatedPost);
//             Navigator.pop(context, updatedPost);
//           }
//         } else if (responseData['error'] == true &&
//             responseData['error_msg'].contains(
//                 "there is no one in your friends list with the mentioned expertise")) {
//           // Fluttertoast.showToast(
//           //   msg: responseData['error_msg'],
//           //   toastLength: Toast.LENGTH_SHORT,
//           //   gravity: ToastGravity.BOTTOM,
//           //   backgroundColor: Colors.red,
//           //   textColor: Colors.white,
//           //   fontSize: 16.0,
//           // );
//           final updatedPost = PostDTO.fromJson(responseData['updated_vote_info'][0]);
//           CommonHelper.showMessage(context, responseData['error_msg'], 5);
//           Navigator.pop(context, updatedPost); // Close the bottom drawer
//           Navigator.pop(context, updatedPost); // Close the bottom drawer
//         } else {
//           Fluttertoast.showToast(
//             msg: "Failed to ${widget.postID > 0 ? "update" : "create"} post.",
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//         }
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to reach the server. Please try again.",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//       }
//     } catch (e) {
//       print("Failed to ${widget.postID > 0 ? "update" : "create"} post: $e");
//       Fluttertoast.showToast(
//         msg: "An error occurred. Please try again.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//     } finally {
//       setState(() => _isSubmitting = false); // Re-enable form interaction
//     }
//   }
//
// /*
//   Future<void> _createPost_GPT_Test(Map<String, dynamic> payload) async {
//     try {
//       // Call the web service
//       final restUtil = RESTUtil(
//         baseUrl: widget.postID > 0 ? AppConstants.UPDATE_QUESTION : AppConstants.ASK_FOR_REVIEW,
//         username: AppConstants.CREDENTIALS_USERNAME,
//         password: AppConstants.CREDENTIALS_PASSWORD,
//       );
//
//       final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});
//
//       if (response.statusCode == 200) {
//         final responseData = json.decode(response.body);
//
//         if (responseData['error'] == false) {
//           // Determine the message based on whether it's a new post or an update
//           final actionMessage = widget.postID > 0 ? "updated" : "created";
//
//           Fluttertoast.showToast(
//             msg: "Post $actionMessage successfully!",
//             toastLength: Toast.LENGTH_LONG, // Ensure the toast stays longer
//             gravity: ToastGravity.BOTTOM,
//             backgroundColor: Colors.green,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//
//           if (widget.postID > 0) {
//             // Updated post
//             final updatedPost = PostDTO.fromJson(responseData['updated_vote_info'][0]);
//             widget.tabController?.index = 0; // Switch to Posts tab
//           } else {
//             // New post
//             widget.tabController?.index = 0; // Switch to Posts tab
//           }
//
//           Navigator.pop(context); // Go back to the main screen
//         } else {
//           _showErrorToast(responseData['error_msg'] ?? "Failed to create post.");
//         }
//       } else {
//         _showErrorToast("Failed to reach the server. Please try again.");
//       }
//     } catch (e) {
//       _showErrorToast("An error occurred. Please try again.");
//     } finally {
//       setState(() => _isSubmitting = false); // Re-enable form interaction
//     }
//   }
// */
//   // void _showErrorToast(String message) {
//   //   Fluttertoast.showToast(
//   //     msg: message,
//   //     toastLength: Toast.LENGTH_LONG,
//   //     gravity: ToastGravity.BOTTOM,
//   //     backgroundColor: Colors.red,
//   //     textColor: Colors.white,
//   //     fontSize: 16.0,
//   //   );
//   // }
//
//   // void _showVisibilityDrawer() {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [
//   //           ListTile(
//   //             leading: Icon(Icons.public),
//   //             title: Text("Public"),
//   //             trailing: _postVisibility == "public" ? Icon(Icons.check, color: AppColors.primary) : null,
//   //             onTap: () {
//   //               setState(() {
//   //                 _postVisibility = "public";
//   //               });
//   //               Navigator.pop(context);
//   //             },
//   //           ),
//   //           ListTile(
//   //             leading: Icon(Icons.group),
//   //             title: Text("Contacts"),
//   //             trailing: _postVisibility == "contacts" ? Icon(Icons.check, color: AppColors.primary) : null,
//   //             onTap: () {
//   //               setState(() {
//   //                 _postVisibility = "contacts";
//   //               });
//   //               Navigator.pop(context);
//   //             },
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }
//   void _showPostVisibilityDrawer() {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,  // Align heading to the left
//             children: [
//               // 🔹 Heading
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Text(
//                   "Who can see your post",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//
//               // 🔹 Visibility Options
//               ListTile(
//                 leading: Icon(Icons.public, color: Colors.blue),  // 🌍 Public icon
//                 title: Text("Public (Visible to all relevant experts)"),
//                 trailing: _postVisibility == "public"
//                     ? Icon(Icons.check, color: AppColors.primary)
//                     : null,
//                 onTap: () {
//                   setState(() => _postVisibility = "public");
//                   Navigator.pop(context);
//                 },
//               ),
//               ListTile(
//                 leading: Icon(Icons.group, color: Colors.green),  // 👥 Contacts-only icon
//                 title: Text("Direct Friends Only"),
//                 trailing: _postVisibility == "contacts"
//                     ? Icon(Icons.check, color: AppColors.primary)
//                     : null,
//                 onTap: () {
//                   setState(() => _postVisibility = "contacts");
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//
//   // void _showDurationPicker() {
//   //   showModalBottomSheet(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return Column(
//   //         mainAxisSize: MainAxisSize.min,
//   //         children: [1, 3, 7, 30, "Never"].map((dynamic days) {
//   //           int duration = (days is int) ? days : 2000; // Convert "Never" to 2000
//   //
//   //           return ListTile(
//   //             leading: Icon(Icons.timer),
//   //             title: Text(days == "Never" ? "Never" : "$days days"), // Handle "Never"
//   //             trailing: _postDuration == duration
//   //                 ? Icon(Icons.check, color: AppColors.primary)
//   //                 : null,
//   //             onTap: () {
//   //               setState(() {
//   //                 _postDuration = duration; // Ensure it stores only int
//   //               });
//   //               Navigator.pop(context);
//   //             },
//   //           );
//   //         }).toList(),
//   //       );
//   //     },
//   //   );
//   // }
//   void _showDurationPicker() {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) {
//         return Container(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,  // Align heading to the left
//             children: [
//               // 🔹 Heading
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 8.0),
//                 child: Text(
//                   "Allow Interaction For",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//
//               // Duration Options
//               ...[1, 3, 7, 30, "No Limit"].map((dynamic days) {
//                 int duration = (days is int) ? days : 2000; // Convert "Never" to 2000
//
//                 return ListTile(
//                   leading: Icon(
//                     days == "No Limit" ? Icons.timer_off : Icons.timer,  // ⏳ Timer for days, ⏰ Off for Never
//                     color: days == "Never" ? Colors.red : Colors.blue,
//                   ),
//                   title: Text(days == "No Limit" ? "No Limit (No expiration)" : "$days days"), // Handle "Never"
//                   trailing: _postDuration == duration
//                       ? Icon(Icons.check, color: AppColors.primary)
//                       : null,
//                   onTap: () {
//                     setState(() {
//                       _postDuration = duration; // Ensure it stores only int
//                     });
//                     Navigator.pop(context);
//                   },
//                 );
//               }).toList(),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//
// }
