import 'dart:convert';
import 'package:Apviser/AppConstants.dart';
import 'package:flutter/material.dart';
import '../CommonHelper.dart';
import '../rest_util.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Add this import for toast messages
// import '../widgets/multiselect_dropdown.dart';
import '../widgets/app_bar.dart';
import '../widgets/select_expertise2.dart';
import 'error_screen.dart'; // Ensure this path is correct
// Ensure this path is correct
import 'userinfo.dart'; // Ensure this path is correct

class SelectExpertisePage extends StatefulWidget {
  //final String verificationId;
  final String phoneNumber;
  final int userID;
  //final String referrerID; // Add referrerID parameter

  SelectExpertisePage({required this.phoneNumber, required this.userID});

  @override
  _SelectExpertisePageState createState() => _SelectExpertisePageState();

}

class _SelectExpertisePageState extends State<SelectExpertisePage> {
  List<ValueItem<String>> selectedOptions = [];
  bool _showError = false;
  List<ValueItem<String>> userExpertise = [];

  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.UPDATE_USER_EXPERTISE,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  Future<void> _updateUserExpertise() async {
    CommonHelper.logDebug("inside _updateUserExpertise");
    if (selectedOptions.isEmpty) {
      setState(() {
        _showError = true;
      });
      return;
    }

    try {
      final List<int> expertiseIds = selectedOptions.map((option) => option.value.toInt()).toList();
      final jsonPayload = json.encode({
        "userID": widget.userID,
        "expertise": expertiseIds,
        "referrerID": widget.userID
      });

      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": jsonPayload,
      });

      final responseData = json.decode(response.body);
      if (responseData['error'] == false) {
        // Fluttertoast.showToast(
        //   msg: "Updated successfully!",
        //   toastLength: Toast.LENGTH_LONG,
        //   gravity: ToastGravity.BOTTOM,
        //   webPosition: "center",
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        //   fontSize: 16.0,
        // );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => UserInfoPage(phoneNumber: widget.phoneNumber),
          ),
              (route) => false,
        );
      } else {
        Fluttertoast.showToast(
          msg: "There was some problem",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
          webPosition: "center",
        );
      }
      CommonHelper.logDebug('Response: ${response.body}');
    } catch (e) {
      if (e is NoInternetException) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ErrorScreen(message: e.message),
        ));
      } else {
        CommonHelper.logDebug('Exception: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Select Expertise'),
      // ),
      appBar: CustomAppBar(title: "Select Expertise", showBackButton: false, actions: [],),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                width: 200, // Set desired width
                height: 50, // Set desired height
                child: ElevatedButton(
                  onPressed: _updateUserExpertise,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor, // Set the primary color
                      foregroundColor: Colors.white
                  ),
                  child: Text('NEXT'),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Center(
              child: Text(AppConstants.THINK_OF_5_PEOPLE),
            ),
            if (_showError)
              Center(child: Text(
                'Please select at least one option.',
                style: TextStyle(color: Colors.red),
              ), ),
            // Wrap(
            //   spacing: 8.0,
            //   runSpacing: 4.0,
            //   children: selectedOptions.map((option) => Chip(
            //     label: Text(option.label),
            //     backgroundColor: Theme.of(context).primaryColor,
            //     labelStyle: TextStyle(color: Colors.white), // Make text white for better contrast
            //     deleteIconColor: Colors.white, // Change the color of the delete icon
            //     onDeleted: () {
            //       setState(() {
            //         selectedOptions.remove(option);
            //       });
            //     },
            //   )).toList(),
            // ),
            SizedBox(height: 16.0),
            SelectExpertiseWidget2(
              userId: widget.userID,
              initialSelectedOptions: userExpertise,
              onSelectionChanged: (options) {
                setState(() {
                  selectedOptions = options;
                });
              },
              isEditable: true, // Allow editing only if viewing own profile and in edit mode
            ),

            // MultiSelectDropDown<String>(
            //   options: [
            //     ValueItem<String>(label: 'Cricket', value: 19),
            //     ValueItem<String>(label: 'Food', value: 2),
            //     ValueItem<String>(label: 'Travel', value: 3),
            //     ValueItem<String>(label: 'Medicine', value: 4),
            //     ValueItem<String>(label: 'Real Estate', value: 5),
            //     ValueItem<String>(label: 'Computer Networks', value: 6),
            //     ValueItem<String>(label: 'Music', value: 7),
            //   ],
            //   searchEnabled: true,
            //   searchLabel: 'Search Items',
            //   onOptionSelected: _onOptionSelected,
            // ),


            // ElevatedButton(
            //   onPressed: _showSelectedOptions,
            //   child: Text('Show Selected Options'),
            // ),
          ],
        ),
      ),
    );
  }
}
