import 'package:Apviser/AppConstants.dart';
import 'package:Apviser/colours.dart';
import 'package:Apviser/models/PostsDTO.dart';
import 'package:Apviser/models/UserDTO.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import './post.dart';
import 'pages/create_post.dart';

class Posts extends StatefulWidget {
  TabController tabController;
  ScrollController scrollController;
  UserDTO? currentUser;

  Posts({required this.tabController, required this.scrollController, this.currentUser});
  @override
  _PostsState createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  // final
  late PostsModel posts;

  @override
  void initState() {
    // getToken();
    posts = PostsModel();
    widget.scrollController.addListener(() {
      if (widget.scrollController.position.maxScrollExtent == widget.scrollController.offset) {
        posts.loadMore();
      }
    });
    super.initState();
  }

  // getToken() async {
  //   String? deviceToken = await FirebaseMessaging.instance.getToken();
  //   CommonHelper.logDebug("token is $deviceToken");
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<PostDTO>>(
        stream: posts.stream,
        builder: (BuildContext context, AsyncSnapshot<List<PostDTO>> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            return RefreshIndicator(
              onRefresh: posts.refresh,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                controller: widget.scrollController,
                separatorBuilder: (context, index) => Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH), // Adjust max width as needed
                    child: Divider(thickness: 1),
                  ),
                ),
                itemCount: posts.data.length + 1,
                itemBuilder: (BuildContext _context, int index) {
                  if(index < posts.data!.length){
                    return Post(post: posts.data![index], onDelete: () {  }, showMenu: false, onEdit: () {}, showReportAbuse: true,);
                  } else if(posts.hasMore){
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    if(posts.hasMore){
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }else{
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: AppConstants.APP_MAX_WIDTH),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                            child: Text(
                              AppConstants.TEXT_NO_EXPERTISE,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            );
          }
        },
      ),
      // Floating action button for home screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showBottomDrawer(context); // Call method to show the bottom drawer
        },
        child: Icon(Icons.reviews, color: AppColors.secondary,),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positioned on the right
    );
  }

// Method to show the bottom drawer
  void _showBottomDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {


        return SafeArea( // Add SafeArea here
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Your existing options...
                _buildOption(
                    context,
                    Icons.traffic,
                    'Launch the ',
                    'Honk Poll', '',
                        () async => _navigateToCreateQuestionScreen(context, questionType: 'Normal Poll')
                ),
                _buildOption(
                    context,
                    Icons.bar_chart,
                    'Create a ',
                    'Custom Poll', '',
                        () => _navigateToCreateQuestionScreen(context, questionType: 'Custom Poll')
                ),
                _buildOption(
                    context,
                    Icons.question_answer,
                    'Get Answers to your ',
                    'Questions', '',
                        () => _navigateToCreateQuestionScreen(context, questionType: 'Answer Poll')
                ),
                _buildOption(
                    context,
                    Icons.handshake,
                    'Look for a ',
                    'SkillSwap',
                    '',
                        () => _navigateToCreateQuestionScreen(context, questionType: 'Handshake')
                ),
              ],
            ),
          ),
        );

        // return Container(
        //   padding: const EdgeInsets.all(16.0),
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //
        //     ],
        //   ),
        // );
      },
    );
  }

  void _navigateToCreateQuestionScreen (BuildContext context, {required String questionType}) async {
    final newPost = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePost(questionType: questionType, tabController: widget.tabController),  // Pass the tabController
      ),
    );

    // If a new post is returned, refresh the stream
    if (newPost != null) {
      setState(() {
        posts.addNewPost(newPost as PostDTO); // Add the new post to the stream
      });
    }
  }


// Method to build options in the bottom drawer
  Widget _buildOption(BuildContext context, IconData icon, String title, String highlightedText, String? explaination, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,  // Execute the provided function on tap
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 30),
            SizedBox(width: 16),
            RichText(
              text: TextSpan(
                text: title,
                style: TextStyle(color: Colors.black, fontSize: 16),
                children: [
                  TextSpan(
                    text: highlightedText,
                    style: TextStyle(
                      color: Colors.red, // Highlighted text color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              TextSpan(
                text: explaination,)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
