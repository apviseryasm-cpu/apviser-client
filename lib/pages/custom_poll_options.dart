import 'dart:convert';

import 'package:Apviser/colours.dart';
import 'package:Apviser/models/PostsDTO.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';

import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../rest_util.dart';
// import 'package:your_project/rest_util.dart'; // Update with your actual RESTUtil import
// import 'package:your_project/constants/app_constants.dart'; // Update with your actual AppConstants import

class CustomPollOptionsScreen extends StatefulWidget {
  final String description, base64Image; // Passed from the previous screen
  final List<int?> expertise; // Expertise passed from the previous screen
  final int userID; // Expertise passed from the previous screen
  List<String?> newExpertiseList;
  int hasImage;
  int postDuration;
  int postVisibility;
  TabController? tabController;
  PostDTO? postData;

  CustomPollOptionsScreen({
    required this.userID,
    required this.description,
    required this.expertise,
    required this.base64Image,
    this.tabController,
    this.postData,
    required this.newExpertiseList,
    required this.hasImage,
    required this.postDuration,
    required this.postVisibility,
  });

  @override
  _CustomPollOptionsScreenState createState() => _CustomPollOptionsScreenState();
}

class _CustomPollOptionsScreenState extends State<CustomPollOptionsScreen> {
  // Default visible fields count is 2, max allowed is 5
  int _visibleFields = 2;

  // Create text controllers for options
  List<TextEditingController> optionControllers = [];
  bool _showError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // Initialize option controllers based on PostDTO.options
    optionControllers = widget.postData?.options?.map((option) {
      return TextEditingController(text: option.option);
    }).toList() ??
        [];

    // Ensure at least two controllers are available
    while (optionControllers.length < 2) {
      optionControllers.add(TextEditingController());
    }

