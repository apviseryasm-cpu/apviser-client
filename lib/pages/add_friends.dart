import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // Import the main flutter_contacts library
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../DatabaseHelper.dart';
import '../models/UserDTO.dart';
import '../rest_util.dart'; // Ensure this path is correct
import '../widgets/select_expertise2.dart';
import 'home.dart'; // Ensure this path is correct

class ContactsPage extends StatefulWidget {
  final int referrerID; // User who referred
  final int? questionID; // Question ID (from SuggestReferral Page)
  final bool? showSkip;
  final String? expertise;
  final String? cameFrom;

  ContactsPage(
      {required this.referrerID,
        this.questionID,
        this.showSkip = true,
        this.expertise = "",
        this.cameFrom});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> _selectedContacts = [];
  List<Contact> _displayedContacts = [];
  List<Contact> _allContacts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentMax = 30;
  List<ValueItem<String>> selectedExpertise = [];

  final TextEditingController _searchController = TextEditingController();
  final RESTUtil _apiUtil = RESTUtil(
    baseUrl: AppConstants.URL_FRIENDS_REQUEST,
    username: AppConstants.CREDENTIALS_USERNAME,
    password: AppConstants.CREDENTIALS_PASSWORD,
  );
  late UserDTO? currentUser;

  @override
  void initState() {
    super.initState();
    _getContactsPermission();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
    currentUser = await _dbHelper.getCurrentUser("cuser");
    setState(() {}); // Update UI after fetching user
  }

  Future<void> _sendFriendRequestsOrSuggestReferrals() async {
    if (_selectedContacts.isEmpty || currentUser == null) return;

    if (widget.questionID != null) {
      _suggestExpertsByPhone();
    } else {
      _sendFriendRequests();
    }
  }

  Future<void> _getContactsPermission() async {
    // Request permission using flutter_contacts
    // flutter_contacts handles permission requests internally when `getContacts` is called,
    // but it's good practice to ensure it's granted or explain to the user.
    // However, permission_handler is still good for showing a custom dialog if denied permanently.
    PermissionStatus permission = await Permission.contacts.status;
    print('Permission status: $permission');

    if (permission != PermissionStatus.granted) {
      permission = await Permission.contacts.request();
      if (permission != PermissionStatus.granted) {
        CommonHelper.showMessage(context, "Contacts permission denied", 5);
        return;
      }
    }
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission()) {
      CommonHelper.showMessage(context, "Contacts permission not granted", 5);
      return;
    }

