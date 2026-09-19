import 'dart:convert';

import 'package:Apviser/CommonHelper.dart';
import 'package:Apviser/colours.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../AppConstants.dart'; // Replace with your constants class
import '../rest_util.dart';
import 'package:flutter/foundation.dart';

import '../widgets/select_expertise2.dart';

class ExpertiseManagementPage extends StatefulWidget {
  final int userId; // ID of the user whose expertise is being managed
  final List<ValueItem<String>> initialSelectedExpertise;

  const ExpertiseManagementPage({
    required this.userId,
    required this.initialSelectedExpertise,
    Key? key,
  }) : super(key: key);

  @override
  _ExpertiseManagementPageState createState() =>
      _ExpertiseManagementPageState();
}

class _ExpertiseManagementPageState extends State<ExpertiseManagementPage> {
  List<ValueItem<String>> selectedExpertise = [];
  bool _isLoading = false;
  bool _isExpertiseChanged = false; // Track whether the photo has been changed

  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.UPDATE_USER_EXPERTISE,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  @override
  void initState() {
    super.initState();
    selectedExpertise = widget.initialSelectedExpertise;
  }

  Future<void> _saveExpertise() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<int> expertiseIds =
          selectedExpertise.map((option) => option.value).toList();
      final jsonPayload = json.encode({
        "userID": widget.userId,
        "referrerID": widget.userId,
        "expertise": expertiseIds,
      });

      final response =
          await _apiUtil.postForm(_apiUtil.baseUrl, {"json": jsonPayload});
      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        _isExpertiseChanged = true;
        // Fluttertoast.showToast(
        //   msg: "Expertise updated successfully!",
        //   toastLength: Toast.LENGTH_LONG,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        // );
        CommonHelper.showMessage(context, "Expertise updated successfully!", 5);
        Navigator.pop(
            context, selectedExpertise); // Return updated expertise on success
      } else {
        // Fluttertoast.showToast(
        //   msg: "Failed to update expertise",
        //   toastLength: Toast.LENGTH_LONG,
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.red,
        //   textColor: Colors.white,
        // );
        CommonHelper.showMessage(context, "Failed to update expertise", 5);
      }
    } catch (e) {
      CommonHelper.logDebug("Error updating expertise: $e");
      // Fluttertoast.showToast(
      //   msg: "An error occurred. Please try again.",
      //   toastLength: Toast.LENGTH_LONG,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      // );
      CommonHelper.showMessage(
          context, "An error occurred. Please try again.", 5);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Manage Expertise",
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.cancel,
              color: AppColors.secondary,
            ),
            onPressed: () {
              Navigator.pop(context); // Cancel and go back without saving
            },
          ),
          IconButton(
            icon: Icon(Icons.save, color: AppColors.secondary),
            onPressed:
                _isLoading ? null : _saveExpertise, // Save expertise changes
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          :
      SingleChildScrollView( // Add this
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
              child: Column(
                children: [
                  SelectExpertiseWidget2(
                    userId: widget.userId,
                    initialSelectedOptions: selectedExpertise,
                    isEditable: true,
                    onSelectionChanged: (newSelectedOptions) {
                      setState(() {
                        selectedExpertise = newSelectedOptions;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Padding(
      //         padding: const EdgeInsets.all(16.0),
      //         child: Center(
      //           child: ConstrainedBox(
      //             constraints:
      //                 BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH), // ⬅️ Restrict width
      //             child: Column(
      //               children: [
      //                 Expanded(
      //                   child: SelectExpertiseWidget2(
      //                     userId: widget.userId,
      //                     initialSelectedOptions: selectedExpertise,
      //                     isEditable: true,
      //                     onSelectionChanged: (newSelectedOptions) {
      //                       setState(() {
      //                         selectedExpertise = newSelectedOptions;
      //                       });
      //                     },
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ),
      //       ),
    );
  }
}
