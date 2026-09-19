import 'dart:convert';

import 'package:Apviser/CommonHelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Apviser/models/UserDTO.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../AppConstants.dart';
import '../DatabaseHelper.dart';
import '../colours.dart';
import '../rest_util.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

import '../widgets/app_bar.dart'; // Required for SystemUiOverlayStyle


class FullPhotoScreen extends StatefulWidget {
  final bool isCurrentUser;
  final int currentUserId;
  final String currentPhoto;
  final String? screenTitle;

  FullPhotoScreen({required this.isCurrentUser, required this.currentUserId, required this.currentPhoto, this.screenTitle});

  @override
  _FullPhotoScreenState createState() => _FullPhotoScreenState();
}

class _FullPhotoScreenState extends State<FullPhotoScreen> {
  // Uint8List? _currentImageBytes;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  Uint8List? _profileImage;
  String? _updatedPhotoUrl; // To hold the new photo URL after uploading
  bool _isPhotoChanged = false; // Track whether the photo has been changed
  // UserDTO? user;

  @override
  void initState() {
    super.initState();
    // _loadUserPhotoFromNetwork();  // Load photo when the screen initializes
    // user = _dbHelper.getCurrentUser("cuser") as UserDTO?;
  }

    Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Uint8List fileBytes = await image.readAsBytes();

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.secondary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              // width: 400,
              height: 300,
            ),
          ),
        ],
      );

      if (croppedFile != null) {
        Uint8List croppedBytes = await croppedFile.readAsBytes();

        final img.Image? image = img.decodeImage(croppedBytes);
        if (image != null) {
          final resizedImage = img.copyResize(image, width: 300);
          setState(() {
            _profileImage = Uint8List.fromList(img.encodeJpg(resizedImage));

            _uploadProfileImage();

          });
        }
      }
    } else {
      // Fluttertoast.showToast(
      //   msg: "No image selected. Please try again.",
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      //   fontSize: 16.0,
      // );
      CommonHelper.logDebug("user action cancelled or No image selected. Please try again.");
    }
  }

  Future<void> _updateUserPhotoInHive(String photo) async {
    try {
      UserDTO? currentUser = await _dbHelper.getCurrentUser("cuser");

      if (currentUser != null) {
        // Update only the photo, keeping other data intact
        await _dbHelper.storeCurrentUser("cuser",
            UserDTO(
              userID: currentUser.userID,
              fullName: currentUser.fullName,
              email: currentUser.email,
              phoneNumber: currentUser.phoneNumber,
              photo: photo,
              deviceToken: currentUser.deviceToken,
              handShakeAvailable: currentUser.handShakeAvailable,
              gender: currentUser.gender,
              userType: currentUser.userType,
              country: currentUser.country,
              city: currentUser.city,
            )
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update photo.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      CommonHelper.logDebug("Error updating photo in Hive: $e");
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final restUtil = RESTUtil(
        baseUrl: AppConstants.UPDATE_PROFILE_PICTURE, // Define the correct endpoint for uploading the profile photo
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final payload = {
        'photo': _profileImage != null ? base64Encode(_profileImage!) : null,
        'user_id': widget.currentUserId.toString(),
      };

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {

        String newPhoto = responseData['user']['photo'];
        CommonHelper.logDebug("new photo is "+newPhoto);

        await _updateUserPhotoInHive(newPhoto);  // Store as base64 in Hive

        // Update the state to refresh the image view
        setState(() {
          _isPhotoChanged = true; // Mark that the photo has been updated
          _updatedPhotoUrl = "${AppConstants.APVISER_IMAGES_PATH_FULL}$newPhoto";
        });

        Fluttertoast.showToast(
          msg: "Profile photo updated successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        CommonHelper.logDebug(responseData['error_msg']);
      }
    } catch (e) {
      CommonHelper.logDebug("Error uploading profile photo: $e");
    }
  }

  // Navigate back with information about whether the photo was changed
  void _navigateBackWithUpdateStatus() {
    CommonHelper.logDebug("_isPhotoChanged $_isPhotoChanged");
    Navigator.pop(context, _isPhotoChanged); // Pass a flag indicating if the photo was changed
  }

  @override
  Widget build(BuildContext context) {
    CommonHelper.logDebug("currentPhoto is ${widget.currentPhoto}");
    return Scaffold(
      appBar:

        CustomAppBar(title: widget.screenTitle!, actions: [
          if (widget.isCurrentUser)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.secondary,),
              onPressed: _pickImage,  // Allow the user to change the photo
            )
        ],)
      ,body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppConstants.APP_MAX_WIDTH, // Restrict body width
                ),
                child: _updatedPhotoUrl != null
                    ? Image.network(
                  _updatedPhotoUrl!, // Use the updated photo URL
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        "Failed to load image.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                )
                    : Image.network(
                  "${AppConstants.APVISER_IMAGES_PATH_FULL}${widget.currentPhoto}",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        "Failed to load image.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


