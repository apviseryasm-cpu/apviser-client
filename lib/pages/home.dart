import 'dart:convert';

import 'package:Apviser/pages/notifications.dart';
import 'package:Apviser/pages/profile_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../DatabaseHelper.dart';
import '../main.dart';
import '../models/UserDTO.dart';
import '../my_posts.dart';
import '../post_details_view.dart';
import '../posts.dart';
import '../rest_util.dart';
import 'search.dart';

// UserDTO currentUser = UserDTO();
UserDTO? user; // Declare the user at the class level
final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

class Home extends StatefulWidget {
  final int initialTabIndex;
  Home({Key? key, required this.title, this.currentUser, this.initialTabIndex = 0}) : super(key: key);
  final String title;
  UserDTO? currentUser;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool hasNewNotification = false;
  ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isTabBarVisible = ValueNotifier(true);
  UserDTO? user;

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    PushNotificationService.initialize(context);
    _setupForegroundNotificationListener();
    _setupScrollListener();
    _setupTabChangeListener();
    _navigateToPostDetails();
    _initializeUser();
  }

  void _setupForegroundNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      CommonHelper.logDebug('Foreground Message: ${message.notification?.title}, data: ${message.data}');
      if (message.notification != null) {
        setState(() => hasNewNotification = true);
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      _isTabBarVisible.value = _scrollController.position.userScrollDirection == ScrollDirection.forward;
    });
  }

  void _setupTabChangeListener() {
    _tabController.addListener(() {
      if (_tabController.index == 2 && _tabController.indexIsChanging) {
        setState(() => hasNewNotification = false);
      }
    });
  }

  void _navigateToPostDetails() {
    if (params.descr?.isNotEmpty == true) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailsView(postDTO: params)),
        );
      });
    }
  }

  Future<void> _initializeUser() async {
    user = await _dbHelper.getCurrentUser("cuser");
    setState(() {}); // Trigger a rebuild when user data is available
    CommonHelper.logDebug("Initialized user in Home: ${user?.userID}");
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Posts(tabController: _tabController, scrollController: _scrollController, currentUser: user), // Pass currentUser
                  MyPosts(tabController: _tabController, scrollController: _scrollController, currentUser: user), // Pass currentUser
                  NotificationsScreen(tabController: _tabController, scrollController: _scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset('assets/images/logo.svg', height: 40),
              _buildAppBarIcons(),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildAppBarIcons() {
    return Row(
      children: [
        IconButton(icon: Icon(Icons.search), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(cameThrough: "icon")))),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSettingsScreen(
                userId: user?.userID ?? 0,
                currentUserId: user?.userID ?? 0,
                userName: '',

              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isTabBarVisible,
      builder: (context, isVisible, child) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: isVisible ? kToolbarHeight : 0,
          child: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
                child: TabBar(
                  controller: _tabController,
                  onTap: _handleTabTap,
                  tabs: [
                    Tab(icon: Icon(Icons.home), text: "Home"),
                    Tab(icon: Icon(Icons.list), text: "My Posts"),
                    Tab(
                      icon: Stack(
                        children: [
                          Icon(Icons.notifications),
                          if (hasNewNotification) _buildNotificationBadge(),
                        ],
                      ),
                      text: "Notifications",
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationBadge() {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }

  void _handleTabTap(int index) {
    if (index == 0 && _scrollController.hasClients) {
      _scrollController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }
}

// // UserDTO currentUser = UserDTO();
// UserDTO? user; // Declare the user at the class level
// final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
//
//
// class Home extends StatefulWidget {
//   const Home({Key? key, required this.title}) : super(key: key);
//   final String title;
//
//   @override
//   State<Home> createState() => _HomeState();
// }
//
// class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool hasNewNotification = false; // State to track notifications
//   ScrollController _scrollController = ScrollController();
//   // bool _isTabBarVisible = true;
//   final ValueNotifier<bool> _isTabBarVisible = ValueNotifier(true);
//
//   @override
//   void initState() {
//     super.initState();
//
//     _tabController = TabController(length: 3, vsync: this);
//
//     PushNotificationService.initialize(context);
//
//     // Listen for foreground notifications
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('Got a message whilst in the foreground!');
//       print('Message data: ${message.data}');
//
//       if (message.notification != null) {
//         print('Message also contained a notification: ${message.notification}');
//       }
//
//       // Update state to show the red dot
//       setState(() {
//         print('Setting hasNewNotification to true');
//         hasNewNotification = true;
//       });
//     });
//
//     _scrollController.addListener(() {
//       ScrollDirection direction = _scrollController.position.userScrollDirection;
//
//       if (direction == ScrollDirection.reverse && _isTabBarVisible.value) {
//         _isTabBarVisible.value = false;
//       } else if (direction == ScrollDirection.forward && !_isTabBarVisible.value) {
//         _isTabBarVisible.value = true;
//       }
//     });
//
//     _tabController.addListener(() {
//       // Check if the Notifications tab (index 2) is selected
//       if (_tabController.index == 2 && _tabController.indexIsChanging) {
//         setState(() {
//           print("clear notifications sign");
//           hasNewNotification = false; // Reset the notification badge
//         });
//       }
//     });
//
//     if (params.descr?.isEmpty == false) {
//       SchedulerBinding.instance.addPostFrameCallback((_) {
//         Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => PostDetailsView(postDTO: params)));
//       });
//     }
//
//     _initializeUser();
//   }
//
//   Future<void> _initializeUser() async {
//     user = await _dbHelper.getCurrentUser("cuser"); // Get user from database
//     setState(() {}); // Call setState to update the UI if needed
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3, // Number of tabs
//       child: Scaffold(
//         appBar: AppBar(
//           title: Center(
//             child: ConstrainedBox(
//               constraints: BoxConstraints(
//                 maxWidth: AppConstants.APP_MAX_WIDTH, // Restrict AppBar width
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Logo on the left
//                   SvgPicture.asset(
//                     'assets/images/logo.svg',
//                     height: 40, // Adjust height as needed
//                   ),
//                   // Icons on the right
//                   Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.search),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => SearchPage(cameThrough: "icon"),
//                             ),
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.settings),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ProfileSettingsScreen(
//                                 userId: user!.userID,
//                                 currentUserId: user!.userID,
//                                 userName: '',
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         body: Column(
//           children: [
//             ValueListenableBuilder<bool>(
//               valueListenable: _isTabBarVisible,
//               builder: (context, isVisible, child) {
//                 return AnimatedContainer(
//                   duration: Duration(milliseconds: 300),
//                   height: isVisible ? kToolbarHeight : 0,
//                   child: PreferredSize(
//                     preferredSize: const Size.fromHeight(kToolbarHeight),
//                     child: Center(
//                       child: ConstrainedBox(
//                         constraints: BoxConstraints(
//                           maxWidth: AppConstants.APP_MAX_WIDTH, // Restrict TabBar width
//                         ),
//                         child: TabBar(
//                           onTap: _handleTabTap, // Refactored scroll logic
//                           tabs: [
//                             Tab(icon: Icon(Icons.home), text: "Home"),
//                             Tab(icon: Icon(Icons.list), text: "My Posts"),
//                             Tab(
//                               icon: Stack(
//                                 children: [
//                                   Icon(Icons.notifications),
//                                   if (hasNewNotification)
//                                     Positioned(
//                                       right: 0,
//                                       top: 0,
//                                       child: Container(
//                                         width: 8,
//                                         height: 8,
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           shape: BoxShape.circle,
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                               text: "Notifications",
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             Expanded(
//               child: TabBarView(
//                 children: [
//                   Posts(tabController: _tabController, scrollController: _scrollController), // First tab: Posts screen
//                   MyPosts(tabController: _tabController, scrollController: _scrollController), // Second tab: My Posts
//                   NotificationsScreen(
//                     tabController: _tabController, scrollController: _scrollController,
//                     onNotificationsViewed: () {
//                       print("clear notifications sign from NotificationsScreen");
//                     },
//                   ), // Third tab: Notifications
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Handles tab tap interactions
//   void _handleTabTap(int index) {
//     if (index == 0 && _scrollController.hasClients) {
//       _scrollController.animateTo(
//         0.0,
//         duration: Duration(milliseconds: 500),
//         curve: Curves.easeInOut,
//       );
//     }
//   }
//
// // Widget _buildEmptyListView() {
// //   return ListView.builder(
// //     itemCount: 0, // Empty list
// //     itemBuilder: (context, index) {
// //       return ListTile(
// //         title: Text("Empty"),
// //       );
// //     },
// //   );
// // }
// }
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static final HiveDatabaseHelper _dbHelper2 = HiveDatabaseHelper.instance;
  // static late BuildContext context;
  static Future initialize(BuildContext context) async {
    CommonHelper.logDebug("inti PushNotificationService");
    // context = context1;
    await _fcm.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        sound: true
    );

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      CommonHelper.logDebug("Foreground Notification: ${message.notification?.title}");
      CommonHelper.logDebug("Notification Data: ${message.data["question_id"]}");
    });

    // Handle background notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      CommonHelper.logDebug("Notification Opened (Background): ${message.data["question_id"]}");

      // Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
      //   '/notifications',
      //       (route) => false, // remove all previous routes
      // );
      // Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
      //   '/notifications',
      //       (route) => false,
      // );
      final currentRoute = ModalRoute.of(context);
      if (currentRoute?.settings.name != '/notifications') {
        // Navigator.pushNamed(context, '/notifications');
        Navigator.pushReplacementNamed(context, '/notifications');
      }
      // Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
      //   '/notifications',
      //       (route) => false,
      // );

    });

    // Handle notification taps from a terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      CommonHelper.logDebug("Notification Opened (Terminated): ${initialMessage.data}");
      final currentRoute = ModalRoute.of(context);
      if (currentRoute?.settings.name != '/notifications') {
        // Navigator.pushNamed(context, '/notifications');
        Navigator.pushReplacementNamed(context, '/notifications');
      }
      // Navigate to Notifications screen
      // Navigator.of(context).pushNamed(
      //   '/notifications',
      //   arguments: initialMessage.data,
      // );
    }

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print('Got a message whilst in the foreground!');
    //   print('Message data: ${message.data}');
    //
    //   if (message.notification != null) {
    //     print('Message also contained a notification: ${message.notification}');
    //   }
    // });

    FirebaseMessaging.onBackgroundMessage(backgroundHandler);

    // Get the token
    await getToken();
  }

  static Future<void> backgroundHandler(RemoteMessage message) async {
    CommonHelper.logDebug('Handling a background message 1 ${message.messageId}');
    // Navigator.push(
    // context
    // ,
    //   MaterialPageRoute(
    //     builder: (context) => NotificationsScreen(
    //
    //     ),
    //   ),
    // );
  }

  static Future<String?> getToken() async {
    CommonHelper.logDebug("inside getToken");
    String? token = await _fcm.getToken();
    CommonHelper.logDebug('Token: $token');
    UserDTO? user = await _dbHelper2.getCurrentUser("cuser");
    await _registerPushToken(UserDTO(userID: user!.userID, deviceToken: token!));
    return token;
  }

  static Future<void> _registerPushToken(UserDTO user) async {
    CommonHelper.logDebug("incide _registerPushToken");

    final RESTUtil _registerToken = RESTUtil(
      baseUrl: AppConstants.URL_DEVICE_TOKEN,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    try {
      Map<String, String> requestBody = <String, String> {
        'json': '{"userID":"${user.userID}", "pushToken":"${user.deviceToken}"}'
      };
      final response = await _registerToken.postForm(_registerToken.baseUrl, requestBody);
      // final response = await _loginUser.postForm2(_loginUser.baseUrl, requestBody);
      CommonHelper.logDebug(response.toString());
      // final response = await _loginUser.loginTest(phoneNumber, _loginUser.baseUrl);
      final responseData = json.decode(response.body);

      if (responseData['error'] == false) {
        CommonHelper.logDebug("Token registered successfully");
        user.deviceToken = responseData["device_token"];
        await _dbHelper2.storeCurrentUser("cuser", user);

      } else {
        // _showErrorToast(responseData['error_msg'] ?? "An error occurred. Please try again.");
        // CommonHelper.logDebug("new user redirect to user registration");
        // await _registerUser(null);
      }
    } catch (e) {
      CommonHelper.logDebug("An error occurred: $e");
      // print(e);
      // await _registerUser(null);
    }
  }

}
