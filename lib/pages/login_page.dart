import 'dart:convert';

import 'package:Apviser/AppConstants.dart';
import 'package:Apviser/rest_util.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:country_codes/country_codes.dart';
// import 'package:country_codes/country_codes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../CommonHelper.dart';
import './otp_verify.dart';
// import 'dart:io' show Platform; // Import for platform detection
import 'package:flutter/foundation.dart' show kIsWeb; // More specific web check
import 'package:http/http.dart' as http;
// import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final TextEditingController _phoneController = TextEditingController();
  String? _verificationId;

  String tt = "", fullname = "";

  bool _isAgreementAccepted = false;
  GlobalKey<FormState> _formKey = GlobalKey();
  FocusNode focusNode = FocusNode();
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _canResendOTP = true;
  // String? _verificationId;
  // String? _errorMessage;
  String _countryCode = ''; // fallback

  @override
  void initState() {
    super.initState();
    //StateError('This is test exception');
    // CommonHelper.logDebug("Test web crash", sendToSentry: true);
    // Request focus on the IntlPhoneField
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   FocusScope.of(context).requestFocus(focusNode);
    // });
    //
    // getInitialCountryCode().then((code) {
    //   setState(() {
    //     _countryCode = code;
    //   });
    // });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(focusNode);
    });

    // Fetch country code without blocking focus
    Future.microtask(() async {
      final code = await getInitialCountryCode();
      if (mounted) {
        setState(() {
          _countryCode = code;
        });
      }
    });
  }

  Future<void> _verifyPhoneNumber() async {
    if (_isSubmitting) return; // Prevent duplicate submissions
    final phoneNumber = tt;
    if (phoneNumber.isEmpty ||
        !RegExp(r'^\+\d{1,3}\d{4,14}(?:x.+)?$').hasMatch(phoneNumber)) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number with country code.';
        //_isSubmitting = false; // Re-enable form interaction
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // await _auth.signInWithCredential(credential);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Successfully signed in!')),
          // );
          setState(() => _isLoading = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            if (e.code == 'too-many-requests') {
              _errorMessage = 'Too many attempts. Try again later.';
              CommonHelper.logDebug("Phone number ${phoneNumber.toString()} had too many attempts", sendToSentry: true, stackTrace: e.stackTrace, exception: e);
              Sentry.captureException(e, stackTrace: e.stackTrace);
              // CommonHelper.logDebug(e.toString());
              // FirebaseCrashlytics.instance.recordError(e, e.stackTrace, fatal: true, reason: "Phone number ${phoneNumber.toString()} had too many attempts");
            } else if (e.code == 'invalid-phone-number') {
              _errorMessage = 'Invalid phone number. Check your input.';
            } else {
              _errorMessage = 'Verification failed. Please try again.';
              CommonHelper.logDebug("Phone number ${phoneNumber.toString()} Verification failed", sendToSentry: true, stackTrace: e.stackTrace, exception: e);
              Sentry.captureException(e, stackTrace: e.stackTrace);
              // CommonHelper.logDebug(e.toString(), addToCrashLatics: true);
              // FirebaseCrashlytics.instance.recordError(e, e.stackTrace, fatal: true, reason: "Phone number ${phoneNumber.toString()} Verification failed");
            }
            _isLoading = false;
            _isSubmitting = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            // _verificationId = verificationId;
            _isLoading = false;
            _isSubmitting = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                verificationId: verificationId,
                phoneNumber: phoneNumber,
                email: '',
                fullName: fullname,
                password: '123456',
                photo: '',
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
        _isSubmitting = false;
        CommonHelper.logDebug("Phone number ${phoneNumber.toString()} got exception", sendToSentry: true, stackTrace: null, exception: e);
        // CommonHelper.logDebug(e.toString(), addToCrashLatics: true);
        // FirebaseCrashlytics.instance.recordError(e, null, fatal: true, reason: "Phone number ${phoneNumber.toString()} got exception");
      });
    }
  }
  /*
  Future<void> _verifyPhoneNumber() async {
    if (_isSubmitting) return; // Prevent duplicate submissions

    setState(() => _isSubmitting = true); // Disable form interaction

    final phoneNumber = tt;
    if (phoneNumber.isEmpty ||
        !RegExp(r'^\+\d{1,3}\d{4,14}(?:x.+)?$').hasMatch(phoneNumber)) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number with country code.';
        _isSubmitting = false; // Re-enable form interaction
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isSubmitting = true; // Re-enable form interaction
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully signed in with phone number!')),
          );
          setState(() {
            _isLoading = false;
            _isSubmitting = false; // Re-enable form interaction
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = 'Phone number verification failed: ${e.message}';
            _isLoading = false;
            _isSubmitting = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _isSubmitting = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                verificationId: _verificationId!,
                phoneNumber: phoneNumber,
                email: '',
                fullName: fullname,
                password: '123456',
                photo: '',
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
        _isSubmitting = false;
        print(_errorMessage);
      });
    }
  }
*/

  void _sendOTP() {
    // CommonHelper.logDebug("sending otp", sendToSentry: true);
    // Sentry.captureException("sending otp");
    //Sentry.captureMessage("sending otp");
    if (!_canResendOTP) return;

    setState(() => _canResendOTP = false);
    _verifyPhoneNumber();

    Future.delayed(Duration(seconds: 30), () {
      setState(() => _canResendOTP = true);
    });
  }

  Future<String> getInitialCountryCode(
      {int maxRetries = 3,
      Duration initialDelay = const Duration(seconds: 1)}) async {
    // try {
    //
    //   LocationPermission permission = await Geolocator.checkPermission();
    //   if (permission == LocationPermission.denied) {
    //     permission = await Geolocator.requestPermission();
    //     if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
    //       return 'US';
    //     }
    //   }
    //
    //   final position = await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.low,
    //   );
    //
    //   if (kIsWeb) {
    try {
      final response =
          await http.get(Uri.parse('https://ipinfo.io/json')); // Example API
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? countryCode = data['country'];
        if (countryCode != null) {
          CommonHelper.logDebug("✅ Country Code (IP-based): $countryCode");
          return countryCode;
        } else {
          CommonHelper.logDebug(
              "⚠️ IP-based geocoding failed to get country code.");
          return 'US'; // Default fallback
        }
      } else {
        CommonHelper.logDebug(
            "⚠️ IP-based geocoding request failed: ${response.statusCode}");
        return 'US'; // Default fallback
      }
    } catch (e) {
      CommonHelper.logDebug("❌ Error during IP-based geocoding: $e");
      return 'US'; // Default fallback
    }
    //   } else {
    //
    //     final placemarks = await placemarkFromCoordinates(
    //       position.latitude,
    //       position.longitude,
    //     ).timeout(const Duration(seconds: 10));
    //
    //     if (placemarks.isNotEmpty) {
    //       final Placemark placemark = placemarks.first;
    //       if (placemark != null && placemark.isoCountryCode != null) {
    //         final code = placemark.isoCountryCode!;
    //         CommonHelper.logDebug("✅ Country Code: $code");
    //         return code;
    //       } else {
    //         CommonHelper.logDebug("⚠️ Placemark found, but isoCountryCode is null.");
    //         CommonHelper.logDebug("⚠️ Placemark details: ${placemark.toJson()}"); // If available
    //         return 'US';
    //       }
    //     } else {
    //       CommonHelper.logDebug("⚠️ Placemark returned empty.");
    //       return 'US';
    //     }
    //   }
    // } catch (e, stack) {
    //   CommonHelper.logDebug("❌ Error during placemark lookup: $e");
    //   CommonHelper.logDebug("📍 Stack: $stack");
    //   return 'US';
    // }
  }

