import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../AppConstants.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import '../CommonHelper.dart';
import '../DatabaseHelper.dart';
import '../models/UserDTO.dart';
import '../rest_util.dart'; // Ensure this path is correct
import '../widgets/app_bar.dart';
import 'home.dart'; // Ensure this path is correct for the home page
import 'add_friends.dart'; // Ensure this path is correct for the contacts page

class UserInfoPage extends StatefulWidget {
  final String phoneNumber;

  UserInfoPage({required this.phoneNumber});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  bool _isOfferingServices = false;
  String? _selectedGender = 'Select';
  Uint8List? _profileImage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConstants.WEB_CLIENT_ID : null,
  );

  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.URL_REGISTER,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() == true) {
      // Set default gender to 'Other' if user left it as 'Select'
      if (_selectedGender == 'Select') {
        _selectedGender = 'Other';
      }
      try {
        int? userID = await _updateUserInfo();
        if (kIsWeb) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => Home(title: '',),
            ),
                (route) => false,
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
             builder: (context) => ContactsPage(referrerID: userID!, cameFrom: "userinfo",), // Pass the correct referrerID
            ),
          );
        }
      } catch (e) {
        CommonHelper.logDebug("Failed to update user information: $e");
        Fluttertoast.showToast(
          msg: "Failed to update user information: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  Future<int?> _updateUserInfo() async {
    CommonHelper.logDebug("inside _updateUserInfo");
    final jsonPayload = json.encode({
      "phone": widget.phoneNumber,
      "fullName": _fullNameController.text,
      "email": _emailController.text,
      "handshake": _isOfferingServices ? 1 : 0,
      "gender": _selectedGender,
      "about": _aboutController.text,
      "title": _designationController.text,
      "password": "",
      "city":"",
      "country":"",
      "coordinates":"",
      "street":"",
      "postal_code":"",
      "state":"",
      "photo": _profileImage != null ? base64Encode(_profileImage!) : null,
    });
    CommonHelper.logDebug(jsonPayload);
    final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
      "json": jsonPayload,
    });

    final responseData = json.decode(response.body);
    int? uID = 0;
    if (responseData['error'] == false) {
      CommonHelper.logDebug("error is false");

      // Parse the JSON string into a Dart Map
      //Map<String, dynamic> data = jsonDecode(responseData);
      // store user information here in hive
      final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
      uID = int.tryParse(responseData["user_id"] ?? '0');
      await _dbHelper.storeCurrentUser("cuser",new UserDTO(userID: uID ?? 0
          , fullName: responseData['full_name'] ?? ''
          , email: responseData['email'] ?? ''
          , phoneNumber: responseData['phone'] ?? '',  // Use empty string if null
          photo: responseData['photo'] ?? '',  // Use empty string if null
          deviceToken: responseData["device_token"] ?? '',  // Use empty string if null
          handShakeAvailable: responseData["handshake_available"] ?? '',  // Use false if null
        gender: responseData["gender"] ?? '',  // Use empty string if null
        userType: int.tryParse(responseData["user_type"] ?? '0') ?? 0,  // Use 0 if null
        country: responseData["country"] ?? '',  // Use empty string if null
        city: responseData["city"] ?? '',  // Use empty string if null
      ));
      CommonHelper.logDebug("User information updated successfully");
      Fluttertoast.showToast(
        msg: "User information updated successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

    } else {
      CommonHelper.logDebug("An error occurred. Please try again");
      throw Exception(responseData['error_msg'] ?? "An error occurred. Please try again.");
    }

    return uID;
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
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
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
              width: 520,
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
          });
        }
      }
    } else {
      Fluttertoast.showToast(
        msg: "No image selected. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: AppColors.primaryLight, // Set the background color

      appBar: CustomAppBar(title: "User Information", showBackButton: false,),

      body:
    SingleChildScrollView(
    child:
    Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppConstants.APP_MAX_WIDTH, // Restrict the width
        ),
        child: Container(
          color: Colors.transparent, // Set background color only for this container
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.login),
                          label: Text("Continue with Google"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _handleGoogleSignInAndFill,
                        )
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _profileImage != null
                              ? MemoryImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey[800],
                          )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Please fill in your information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),


                    SizedBox(height: 20),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      // validator: (value) {
                      //   if (value == null || value.isEmpty) {
                      //     return 'Please enter your email';
                      //   }
                      //   return null;
                      // },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      value: _selectedGender,
                      items: ['Select', 'Male', 'Female', 'Other']
                          .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue!;
                        });
                      },
                      // validator: (value) {
                      //   if (value == null || value == 'Select') {
                      //     return 'Please select your gender';
                      //   }
                      //   return null;
                      // },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _designationController,
                      decoration: InputDecoration(
                        labelText: 'Title/Occupation',
                        hintText: AppConstants.HINT_TEXT_OCCUPATION,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _aboutController,
                      decoration: InputDecoration(
                        labelText: 'About',
                        hintText: AppConstants.HINT_TEXT_ABOUT,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      maxLines: 3,

                    ),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Align icon with the checkbox
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text('Offering Services'),
                            value: _isOfferingServices,
                            onChanged: (bool? value) {
                              setState(() {
                                _isOfferingServices = value ?? false;
                              });
                            },
                          ),
                        ),
                        Tooltip(
                          message: AppConstants.HINT_TEXT_OFFER_SERVICES,
                          child: Icon(
                            Icons.help_outline,
                            color: Colors.grey, // Adjust icon color to match your app theme
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .primaryColor, // Set the primary color
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20), // Increase button size
                          textStyle: TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    ),
    )

    );
  }

  Future<void> _handleGoogleSignInAndFill() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account != null) {
        setState(() {
          _fullNameController.text = account.displayName ?? '';
          _emailController.text = account.email;
          // Optional: Load profile photo
          // You can add logic to download the photo and store as _profileImage
        });
        // CommonHelper.logDebug("Google Sign-In failed: $e");
        CommonHelper.logDebug("Info filled from Google account!");
        _submitForm();
        // Fluttertoast.showToast(
        //   msg: "Info filled from Google account!",
        //   gravity: ToastGravity.BOTTOM,
        //   backgroundColor: Colors.green,
        //   textColor: Colors.white,
        // );
      }
    } catch (e) {
      CommonHelper.logDebug("Google Sign-In failed: $e");
      CommonHelper.showMessage(context, "Some error occurred while fetching info from Google account!", 5);
      // Fluttertoast.showToast(
      //   msg: "Google Sign-In failed: $e",
      //   backgroundColor: Colors.red,
      //   textColor: Colors.white,
      // );
    }
  }


/*Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('User Information'),
      // ),
      appBar: CustomAppBar(title: "User Information", showBackButton: false,),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24.0, vertical: 16.0), // Adjust padding here
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? MemoryImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.grey[800],
                      )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Please fill in your information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  value: _selectedGender,
                  items: ['Select', 'Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value == 'Select') {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _designationController,
                  decoration: InputDecoration(
                    labelText: 'Title/Occupation',
                    hintText: AppConstants.HINT_TEXT_OCCUPATION,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _aboutController,
                  decoration: InputDecoration(
                    labelText: 'About',
                    hintText: AppConstants.HINT_TEXT_ABOUT,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  maxLines: 3,

                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Align icon with the checkbox
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text('Offering Services'),
                        value: _isOfferingServices,
                        onChanged: (bool? value) {
                          setState(() {
                            _isOfferingServices = value ?? false;
                          });
                        },
                      ),
                    ),
                    Tooltip(
                      message: AppConstants.HINT_TEXT_OFFER_SERVICES,
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.grey, // Adjust icon color to match your app theme
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .primaryColor, // Set the primary color
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20), // Increase button size
                      textStyle: TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text('Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }*/
}
