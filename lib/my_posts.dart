import 'package:flutter/material.dart';

import '../models.dart';
import './post.dart';
import 'AppConstants.dart';
import 'CommonHelper.dart';
import 'colours.dart';
import 'models/PostsDTO.dart';
import 'models/UserDTO.dart';
import 'pages/create_post.dart';

class MyPosts extends StatefulWidget {
  final TabController tabController;
  ScrollController scrollController;
  UserDTO? currentUser;

  MyPosts({required this.tabController, required this.scrollController, this.currentUser});
  @override
  MyPostsState createState() => MyPostsState();
}

class MyPostsState extends State<MyPosts> {

  late MyPostsModel posts;

  @override
  void initState() {
    posts = MyPostsModel();
    widget.scrollController.addListener(() {
      if (widget.scrollController.position.maxScrollExtent == widget.scrollController.offset) {
        posts.loadMore2();
      }
    });
    super.initState();
  }

  void _navigateToEditPost(PostDTO post, int index) async {
    CommonHelper.logDebug("_navigateToEditPost called with descr ${post.descr}");
    final updatedPost = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePost(
          postID: post.id!,
          userID: post.userId!,
          postData: post,
        ),
      ),
    );

    // If a result is returned, update the specific post in the list
    if (updatedPost != null && updatedPost is PostDTO) {
      setState(() {
        CommonHelper.logDebug("updating state...");
        posts.data2[index] = updatedPost; // Update the specific post in the list
      });
    }
  }


  // static void removeElement1(PostDTO ptdo){
  //   posts.data2.remove(ptdo);
  // }
  void removePost(PostDTO post) {
    setState(() {
      posts.data2.remove(post);  // Remove the post from the list
    });
  }
  // @override
  // void dispose() {
  //   scrollController.dispose();
  //   // posts.dispose(); // Dispose of the model to close the stream
  //   super.dispose();
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
                itemCount: posts.data2.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index < posts.data2!.length) {
                    final post = posts.data2![index];
                    return Post(
                      post: post,
                      showMenu: true,
                      onDelete: () => _removeItem(index),
                      onEdit: () => _navigateToEditPost(post, index), // Handle edit callback
                    );
                  } else if (posts.hasMore) {
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
                              AppConstants.TEXT_NO_POSTS,
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
    );
  }

  // Remove item from the list based on index
  void _removeItem(int index) {
    CommonHelper.logDebug("remove called at $index");
    setState(() {
      posts.data2.removeAt(index);
    });
  }
}