// Call this function instead of the original getCountryCode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: Colors.transparent)),
      ),
      body: Center(
        // Center the content
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Container(
              width: AppConstants
                  .APP_MAX_WIDTH, // Limit the width of the login form (you can adjust the value)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image on top
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg', // Replace with your image path
                      height: 80, // Adjust the height as needed
                    ),
                  ),
                  SizedBox(
                      height:
                          20), // Add some space between the image and the phone field
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        _countryCode.isEmpty
                            ? CircularProgressIndicator()
                            : IntlPhoneField(
                                initialCountryCode: _countryCode
                                    .toUpperCase(), // Ensure uppercase
                                focusNode: focusNode,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(),
                                ),
                                languageCode: "en",
                                onChanged: (phone) {
                                  CommonHelper.logDebug(phone.completeNumber);
                                  tt = phone.completeNumber;
                                },
                                onCountryChanged: (country) {
                                  CommonHelper.logDebug(
                                      'Country changed to: ' + country.name);
                                },
                              ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _isAgreementAccepted &&
                                  _formKey.currentState?.validate() == true &&
                                  tt.toString().isEmpty == false,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isAgreementAccepted = value!;
                                });
                              },
                            ),
                            GestureDetector(
                              onTap: _showUserAgreement,
                              child: const Text(
                                'I accept the user agreement',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: (_isAgreementAccepted &&
                                  _formKey.currentState?.validate() != null &&
                                  _formKey.currentState?.validate() == true &&
                                  tt.toString().isEmpty == false &&
                                  _isSubmitting == false)
                              ? _sendOTP
                              : null,
                          child: Text('Continue'),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        if (_isLoading) CircularProgressIndicator(),
                        // About Link
                        SizedBox(
                            height:
                                20), // Add some space between the button and about link
                        // GestureDetector(
                        //   onTap: () {
                        //     // Navigate to About page
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (context) => AboutPage(),  // Replace with your About page widget or URL
                        //       ),
                        //     );
                        //   },
                        //   child: Text(
                        //     'Learn more about Apviser',
                        //     style: TextStyle(
                        //       decoration: TextDecoration.underline,
                        //       color: Colors.blue,
                        //     ),
                        //   ),
                        // ),
                        GestureDetector(
                          onTap: _openApviser,
                          child: Text(
                            'Learn more about Apviser',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openApviser() async {
    final Uri url = Uri.parse(AppConstants.APVISER_MAIN_LINK);

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // Forces system browser
    )) {
      throw 'Could not launch $url';
    }
  }

  void _showUserAgreement() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Agreement'),
          content: SingleChildScrollView(
            // child: Text('This is the user agreement...'), // Add actual user agreement text here
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.userAgreementTitle,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  AppConstants.lastUpdated,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey),
                ),
                SizedBox(height: 20),
                _buildSection(
                    AppConstants.section1Title, AppConstants.section1Content),
                _buildSection(AppConstants.section2Title, ""),
                _buildBulletList(AppConstants.section2Points),
                _buildSection(
                    AppConstants.section3Title, AppConstants.section3Content),
                _buildSection(
                    AppConstants.section4Title, AppConstants.section4Content),
                _buildSection(
                    AppConstants.section5Title, AppConstants.section4Content),
                _buildSection(
                    AppConstants.section6Title, AppConstants.section4Content),
                _buildSection(
                    AppConstants.section7Title, AppConstants.section4Content),
                _buildSection(
                    AppConstants.section8Title, AppConstants.section4Content),
                _buildSection(
                    AppConstants.section9Title, AppConstants.section4Content),
                _buildSection(
                    AppConstants.section10Title, AppConstants.section4Content),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper function to build section headers with content
  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        if (content.isNotEmpty)
          Text(
            content,
            style: TextStyle(fontSize: 16),
          ),
        SizedBox(height: 10),
      ],
    );
  }

  // Helper function to create bullet points
  Widget _buildBulletList(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) {
        return Padding(
          padding: EdgeInsets.only(left: 16, bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(
                  point,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
