import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart' show kIsWeb;
//import 'package:flutter/foundation.dart' as foundation;
import 'package:sentry_flutter/sentry_flutter.dart';
import './models/PostsDTO.dart';

class CommonHelper{
  static String getPostAge(PostDTO postDTO){
    String timeDiffence = getTimeDiffence(postDTO.updatedOn.toString());
    return timeDiffence;
  }

   static String getTimeDiffence(String date){
    // just some checks to keep everything in order

    String retVal = "";
    var updatedAt = DateTime.parse(date);
    DateTime currentDate = DateTime.now();
    int rt = currentDate.millisecondsSinceEpoch - updatedAt.millisecondsSinceEpoch;
    int timeinseconds = (rt/1000).toInt();

    int mHour = (timeinseconds / 3600).toInt();
    int mMinute = ((timeinseconds) / 60).toInt();
    int days  = (mHour/24).toInt();
    int weeks = (days/7).toInt();
    int month = (weeks/4).toInt();
    int year = (month/12).toInt();

    if (mMinute < 60) {
      retVal = "Just Now";
    }
    if (mMinute > 60) {
      retVal = (mHour.toString()+" Hours ago");
    }

    if (days == 1) {
      retVal = days.toString()+" day ago";
    }else if(days > 1){
      retVal = days.toString()+" days ago";
    }

    if (weeks == 1) {
      retVal = weeks.toString()+" week ago";
    }else if(weeks > 1){
      retVal = weeks.toString()+" weeks ago";
    }

    if (month == 1) {
      retVal = month.toString()+" month ago";
    }else if(month > 1){
      retVal = month.toString()+" months ago";
    }

    if (year == 1) {
      retVal = year.toString()+" year ago";
    }else if(year > 1){
      retVal = year.toString()+" years ago";
    }

    return retVal;

  }

  static void showMessage(BuildContext context, String message, int timeInSeconds) {
    // final snackBar = SnackBar(
    //   content: Text(message),
    //   duration: Duration(seconds: timeInSeconds),
    //   backgroundColor: Colors.green,
    //   action: SnackBarAction(
    //     label: 'Dismiss',
    //     textColor: Colors.white,
    //     onPressed: () {}, // Optionally handle dismiss action
    //   ),
    // );
    // ScaffoldMessenger.of(context).showSnackBar(snackBar);

    showCustomToast(context, message, Duration(seconds: 5));

  }

  static String htmlToTruncatedPlainText(String html, int maxLength) {
    final parsed = html_parser.parse(html);
    final plainText = parsed.body?.text.trim() ?? '';

    if (plainText.length <= maxLength) return plainText;
    return plainText.substring(0, maxLength).trim() + '...';
  }

  static String truncateText(String text) {
    return
      text.length > 100
          ? '${text.substring(0, 100)}...'
          : text;
  }

  static void logDebug(
      String message, {
        bool addToCrashLatics = false, // Disables Crashlytics if false
        bool sendToSentry = false,     // Optional: Enable Sentry logging
        dynamic exception,
        dynamic stackTrace,

      }) {
    // Always print in debug mode
    if (kDebugMode) {
      print('[DEBUG] $message');
    }else{
      Sentry.captureException(message); // capture all messages
    }

    // Log to Crashlytics (mobile only, if enabled)
    if (addToCrashLatics && !kIsWeb) {
      FirebaseCrashlytics.instance.log(message);
      FirebaseCrashlytics.instance.recordError(
        Exception('Manual log event'),
        null,
        reason: message,
        fatal: false,
      );
    }

    // Log to Sentry (if enabled and not in debug mode)
    if (sendToSentry && !kDebugMode) {
      Sentry.captureException(exception, stackTrace: stackTrace);

      // StateError('This is test exception');
    }
  }

  // static void logDebug(String message, {bool addToCrashLatics = false}) {
  //   if (foundation.kDebugMode) print(message);
  //
  //   if (addToCrashLatics && !kIsWeb) {
  //     FirebaseCrashlytics.instance.log(message);
  //     FirebaseCrashlytics.instance.recordError(
  //       Exception('Manual log event'),
  //       null,
  //       reason: message,
  //       fatal: false,
  //     );
  //   }
  // }

  // static void logDebug(String message, bool addToCrashLatics = false) {
  //   if (kDebugMode) print(message);
  // }

  // static void logDebug(String message, {bool addToCrashLatics = false}) {
  //   if (kDebugMode) print(message);
  //   if (addToCrashLatics) {
  //     FirebaseCrashlytics.instance.log(message);
  //     FirebaseCrashlytics.instance.recordError(
  //       Exception('Manual log event'), // dummy exception for context
  //       null,
  //       reason: message,
  //       fatal: false,
  //     );
  //   }
  // }

}




class CustomToast extends StatelessWidget {
  final String message;

  const CustomToast({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

void showCustomToast(BuildContext context, String message, Duration duration) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => CustomToast(message: message),
  );

  Overlay.of(context)?.insert(overlayEntry);

  Future.delayed(duration, () {
    overlayEntry.remove();
  });
}