    List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true // Use withThumbnail for avatars
    );
    List<Contact> contactsWithPhoneNumbers =
    contacts.where((contact) => contact.phones.isNotEmpty).toList();
    setState(() {
      _allContacts = contactsWithPhoneNumbers;
      _displayedContacts = _allContacts.take(_currentMax).toList();
    });
  }

  Future<void> _loadMoreContacts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(
        Duration(seconds: 2)); // Simulate a delay for loading more contacts

    setState(() {
      if (_displayedContacts.length < _allContacts.length) {
        _currentMax += 30;
        _displayedContacts = _allContacts.take(_currentMax).toList();
        _isLoading = false;
      } else {
        _hasMore = false;
        _isLoading = false;
      }
    });
  }

  Future<void> _sendFriendRequests() async {
    if (_selectedContacts.isEmpty) {
      CommonHelper.showMessage(context, "Please select at least one contact.", 5);
      return;
    }

    List<Map<String, dynamic>> friends = [];

    for (var contact in _selectedContacts) {
      List<ValueItem<String>> selectedExpertiseForUser = [];

      // Show expertise selection dialog for each user
      bool expertiseSelected =
      await _showExpertiseSelectionDialog(contact, selectedExpertiseForUser);

      if (!expertiseSelected || selectedExpertiseForUser.isEmpty) {
        CommonHelper.showMessage(
            context, "Expertise selection is required for ${contact.displayName}.", 5);
        return;
      }

      // Add user to the request payload
      friends.add({
        "friend": {
          "mDisplayName": contact.displayName, // Use contact.displayName
          "mPhone": contact.phones.isNotEmpty
              ? contact.phones.first.number.replaceAll(' ', '')
              : '', // Access .number for phone
        },
        "requesting_user_full_name": '',
        "referrerID": widget.referrerID,
        "expertise": selectedExpertiseForUser.map((e) => e.value).toList(),
        "send_notification": false
      });
    }

    CommonHelper.logDebug(json.encode(friends));
    // Send the request
    try {
      final response = await _apiUtil.postForm(_apiUtil.baseUrl, {
        "json": json.encode(friends),
      });

      final responseData = json.decode(response.body);
      if (responseData['error'] == false) {
        CommonHelper.showMessage(context, "Friend requests sent successfully", 5);

        if (widget.cameFrom == "userinfo") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Home(
                    title:
                    'title')), // Replace MainScreen with your actual main screen widget
          );
        } else {
          Navigator.pop(context, true); // Go back & trigger refresh
        }
      } else {
        CommonHelper.showMessage(context, "Failed to send friend requests. Please try again.", 5);
      }
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');

      CommonHelper.showMessage(context, "An error occurred. Please try again.", 5);
    }
  }

  // Show expertise selection dialog for each user
  Future<bool> _showExpertiseSelectionDialog(
      Contact contact, List<ValueItem<String>> selectedExpertise) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select expertise for user ${contact.displayName}"),
          content: Column(
            children: [
              Expanded(
                child: SelectExpertiseWidget2(
                  userId: widget.referrerID,
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (selectedExpertise.isNotEmpty) {
                  Navigator.pop(context, true);
                } else {
                  CommonHelper.showMessage(
                      context, "Please select at least one expertise.", 5);
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  Future<void> _suggestExpertsByPhone() async {
    List<Map<String, dynamic>> suggestedPeople = _selectedContacts.map((contact) {
      return {
        "phone": contact.phones.isNotEmpty
            ? contact.phones.first.number.replaceAll(" ", "")
            : "", // Access .number for phone
        "fullName": contact.displayName, // Use contact.displayName
        "referrerID": widget.referrerID,
        "expertise": widget.expertise,
        "questionID": widget.questionID
      };
    }).toList();
    final RESTUtil reviewApi = RESTUtil(
      baseUrl: AppConstants.SUGGEST_EXPERTS_BY_PHONE,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );
    try {
      final response =
      await reviewApi.postForm(reviewApi.baseUrl, {'json': jsonEncode(suggestedPeople)});

      final responseData = json.decode(response.body);
      if (responseData['error'] == false) {
        CommonHelper.showMessage(context, "Suggested successfully", 5);

        CommonHelper.logDebug("Sending true back to the previous screen");
        Navigator.pop(context, true); // Go back & trigger refresh
      } else {
        CommonHelper.showMessage(context, "Failed to suggest. Please try again.", 5);
      }
    } catch (e) {
      CommonHelper.logDebug('Exception: $e');

      CommonHelper.showMessage(context, "An error occurred. Please try again.", 5);
    }
  }

  void _hideLoadingIndicator() {
    setState(() => _isLoading = false);
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Requests sent successfully!")),
    );
  }

  void _filterContacts(String query) {
    List<Contact> filteredContacts = _allContacts.where((contact) {
      return contact.displayName.toLowerCase().contains(query.toLowerCase()) &&
          contact.phones.isNotEmpty;
    }).toList();
    setState(() {
      _displayedContacts = filteredContacts.take(_currentMax).toList();
    });
  }

  Future<void> _refreshContacts() async {
    // Re-check the permission status
    PermissionStatus permission = await Permission.contacts.status;

    if (permission == PermissionStatus.granted) {
      // If permission is granted, fetch contacts
      setState(() {
        _allContacts.clear();
        _displayedContacts.clear();
        _currentMax = 30;
        _isLoading = false;
        _hasMore = true;
      });
      await _fetchContacts();
    } else if (permission == PermissionStatus.denied) {
      // If permission is denied, explicitly request it again
      permission = await Permission.contacts.request();

      if (permission == PermissionStatus.granted) {
        // If permission is granted after re-request, fetch contacts
        setState(() {
          _allContacts.clear();
          _displayedContacts.clear();
          _currentMax = 30;
          _isLoading = false;
          _hasMore = true;
        });
        await _fetchContacts();
      } else if (permission == PermissionStatus.permanentlyDenied ||
          permission == PermissionStatus.denied) {
        // If permission is still denied or permanently denied, guide the user to settings
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text(
              'Contacts permission is required to load contacts. Please enable it in the app settings.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Invite Users",
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _selectedContacts.isNotEmpty
                ? _sendFriendRequestsOrSuggestReferrals
                : null,
          ),
          if (widget.showSkip == true)
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Home(
                          title:
                          'title')), // Replace MainScreen with your actual main screen widget
                );
              },
              child: Text(
                'Skip',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshContacts,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Contacts',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _filterContacts(value);
                },
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (!_isLoading &&
                      _hasMore &&
                      scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                    _loadMoreContacts();
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount: _displayedContacts.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _displayedContacts.length) {
                      return Center(child: CircularProgressIndicator());
                    }
                    Contact contact = _displayedContacts[index];
                    bool isSelected = _selectedContacts.contains(contact);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                        contact.photo != null // Use contact.photo
                            ? MemoryImage(contact.photo!)
                            : AssetImage('assets/images/anonymous.png')
                        as ImageProvider,
                      ),
                      title: Text(contact.displayName), // Use contact.displayName
                      subtitle: Text(contact.phones.isNotEmpty
                          ? contact.phones.first.number
                          : ''), // Access .number for phone
                      trailing: isSelected
                          ? Icon(Icons.check_box, color: Colors.green)
                          : Icon(Icons.check_box_outline_blank),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedContacts.remove(contact);
                          } else {
                            _selectedContacts.add(contact);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
