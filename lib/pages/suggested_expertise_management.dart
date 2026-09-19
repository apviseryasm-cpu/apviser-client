import 'dart:convert';

import 'package:Apviser/CommonHelper.dart';
import 'package:Apviser/colours.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../AppConstants.dart';  // Replace with your constants class
import '../DatabaseHelper.dart';
import '../models/UserDTO.dart';
import '../rest_util.dart';
import 'package:flutter/foundation.dart';

import '../widgets/select_expertise2.dart';


class SuggestedExpertiseManagementPage extends StatefulWidget {
  final int userId; // ID of the user whose expertise is being managed
  // final int referrerId; // ID of the user whose expertise is being managed
  final List<ValueItem<String>> initialSelectedExpertise;

  const SuggestedExpertiseManagementPage({
    required this.userId,
    required this.initialSelectedExpertise,
    // required this.referrerId,
    Key? key,
  }) : super(key: key);

  @override
  _SuggestedExpertiseManagementPageState createState() => _SuggestedExpertiseManagementPageState();
}

class _SuggestedExpertiseManagementPageState extends State<SuggestedExpertiseManagementPage> {
  List<ValueItem<String>> selectedExpertise = [];
  bool _isLoading = false;
  bool _isExpertiseChanged = false; // Track whether the photo has been changed
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  UserDTO? cuser;

  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.TAG_EXPERTISE_TO_USER,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  @override
  void initState() {
    super.initState();
    selectedExpertise = widget.initialSelectedExpertise; // Set expertise first
    _initializeUser(); // Fetch user separately
  }

  Future<void> _initializeUser() async {
    cuser = await _dbHelper.getCurrentUser("cuser");  // Get user from database
    if (mounted) setState(() {});  // Update the UI after fetching user
  }

  Future<void> _saveExpertise() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<int> expertiseIds = selectedExpertise.map((option) => option.value).toList();
      final List<String> newExpertiseList = selectedExpertise
          .where((expertise) => expertise.value == -1) // Filter newly added expertise
          .map((expertise) => expertise.label) // Extract the label (name)
          .toList();
      final jsonPayload = json.encode({
        "user_id": widget.userId,
        "my_id": cuser?.userID,
        "expertise": expertiseIds,
        "new_expertise": newExpertiseList,
      });
      CommonHelper.logDebug(jsonPayload);
      //return;
      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {"json": jsonPayload});
      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        _isExpertiseChanged = true;
        CommonHelper.showMessage(context, "Expertise tagged successfully!", 5);
        Navigator.pop(context, selectedExpertise); // Return updated expertise on success
      } else {
        CommonHelper.showMessage(context, "Failed to tag expertise", 5);
      }
    } catch (e) {
      CommonHelper.logDebug("Error updating expertise: $e");
      CommonHelper.showMessage(context, "An error occurred. Please try again.", 5);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
       CustomAppBar(title: "Tag Relevant Expertise", showBackButton: true, actions: [
             IconButton(
               icon: Icon(Icons.cancel, color: AppColors.secondary,),
               onPressed: () {
                 Navigator.pop(context); // Cancel and go back without saving
               },
             ),
             IconButton(
               icon: Icon(Icons.save, color: AppColors.secondary),
               onPressed: _isLoading ? null : _saveExpertise, // Save expertise changes
             ),
       ],),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SelectExpertiseWidget2(
                userId: widget.userId,
                initialSelectedOptions: selectedExpertise,
                isEditable: true,
                onSelectionChanged: (newSelectedOptions) {
                  setState(() {
                    selectedExpertise = newSelectedOptions;
                  });
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