    // Set visible fields to match the number of options
    _visibleFields = optionControllers.length;
  }

  // Method to add more fields
  void _addField() {
    if (_visibleFields < 5) {
      setState(() {
        _visibleFields += 1;
        if (_visibleFields > optionControllers.length) {
          optionControllers.add(TextEditingController());
        }
      });
    }
  }

  // Method to remove a field
  void _removeField(int index) {
    if (_visibleFields > 2) {
      setState(() {
        optionControllers.removeAt(index);
        _visibleFields -= 1;
      });
    }
  }

  Future<void> _submitPollOptions() async {
    try {
      if (_isSubmitting) return; // Prevent duplicate submissions

      setState(() => _isSubmitting = true); // Disable form interaction

      // Collect visible options and validate
      List<String> options = [];
      for (int i = 0; i < _visibleFields; i++) {
        if (optionControllers[i].text.isEmpty) {
          setState(() {
            _showError = true;
            _isSubmitting = false; // Re-enable form interaction
          });
          return; // Exit early if any visible field is empty
        }
        options.add(optionControllers[i].text);
      }

      setState(() {
        _showError = false;
        _isSubmitting = true; // Re-enable form interaction
      });
      // if (widget.postData!.id! > 0){
      //   print(widget.postData?.id);
      // }
      // Prepare payload for the web service call
      final Map<String, dynamic> payload = {
        "userID": widget.userID,
        "expertise": widget.expertise, // Expertise from previous screen
        "description": widget.description, // Description from previous screen
        "type": 3, // Type for custom poll
        "new_expertise": [], // Assuming no new expertise is added
        "post_image": widget.base64Image, // Assuming no image for now
        "options": options,
        if (widget.postData != null && widget.postData!.id! > 0)
          "question_id": widget.postData!.id,
        if (widget.postData != null)
          "image_name": widget.postData!.postImage, // Only add if postData is not null
        "new_expertise": widget.newExpertiseList,
        "contains_image": widget.hasImage,
        "expiry_in_days": widget.postDuration,
        "post_visibility": widget.postVisibility,
      };

      // Call the web service
      final restUtil = RESTUtil(
        baseUrl: (widget.postData != null && widget.postData!.id! > 0)
            ? AppConstants.UPDATE_QUESTION
            : AppConstants.ASK_FOR_REVIEW_NEW,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});
      // print("response is $response")
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Check if the like action was successful and update the comment state
        if (responseData['error'] == false) {
          Fluttertoast.showToast(
            msg: "Post submitted successfully!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          // Get the updated post from the response
          final updatedPost = PostDTO.fromJson(responseData['updated_vote_info'][0]);
          CommonHelper.logDebug("updated descr is ${updatedPost.descr}");
          // Redirect user to "My Posts" tab after successful submission
          widget.tabController?.index = 1; // Switch to the "My Posts" tab
          Navigator.pop(context, updatedPost);
          Navigator.pop(context, updatedPost);

          // Redirect user to "My Posts" tab after successful submission
          // widget.tabController.index = 1; // Switch to the "My Posts" tab

          // Navigator.pop(context);
          // Close the bottom drawer
          // Navigator.of(context).pop(); // Close the bottom drawer only
          // Navigator.pop(context);

        }else if(responseData['error'] == true && responseData['error_msg'].contains("there is no one in your friends list with the mentioned expertise")){
          Fluttertoast.showToast(
            msg: responseData['error_msg'],
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
          final updatedPost = PostDTO.fromJson(responseData['updated_vote_info'][0]);
          CommonHelper.logDebug("updated descr is ${updatedPost.descr}");
          Navigator.pop(context, updatedPost);
          Navigator.pop(context, updatedPost);
        }else{
          Fluttertoast.showToast(
            msg: "Failed to submit post",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to submit post",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      CommonHelper.logDebug("Failed to submit post: $e");
      //return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(title: "Create Custom Poll", showBackButton: true, actions: [
            IconButton(
              icon: Icon(Icons.check, color: AppColors.secondary,),
              onPressed: _isSubmitting ? null : _submitPollOptions,
            ),
      ],),
      // AppBar(
      //   title: Text('Create Custom Poll'),
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.check),
      //       onPressed: _isSubmitting ? null : _submitPollOptions,
      //     ),
      //   ],
      // ),
      body:
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamically add TextFields for options
                for (int i = 0; i < _visibleFields; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        // Expanded TextField to take full width except for the Remove button
                        Expanded(
                          child: TextField(
                            controller: optionControllers[i],
                            decoration: InputDecoration(
                              labelText: 'Option ${i + 1}',
                              border: OutlineInputBorder(),
                              errorText: _showError && optionControllers[i].text.isEmpty
                                  ? 'Option is required'
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        if (_visibleFields > 2) // Show the remove button if there are more than 2 fields
                          IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeField(i), // Remove field action
                          ),
                      ],
                    ),
                  ),

                // Show the Add button only if less than 5 fields are visible
                if (_visibleFields < 5)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addField,
                        icon: Icon(Icons.add, color: AppColors.secondary,),
                        label: Text('Add Option', style: TextStyle(color: AppColors.secondary), ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, // Set the primary color
                        ),
                      ),
                    ],
                  ),

                // Error message if any visible field is empty
                if (_showError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Please fill all options before submitting.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),

      // SingleChildScrollView(
      //   padding: const EdgeInsets.all(16.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       // Dynamically add TextFields for options
      //       for (int i = 0; i < _visibleFields; i++)
      //         Padding(
      //           padding: const EdgeInsets.only(bottom: 16.0),
      //           child: Row(
      //             children: [
      //               // Expanded TextField to take full width except for the Remove button
      //               Expanded(
      //                 child: TextField(
      //                   controller: optionControllers[i],
      //                   decoration: InputDecoration(
      //                     labelText: 'Option ${i + 1}',
      //                     border: OutlineInputBorder(),
      //                     errorText: _showError && optionControllers[i].text.isEmpty
      //                         ? 'Option is required'
      //                         : null,
      //                   ),
      //                 ),
      //               ),
      //               const SizedBox(width: 8.0),
      //               if (_visibleFields > 2) // Show the remove button if there are more than 2 fields
      //                 IconButton(
      //                   icon: Icon(Icons.remove_circle, color: Colors.red),
      //                   onPressed: () => _removeField(i), // Remove field action
      //                 ),
      //             ],
      //           ),
      //         ),
      //
      //       // Show the Add button only if less than 5 fields are visible
      //       if (_visibleFields < 5)
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.end,
      //           children: [
      //             ElevatedButton.icon(
      //               onPressed: _addField,
      //               icon: Icon(Icons.add),
      //               label: Text('Add Option'),
      //               style: ElevatedButton.styleFrom(
      //                 backgroundColor: Theme.of(context).primaryColor, // Set the primary color
      //               ),
      //             ),
      //           ],
      //         ),
      //
      //       // Error message if any visible field is empty
      //       if (_showError)
      //         Padding(
      //           padding: const EdgeInsets.only(top: 8.0),
      //           child: Text(
      //             'Please fill all options before submitting.',
      //             style: TextStyle(color: Colors.red),
      //           ),
      //         ),
      //     ],
      //   ),
      // ),
    );
  }
}
