import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Apviser/AppConstants.dart';
import 'package:Apviser/CommonHelper.dart';
import 'package:Apviser/DatabaseHelper.dart';
import 'package:Apviser/models/UserDTO.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../colours.dart';
import '../rest_util.dart';
import '../widgets/app_bar.dart';
import 'select_expertise.dart';
import 'home.dart';

class OtpVerificationPage extends StatefulWidget {
  String verificationId;
  final String phoneNumber;
  final String fullName;
  final String email;
  final String photo;
  final String password;

  OtpVerificationPage({
    required this.verificationId,
    required this.phoneNumber,
    required this.fullName,
    required this.email,
    required this.photo,
    required this.password,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode =
      FocusNode(); // Add a FocusNode for the OTP TextField
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  bool _isSubmitting = false;
  int _resendCooldown = 60;
  Timer? _timer;


  final RESTUtil _addUser = RESTUtil(
    baseUrl: AppConstants.URL_REGISTER,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  final RESTUtil _loginUser = RESTUtil(
    baseUrl: AppConstants.URL_LOGIN,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );

  @override
  void initState() {
    super.initState();
    // Request focus on the OTP TextField
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
    });
  }

  Future<void> _signInWithPhoneNumber() async {
    if (_isSubmitting) return; // Prevent duplicate submissions

    if (_otpController.text.trim().isEmpty) {
      _showErrorToast(AppConstants.TEXT_OTP_EMPTY);
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);

      //_showSuccessToast(AppConstants.TEXT_SIGNIN_SUCCESSFUL);
      await _checkUserExists(widget.phoneNumber);
    } catch (e) {
      CommonHelper.logDebug('Failed to sign in with phone number: $e');
      //_showErrorToast(AppConstants.TEXT_WRONG_OTP);
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().contains('expired') ? 'OTP expired. Request a new one.' : 'Invalid OTP. Try again.')),
      );
    }finally{
      //_isSubmitting = false;
    }
  }
  Future<void> _checkUserExists(String phoneNumber) async {
    CommonHelper.logDebug("inside _checkUserExists");

    // final payload = json.encode({"username": phoneNumber});

    try {
      Map<String, String> requestBody = <String, String>{
        'json': '{"username":"${phoneNumber}"}'
      };
      final response =
          await _loginUser.postForm(_loginUser.baseUrl, requestBody);
      // final response = await _loginUser.postForm2(_loginUser.baseUrl, requestBody);
      CommonHelper.logDebug(response.toString());
      // final response = await _loginUser.loginTest(phoneNumber, _loginUser.baseUrl);
      final responseData = json.decode(response.body);
      // _isSubmitting = true;
      if (responseData['error'] == false) {
        // print("Welcome back!");
        _showSuccessToast("${AppConstants.TEXT_WELCOME_BACK} ${responseData['full_name']}");
        CommonHelper.logDebug("${AppConstants.TEXT_WELCOME_BACK} ${responseData['full_name']}");
        int cuserID = 0;
        int? uid = int.tryParse(responseData['ID'] ?? '');
        //cuserID = uid;
        if (uid != null) {
          CommonHelper.logDebug("uid not null");
          cuserID = uid;

          // await _dbHelper.storeCurrentUser("cuser",new UserDTO(userID: cuserID, fullName: responseData['full_name']));
          await _dbHelper.storeCurrentUser(
              "cuser",
              UserDTO(
                userID: cuserID,
                fullName:
                    responseData['full_name'] ?? '', // Use empty string if null
                email: responseData['email'] ?? '', // Use empty string if null
                phoneNumber:
                    responseData['phone'] ?? '', // Use empty string if null
                photo: responseData['photo'] ?? '', // Use empty string if null
                deviceToken: responseData["device_token"] ??
                    '', // Use empty string if null
                handShakeAvailable: responseData["handshake_available"] ??
                    '', // Use false if null
                gender:
                    responseData["gender"] ?? '', // Use empty string if null
                userType: int.tryParse(responseData["user_type"] ?? '0') ??
                    0, // Use 0 if null
                country:
                    responseData["country"] ?? '', // Use empty string if null
                city: responseData["city"] ?? '', // Use empty string if null
              ));

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) => Home(
                      title: '',
                    )),
            (route) => false,
          );
        } else {
          CommonHelper.logDebug("uid is null");
        }
      } else {
        // _showErrorToast(responseData['error_msg'] ?? "An error occurred. Please try again.");
        CommonHelper.logDebug("new user redirect to user registration");
        await _registerUser(null);
      }
    } catch (e) {
      //print("An error occurred: $e");
      _showErrorToast(AppConstants.TEXT_SOME_ERROR);
      CommonHelper.logDebug(e.toString());
      await _registerUser(null);
    }finally{
      // _isSubmitting = false;
    }
  }

  Future<void> _registerUser(Position? position) async {
    String? country;
    String? city;
    String? state;
    String? coordinates;
    String? street;
    String? postalCode;

    if (position != null) {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();

      country = place.country;
      city = place.locality;
      state = place.administrativeArea;
      coordinates = "${position.latitude},${position.longitude}";
      street = place.street;
      postalCode = place.postalCode;
    }

    try {
      final jsonPayload = json.encode({
        "email": widget.email,
        "phone": widget.phoneNumber,
        "password": widget.password,
        "fullName": widget.fullName,
        "photo": widget.photo,
        "handshake": 1,
        "country": country ?? "",
        "city": city ?? "",
        "state": state ?? "",
        "coordinates": coordinates ?? "",
        "street": street ?? "",
        "postal_code": postalCode ?? "",
      });
      final response = await _addUser.postForm(_addUser.baseUrl, {
        "json": jsonPayload,
      });

      final responseData = json.decode(response.body);
      if (responseData['error'] == false) {
        CommonHelper.logDebug("user added successfully");
        await _dbHelper.storeCurrentUser(
          "cuser",
          UserDTO(
            userID: int.tryParse(responseData['user_id']) ??
                0, // Use tryParse and provide a default value if parsing fails
            fullName: responseData['full_name'],
          ),
        );
        // CommonHelper.showMessage(context, AppConstants.TEXT_REGISTRATION_SUCCESSFUL, 5);
        // _showSuccessToast(AppConstants.TEXT_REGISTRATION_SUCCESSFUL);

        CommonHelper.logDebug("Registration successful");

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SelectExpertisePage(
              phoneNumber: widget.phoneNumber,
              userID: int.tryParse(responseData['user_id']) ?? 0,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        CommonHelper.logDebug("Registration failed. Please try again.");
        _showErrorToast(AppConstants.TEXT_REGISTRATION_FAIL);
      }
    } catch (e) {
      CommonHelper.logDebug(e.toString());
      _showErrorToast(AppConstants.TEXT_SOME_ERROR);
    }
  }



  void _startResendCooldown() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() => _resendCooldown--);
      if (_resendCooldown == 0) timer.cancel();
    });
  }


  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  void _showErrorToast(String message) {
    CommonHelper.logDebug(message, sendToSentry: true, exception: message);
    CommonHelper.showMessage(context, message, 5);
    // Fluttertoast.showToast(
    //   msg: message,
    //   toastLength: Toast.LENGTH_LONG,
    //   gravity: ToastGravity.BOTTOM,
    //   backgroundColor: Colors.red,
    //   textColor: Colors.white,
    //   fontSize: 16.0,
    // );
  }

  void _showSuccessToast(String message) {
    CommonHelper.logDebug(message);
    CommonHelper.showMessage(context, message, 5);
    // Fluttertoast.showToast(
    //   msg: message,
    //   toastLength: Toast.LENGTH_LONG,
    //   gravity: ToastGravity.BOTTOM,
    //   backgroundColor: Colors.green,
    //   textColor: Colors.white,
    //   fontSize: 16.0,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: AppColors.primaryLight, // Set the background color

      appBar: CustomAppBar(title: "OTP", showBackButton: true,),

      body: Center(
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
                Center(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    alignment: Alignment.topCenter,
                    height: 80,
                  ),
                ),
                SizedBox(height: 16.0), // Add some space between the image and the phone field
                Text(
                  'Enter the OTP sent to ${widget.phoneNumber}:',
                  textAlign: TextAlign.center, // Center align the text
                  style: TextStyle(
                    fontSize: 16.0, // Optional: Adjust font size
                    color: AppColors.black, // Ensure text is readable on the primary background
                  ),
                ),
                SizedBox(height: 16.0), // Add padding between the text boxes
                TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode, // Assign the focus node here
                  autofocus: true, // Automatically focus to capture keyboard input
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    labelStyle: TextStyle(color: AppColors.black), // Adjust label color
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary), // Adjust border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary), // Adjust focused border color
                    ),
                  ),
                  style: TextStyle(color: AppColors.black), // Adjust input text color
                  onSubmitted: (_) {
                    // Call the sign-in function when Enter is pressed
                    _signInWithPhoneNumber();
                  },
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _signInWithPhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // White button for contrast
                    foregroundColor: AppColors.secondary, // Text and icon color
                  ),
                  child: Text(AppConstants.BUTTON_TEXT_VERIFY_OTP),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


/*Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP', style: TextStyle(color: Colors.transparent)),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: SvgPicture.asset(
                alignment: Alignment.topCenter,
                'assets/images/logo.svg',
                height: 80,
              ),
            ),
            //SizedBox(height: 20), // Add some space between the image and the phone field,
            Text('Enter the OTP sent to ${widget.phoneNumber}:'),
            SizedBox(height: 16.0), // Add padding between the text boxes
            TextField(
              controller: _otpController,
              focusNode: _otpFocusNode, // Assign the focus node here
              autofocus: true, // Automatically focus to capture keyboard input
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                // Call the sign-in function when Enter is pressed
                _signInWithPhoneNumber();
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _signInWithPhoneNumber,
              child: Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }*/
}

class OTPInputField extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final Function(String) onChanged;

  OTPInputField({
    required this.controller,
    required this.length,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return Container(
          width: 50,
          height: 60,
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLength: 1, // Each field takes one digit
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "", // Hides character counter
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
            ),
          ),
        );
      }),
    );
  }
}
