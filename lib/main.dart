import 'dart:async';
import 'package:Apviser/colours.dart';
import 'package:Apviser/models/UserDTO.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import './pages/home.dart';
import './pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'AppConstants.dart';
import 'CommonHelper.dart';
import 'DatabaseHelper.dart';
import './models/PostsDTO.dart';
import 'package:flutter/material.dart';
import 'pages/PublicPostsPage.dart';
import 'pages/not_found.dart';
import 'pages/single.dart';
import 'pages/splash.dart';
import 'package:flutter/foundation.dart';

// Required for kIsWeb

AndroidNotificationChannel channel = const AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
  'This channel is used for important notifications.', // description
  importance: Importance.high,
);

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

PostDTO params = PostDTO();
PostDTO getParams() {
  PostDTO postDTO = PostDTO();
  return postDTO;
}

Future<void> main() async {
  // SplashScreen();
  if(!kDebugMode){
    runZonedGuarded(() async {
      await SentryFlutter.init(
            (options) {
          options.dsn = 'https://e32e8ed3ede2eaa8a8faadd953cda871@o4509433638027264.ingest.us.sentry.io/4509433639927808';
        },
      );
      //runApp(MyApp());
    }, (exception, stackTrace) async {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    });
  }

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    try {
      if (kIsWeb) {
        // Firebase initialization for Web
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyDYXiiHxaDIUBoMr5z9y7-ip_yc8OFcvJA",
            authDomain: "apviser-72c4e.firebaseapp.com",
            databaseURL: "https://apviser-72c4e.firebaseio.com",
            projectId: "apviser-72c4e",
            storageBucket: "apviser-72c4e.appspot.com",
            messagingSenderId: "453905060766",
            appId: "1:453905060766:web:09129efcfc43ba5e29fc8f",
          ),
        );

      } else {
        // Firebase initialization for Android & iOS (Uses google-services.json)
        await Firebase.initializeApp();
      }
      // ✅ Enable Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      // ✅ Catch Flutter framework errors
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      // ✅ Catch Dart async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      CommonHelper.logDebug("Firebase initialized successfully!");
    } catch (e, stack) {
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Firebase init failed');
      CommonHelper.logDebug("Error initializing Firebase: $e");
    }
    // await SentryFlutter.init(
    //       (options) {
    //     options.dsn = 'https://e32e8ed3ede2eaa8a8faadd953cda871@o4509433638027264.ingest.us.sentry.io/4509433639927808';
    //     // Adds request headers and IP for users,
    //     // visit: https://docs.sentry.io/platforms/dart/data-management/data-collected/ for more info
    //     options.sendDefaultPii = true;
    //   },
    //   appRunner: () {
    //     //Logger.confirmSentryInitialized(); // <-- Add this line
    //     CommonHelper.logDebug("✅ Sentry initialized successfully!");
    //     //runApp(SentryWidget(child: MyApp()));
    //   },
    // );

    runApp(MyApp());
  }


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //_notificationService.initialize();
    return
      MaterialApp(
        title: 'Apviser',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          focusColor: AppColors.secondary,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/',
        home: SplashScreenLoader(),
        onGenerateRoute: (settings) {
          Uri uri = Uri.parse(settings.name ?? '');

          // if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'single') {
          //   final questionId = int.tryParse(uri.pathSegments[1]);
          //   if (questionId != null) {
          //     return MaterialPageRoute(
          //       builder: (_) => SinglePostPage(questionId: questionId, slug: ,),
          //     );
          //   }
          // }

          if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'single') {
            final segment = uri.pathSegments[1];
            final questionId = int.tryParse(segment);

            if (questionId != null) {
              // Handle numeric ID case
              return MaterialPageRoute(
                builder: (_) => SinglePostPage(questionId: questionId, slug: ''),
              );
            } else {
              // Handle slug case
              return MaterialPageRoute(
                builder: (_) => SinglePostPage(questionId: -1, slug: segment),
              );
            }
          }

          // Fallback to 404
          return MaterialPageRoute(builder: (_) => NotFoundPage());
        },
        onUnknownRoute: (settings) => MaterialPageRoute(builder: (_) => NotFoundPage()),

        routes: {
          // '/notifications': (context) =>
          //     NotificationsScreen(tabController: DefaultTabController.of(context)),
          // '/notifications': (context) => DefaultTabController(
          //   length: 3,
          //   initialIndex: 2, // Open the Notifications tab
          //   child: Home(title: 'Apviser'), // The widget that contains all 3 tabs
          // ),
          // '/notifications': (context) {
          //   final settings = ModalRoute.of(context)!.settings;
          //   final args = settings.arguments as int? ?? 0;
          //
          //   return DefaultTabController(
          //     length: 3,
          //     initialIndex: args, // 👈 dynamic tab index
          //     child: Home(title: 'Apviser'),
          //   );
          // },
          '/notifications': (context) => Home(initialTabIndex: 2, title: 'Apviser',),
          '/login': (context) => LoginPage(),
          '/public': (context) => PublicPostsPage(),
        },
      );

  }
}

class SplashScreenLoader extends StatefulWidget {
  @override
  _SplashScreenLoaderState createState() => _SplashScreenLoaderState();
}

class _SplashScreenLoaderState extends State<SplashScreenLoader> {
  bool _isInitialized = false;

  @override
  void initState() {
    // super.initState();

    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    CommonHelper.logDebug("inti _initializeApp()");
    // Simulate some startup work like loading data, initializing services, etc.
    // await Future.delayed(Duration(milliseconds: 500));
    //WidgetsFlutterBinding.ensureInitialized();

    HiveDatabaseHelper.initHive();
    // PushNotificationService _notificationService = PushNotificationService();
    //PushNotificationService.initialize();
    // _notificationService.initialize();
    /*------------------------------Firebase Init-------------------------------*/
    FlutterNativeSplash.remove();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),  // Set a maximum width for larger screens
          child: AuthWrapper(),  // Your actual home screen content
        ),
      );
    } else {
      return Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),  // Set a maximum width for larger screens
          child: SplashScreen(),  // Your splash screen content
        ),
      );
    }
  }

}

class AuthWrapper extends StatelessWidget {
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  late UserDTO? cuser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (authSnapshot.hasData) {
          CommonHelper.logDebug("User is authenticated with Firebase. UID: ${authSnapshot.data!.uid}");
          return FutureBuilder<UserDTO?>(
            future: _initializeUser(),
            builder: (context, localUserSnapshot) {
              if (localUserSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (localUserSnapshot.hasData && localUserSnapshot.data != null && localUserSnapshot.data!.userID > 0) {
                CommonHelper.logDebug("Local user data found: ${localUserSnapshot.data!.userID}");
                return Home(title: 'Apviser', currentUser: localUserSnapshot.data);
              } else {
                CommonHelper.logDebug("No valid local user data found after Firebase auth.");
                // Optionally handle the case where Firebase user exists but local data is missing
                // You might want to fetch user data from network and store it locally here
                return Home(title: 'Apviser', currentUser: cuser); // Or a loading screen
              }
            },
          );
        } else {
          CommonHelper.logDebug("User is not authenticated with Firebase.");
          return LoginPage(); // Or OtpVerificationPage if needed
          // return UserInfoPage(phoneNumber: "widget.phoneNumber");
        }
      },
    );
  }

  Future<UserDTO?> _initializeUser() async {
    cuser = await _dbHelper.getCurrentUser("cuser");
    return cuser;
    // setState(() {}); // Trigger a rebuild when user data is available
    CommonHelper.logDebug("Initialized user in Home: ${cuser?.userID}");
  }

}


