import 'package:Apviser/colours.dart';
import 'package:flutter/material.dart';
import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../models.dart';
import '../models/NotificationDTO.dart';
import '../models/PostsDTO.dart';
import '../post_details_view.dart';
import 'friends_management.dart';

class NotificationsScreen extends StatefulWidget {
  final TabController? tabController;
  final VoidCallback?
      onNotificationsViewed; // Callback to reset notification badge
  ScrollController? scrollController;

  NotificationsScreen(
      {this.tabController, this.onNotificationsViewed, this.scrollController});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationsModel notifications;

  @override
  void initState() {
    notifications = NotificationsModel();
    widget.scrollController?.addListener(() {
      if (widget.scrollController?.position.maxScrollExtent ==
          widget.scrollController?.offset) {
        notifications.loadMore2();
      }
    });

    // Programmatically switch to Notifications Tab if tabController is available
    if (widget.tabController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.tabController!.animateTo(2); // 2 is the Notifications Tab index
      });
    }

    // Detect tab selection for callback
    widget.tabController?.addListener(() {
      if (widget.tabController?.index == 2) {
        CommonHelper.logDebug("clear notifications sign");
        widget.onNotificationsViewed?.call();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<NotificationDTO>>(
        stream: notifications.stream,
        builder: (BuildContext context,
            AsyncSnapshot<List<NotificationDTO>> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(
              child: SizedBox(
                width: AppConstants.APP_MAX_WIDTH,
                child: RefreshIndicator(
                  onRefresh: notifications.refresh,
                  child: notifications.data2!.isEmpty
                      ? ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: Text(
                            AppConstants.TEXT_NO_NOTIFICATIONS,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    controller: widget.scrollController,
                    separatorBuilder: (context, index) => Center(
                      child: Container(
                        constraints:
                        BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
                        child: const Divider(thickness: 1),
                      ),
                    ),
                    itemCount: notifications.data2!.length +
                        (notifications.hasMore ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index < notifications.data2!.length) {
                        final notification = notifications.data2![index];
                        return Container(
                          constraints: BoxConstraints(
                              maxWidth: AppConstants.APP_MAX_WIDTH),
                          child:
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                "${AppConstants.APVISER_IMAGES_PATH_FULL}${notification.friendPhoto!}",
                              ),
                              radius: 25.0,
                              onBackgroundImageError: (_, __) =>
                              const Icon(Icons.person, size: 40.0),
                            ),
                            title: SizedBox(
                              width: AppConstants.APP_MAX_WIDTH,
                              child: Text(
                                CommonHelper.htmlToTruncatedPlainText(
                                  notification.notificationDescr!,
                                  200,
                                ),
                              ),
                            ),
                            trailing: _getNotificationIcon(
                              notification.type!,
                              notification.notificationDescr!,
                              notification.questionType!,
                            ),
                            onTap: (notification.type == 1 ||
                                notification.type == 2 ||
                                notification.type == 5 ||
                                notification.type == 6)
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailsView(
                                    postDTO: PostDTO(
                                      questionId: notification.questionId,
                                      type: notification.questionType,
                                      descr: notification.questionDescr,
                                      options: notification.options,
                                      updatedOn: notification.timestamp,
                                    ),
                                  ),
                                ),
                              );
                            }
                                : (notification.type == 3 ||
                                notification.type == 4)
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendsManagementScreen(),
                                ),
                              );
                            }
                                : null, // Disable tap
                          )

                          // ListTile(
                          //   leading: CircleAvatar(
                          //     backgroundImage: NetworkImage(
                          //         "${AppConstants.APVISER_IMAGES_PATH_FULL}${notification.friendPhoto!}"),
                          //     radius: 25.0,
                          //     onBackgroundImageError: (_, __) =>
                          //     const Icon(Icons.person, size: 40.0),
                          //   ),
                          //   title: SizedBox(
                          //     width: AppConstants.APP_MAX_WIDTH,
                          //     child: Text(
                          //       CommonHelper.htmlToTruncatedPlainText(
                          //           notification.notificationDescr!, 200),
                          //     ),
                          //   ),
                          //   trailing: _getNotificationIcon(
                          //       notification.type!,
                          //       notification.notificationDescr!,
                          //       notification.questionType!),
                          //   onTap: () {
                          //     Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //         builder: (context) => PostDetailsView(
                          //           postDTO: PostDTO(
                          //             questionId: notification.questionId,
                          //             type: notification.questionType,
                          //             descr: notification.questionDescr,
                          //             options: notification.options,
                          //             updatedOn: notification.timestamp,
                          //           ),
                          //         ),
                          //       ),
                          //     );
                          //   },
                          // ),
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _getNotificationIcon(
      int notificationType, String notificationText, int questionType) {
    notificationText = notificationText
        .toLowerCase(); // Convert to lowercase for case-insensitive matching

    if (notificationText.contains("bumped")) {
      return Icon(Icons.trending_up, color: Colors.blue);
    } else if (notificationText.contains("replied")) {
      return Icon(Icons.reply, color: Colors.green);
    } else if (notificationText.contains("liked")) {
      return Icon(Icons.thumb_up, color: Colors.red);
    } else if (notificationText.contains("commented")) {
      return Icon(Icons.comment, color: Colors.purple);
    } else if (notificationText.contains("ready to offer")) {
      return Icon(Icons.local_offer, color: Colors.teal);
    } else if (notificationText.contains("recommends")) {
      return Icon(Icons.star, color: Colors.amber);
    } else if (notificationText.contains("voted bad")) {
      return Icon(Icons.thumb_down, color: Colors.redAccent);
    } else if (notificationText.contains("voted good")) {
      return Icon(Icons.thumb_up, color: Colors.greenAccent);
    } else if (notificationText.contains("voted normal")) {
      return Icon(Icons.thumbs_up_down, color: Colors.grey);
    } else if (notificationText.contains("withdrawn")) {
      return Icon(Icons.remove_circle, color: Colors.orange);
    }

    // Handle poll types when someone asked a question
    if (notificationType == 1) {
      switch (questionType) {
        case 1:
          return Icon(Icons.traffic, color: AppColors.primary);
        case 3:
          return Icon(Icons.poll, color: AppColors.primary);
        case 4:
          return Icon(Icons.handshake, color: AppColors.primary);
        case 2:
          return Icon(Icons.question_answer, color: AppColors.primary);
        default:
          return Icon(Icons.notification_important, color: AppColors.primary);
      }
    }

    // If no specific text matches, use notification type
    switch (notificationType) {
      // case 1:
      //   return Icon(Icons.question_mark, color: Colors.blue);
      case 2:
        return Icon(Icons.question_answer, color: Colors.orange);
      case 3:
        return Icon(Icons.person_add, color: Colors.blueAccent);
      case 4:
        return Icon(Icons.handshake, color: Colors.green);
      case 5:
        return Icon(Icons.thumb_up, color: Colors.red);
      case 6:
        return Icon(Icons.comment, color: Colors.purple);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

// Widget _getNotificationIcon(int questionType) {
  //   switch (questionType) {
  //     case 1 || 3:
  //       return Icon(Icons.thumb_up, color: Colors.blue);
  //     case 4:
  //       return Icon(Icons.handshake, color: Colors.green);
  //     case 2:
  //       return Icon(Icons.question_answer, color: Colors.orange);
  //     default:
  //       return Icon(Icons.notification_important, color: Colors.grey);
  //   }
  // }
}
