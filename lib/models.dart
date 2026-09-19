import 'dart:async';
import 'dart:convert';
import 'package:Apviser/models/NotificationDTO.dart';

import 'AppConstants.dart';
import './models/PostsDTO.dart';
import 'CommonHelper.dart';
import 'DatabaseHelper.dart';
import 'models/UserDTO.dart';
import 'pages/search.dart';
import 'rest_util.dart';

class PostsModel {
  late Stream<List<PostDTO>> stream;
  late bool hasMore;

  late bool _isLoading;
  late List<PostDTO> data;
  late StreamController<List<PostDTO>> _controller;
  late String createdOn;

  String url1 = AppConstants.GET_PUBLIC_ITEMS2;
  String url2 = AppConstants.GET_PUBLIC_ITEMS;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

  PostsModel() {
    data = <PostDTO>[];
    _controller = StreamController<List<PostDTO>>.broadcast();
    _isLoading = false;
    createdOn = DateTime.now().toString();
    stream = _controller.stream.map((List<PostDTO> postsData) {
      return postsData.toList();
    });
    //     .map((event) => (event) {
    //   return postsData;
    // });
    //     .map((List<Map> postsData) {
    //   return postsData.map((Map postData) {
    //     return PostDTO.fromJson(postData);
    //   }).toList();
    // });
    hasMore = true;
    refresh();
  }

  void addNewPost(PostDTO post) {
    // Add the new post to the top of the list
    data.insert(0, post);
    _controller.add(data); // Update the stream with the new list
  }

  Future<List<PostDTO>> _getPostsData(String createdOn, String requestURL) async {
    final RESTUtil _getPosts = RESTUtil(
      baseUrl: requestURL,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );
    CommonHelper.logDebug("_getExampleServerData called with $createdOn $requestURL");
    List<PostDTO> list = [];

    try {
      // Fetch the current user from the local database (Hive in this case)
      UserDTO? user = await _dbHelper.getCurrentUser("cuser");

      if (user != null) {
        CommonHelper.logDebug("Retrieved user: ${user.fullName}, ${user.userID}");
      } else {
        CommonHelper.logDebug("No user found in models");
        throw Exception('No user found');
      }

      // Construct the request payload
      Map<String, String> requestBody = <String, String> {
        'json': json.encode({
          "id": user.userID.toString(),
          "createdOn": createdOn,
          "limit": 5,
          "expertiseCSV": [] // Example IDs; you may replace with dynamic data
        })
      };

      CommonHelper.logDebug("Request body in models is ${requestBody.toString()}");

      // Make the POST request using RESTUtil
      final response = await _getPosts.postForm(requestURL, requestBody);

      // Check the response status and handle accordingly
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        list = List<PostDTO>.from(parsed.map((model) => PostDTO.fromJson(model)));
      } else {
        throw Exception('Failed to fetch posts');
      }
    } catch (error) {
      CommonHelper.logDebug("Error: $error");
      throw Exception('Failed to fetch posts');
    }

    return list;
  }

  Future<void> refresh() {
    return loadMore(clearCachedData: true);
  }

  Future<void> loadMore({bool clearCachedData = false}) {
    CommonHelper.logDebug("load more");
    String url = url1;
    if(data.isEmpty == false){
      if(data.last.createdOn!.isEmpty){
        createdOn="";
      }else{
        createdOn=data.last.id.toString();
        CommonHelper.logDebug("createdOn is ${createdOn}");
        url = url2;
      }
    }

    if (clearCachedData) {
      //_data = List<PostDTO>();
      hasMore = true;
    }
    if (_isLoading || !hasMore) {
      CommonHelper.logDebug(_isLoading.toString());
      //return Future.value();
    }
    _isLoading = true;
    //createdOn = _data.last.createdOn.toString();
    return _getPostsData(createdOn, url).then((postsData) {
      _isLoading = false;
      data.addAll(postsData);
      hasMore = (postsData.length < 20)?false:true;
      _controller.add(data);
    });
  }
}

class MyPostsModel {
  late Stream<List<PostDTO>> stream;
  late bool hasMore;

  late bool _isLoading;
  late List<PostDTO> data2;
  late StreamController<List<PostDTO>> _controller;
  late String createdOn2;

  String url1 = AppConstants.MY_QUESTIONS2;
  String url2 = AppConstants.GET_CREATED_ITEMS;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

  MyPostsModel() {
    data2 = <PostDTO>[];
    _controller = StreamController<List<PostDTO>>.broadcast();
    _isLoading = false;
    createdOn2 = "null";
    stream = _controller.stream.map((List<PostDTO> postsData) {
      return postsData.toList();
    });

    hasMore = true;
    refresh();
  }

  // Add deletePost method
  Future<void> deletePost(PostDTO post) async {
    CommonHelper.logDebug("**delete called with ${post.descr}**");
    data2.remove(post); // Remove the post from the internal list
    _controller.add(data2); // Update the stream with the new list
  }

  Future<List<PostDTO>> _getMyPostsData(String updatedOn, String requestURL) async {
    final RESTUtil _getPosts = RESTUtil(
      baseUrl: requestURL,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );
    CommonHelper.logDebug("_getMyPostsData called with $updatedOn $requestURL");
    List<PostDTO> list = [];

    try {
      // Fetch the current user from the local database (Hive in this case)
      UserDTO? user = await _dbHelper.getCurrentUser("cuser");

      if (user != null) {
        CommonHelper.logDebug("Retrieved user: ${user.fullName}, ${user.userID}");
      } else {
        CommonHelper.logDebug("No user found in models");
        throw Exception('No user found');
      }

      // Construct the request payload
      Map<String, String> requestBody = <String, String>{
        'json': json.encode({
          "id": user.userID.toString(),
          "createdOn": updatedOn,
          "limit": AppConstants.INITITAL_QUESTIONS_FETCH,
        })
      };

      CommonHelper.logDebug("Request body in models is ${requestBody.toString()}");

      // Make the POST request using RESTUtil
      final response = await _getPosts.postForm(requestURL, requestBody);

      // Check the response status and handle accordingly
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        list = List<PostDTO>.from(parsed.map((model) => PostDTO.fromJson(model)));
      } else {
        throw Exception('Failed to fetch posts');
      }
    } catch (error) {
      CommonHelper.logDebug("Error: $error");
      throw Exception('Failed to fetch posts');
    }

    return list;
  }

  Future<void> refresh() {
    return loadMore2(clearCachedData: true);
  }

  Future<void> loadMore2({bool clearCachedData = false}) {
    CommonHelper.logDebug("load more");
    String url = url1;
    if(data2.isEmpty == false){
      if(data2.last.createdOn!.isEmpty){
        createdOn2="";
      }else{
        createdOn2=data2.last.id.toString();
        CommonHelper.logDebug("createdOn is ${createdOn2}");
        url = url2;
      }
    }

    if (clearCachedData) {
      //_data = List<PostDTO>();
      hasMore = true;
    }
    if (_isLoading || !hasMore) {
      CommonHelper.logDebug(_isLoading.toString());
      //return Future.value();
    }
    _isLoading = true;
    //createdOn = _data.last.createdOn.toString();
    return _getMyPostsData(createdOn2, url).then((myPostsData) {
      _isLoading = false;
      data2.addAll(myPostsData);
      hasMore = (myPostsData.length < 20)?false:true;
      _controller.add(data2);
    });
  }

  void dispose() {
    _controller.close();
  }

}

class SearchPostsModel {
  late Stream<List<PostDTO>> stream;
  late bool hasMore;

  late bool _isLoading;
  late List<PostDTO> data2;
  late StreamController<List<PostDTO>> _controller;
  late int maxID;

  String url1 = AppConstants.SEARCH_POSTS;
  // String url2 = AppConstants.SEARCH_POSTS;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  String descr="";
  List<int> expertiseIds=[];

  SearchPostsModel(String descr, List<int> expertiseIds) {
    data2 = <PostDTO>[];
    _controller = StreamController<List<PostDTO>>.broadcast();
    _isLoading = false;
    maxID = 0;
    this.expertiseIds = expertiseIds;
    this.descr = descr;
    stream = _controller.stream.map((List<PostDTO> postsData) {
      return postsData.toList();
    });

    hasMore = true;
    if(expertiseIds.length>0)
      refresh();
  }

  // // Add deletePost method
  // Future<void> deletePost(PostDTO post) async {
  //   print("**delete called with ${post.descr}**");
  //   data2.remove(post); // Remove the post from the internal list
  //   _controller.add(data2); // Update the stream with the new list
  // }

  Future<List<PostDTO>> getSearchPostsData(String descr1, List<int> expertiseIds1, {int showPublicPosts=0}) async {
    final RESTUtil _getPosts = RESTUtil(
      baseUrl: url1,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    List<PostDTO> list = [];
    this.expertiseIds = expertiseIds1;
    try {
      // Fetch the current user from the local database (Hive in this case)
      UserDTO? user = await _dbHelper.getCurrentUser("cuser");

      if (user != null) {
        CommonHelper.logDebug("Retrieved user: ${user.fullName}, ${user.userID}");
      } else {
        CommonHelper.logDebug("No user found in models");
        throw Exception('No user found');
      }

      // Construct the request payload
      Map<String, String> requestBody = <String, String>{
        'json': json.encode({
          "user_id":user.userID,
          "descr": descr1,
          "expertise_csv": expertiseIds1,
          "max_question_id": this.maxID,
          if(showPublicPosts==1)"show_public_posts": showPublicPosts,
        })
      };

      CommonHelper.logDebug("Request body in models is ${requestBody.toString()}");

      // Make the POST request using RESTUtil
      final response = await _getPosts.postForm(url1, requestBody);

      // Check the response status and handle accordingly
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        list = List<PostDTO>.from(parsed.map((model) => PostDTO.fromJson(model)));
        // SearchPageState.isLoading=false;
      } else {
        throw Exception('Failed to fetch posts');
      }
    } catch (error) {
      CommonHelper.logDebug("Error: $error");
      throw Exception('Failed to fetch posts');
    }

    return list;
  }

  Future<void> refresh() {
    return loadMoreSearch(clearCachedData: true);
  }

  Future<void> loadMoreSearch({bool clearCachedData = false, String tdescr=""}) {
    CommonHelper.logDebug("load more");
    // String url = url1;
    if(data2.isEmpty == false){
      if(data2.last.createdOn!.isEmpty){
        maxID=0;
      }else{
        maxID=data2.last.id!.toInt();
        CommonHelper.logDebug("max_question_id is ${maxID}");
        // url = url2;
      }
    }

    if (clearCachedData) {
      //_data = List<PostDTO>();
      hasMore = true;
    }
    if (_isLoading || !hasMore) {
      CommonHelper.logDebug(_isLoading.toString());
      //return Future.value();
    }
    _isLoading = true;
    //createdOn = _data.last.createdOn.toString();
    return getSearchPostsData(tdescr, this.expertiseIds).then((searchPostsData) {
      _isLoading = false;
      data2.addAll(searchPostsData);
      hasMore = (searchPostsData.length < 20)?false:true;
      _controller.add(data2);
    });
  }

  void dispose() {
    _controller.close();
  }

}

class NotificationsModel {
  late Stream<List<NotificationDTO>> stream;
  late bool hasMore;

  late bool _isLoading;
  late List<NotificationDTO> data2;
  late StreamController<List<NotificationDTO>> _controller;
  late int maxID;

  String url1 = AppConstants.USER_NOTIFICATIONS;
  // String url2 = AppConstants.GET_CREATED_ITEMS;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

  NotificationsModel() {
    data2 = <NotificationDTO>[];
    _controller = StreamController<List<NotificationDTO>>.broadcast();
    _isLoading = false;
    maxID = 0;
    stream = _controller.stream.map((List<NotificationDTO> postsData) {
      return postsData.toList();
    });

    hasMore = true;
    refresh();
  }

  // // Add deletePost method
  // Future<void> deletePost(PostDTO post) async {
  //   CommonHelper.logDebug("**delete called with ${post.descr}**");
  //   data2.remove(post); // Remove the post from the internal list
  //   _controller.add(data2); // Update the stream with the new list
  // }

  Future<List<NotificationDTO>> _getNotificationsData(int maxID, String requestURL) async {
    final RESTUtil _getNotifications = RESTUtil(
      baseUrl: requestURL,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );
    CommonHelper.logDebug("_getNotificationsData called with $maxID $requestURL");
    List<NotificationDTO> list = [];

    try {
      // Fetch the current user from the local database (Hive in this case)
      UserDTO? user = await _dbHelper.getCurrentUser("cuser");

      if (user != null) {
        CommonHelper.logDebug("Retrieved user: ${user.fullName}, ${user.userID}");

        String finalURL = "$requestURL${user.userID}/$maxID";

        // Make the POST request using RESTUtil
        final response = await _getNotifications.get(finalURL);

        // Check the response status and handle accordingly
        if (response.statusCode == 200) {
          final parsed = jsonDecode(response.body);
          list = List<NotificationDTO>.from(parsed.map((model) => NotificationDTO.fromJson(model)));
        } else {
          throw Exception('Failed to fetch posts');
        }

      } else {
        CommonHelper.logDebug("No user found in models");
        throw Exception('No user found');
      }

    } catch (error) {
      CommonHelper.logDebug("Error: $error");
      throw Exception('Failed to fetch posts');
    }

    return list;
  }

  Future<void> refresh() {
    return loadMore2(clearCachedData: true);
  }

  Future<void> loadMore2({bool clearCachedData = false}) {
    CommonHelper.logDebug("load more");
    String url = url1;
    if(data2.isEmpty == false){
      if(data2.last.timestamp!.isEmpty){
        maxID=0;
      }else{
        maxID=data2.last.id!;
        CommonHelper.logDebug("createdOn is ${maxID}");
        // url = url2;
      }
    }

    if (clearCachedData) {
      //_data = List<PostDTO>();
      hasMore = true;
    }
    if (_isLoading || !hasMore) {
      CommonHelper.logDebug(_isLoading.toString());
      //return Future.value();
    }
    _isLoading = true;
    //createdOn = _data.last.createdOn.toString();
    return _getNotificationsData(maxID, url).then((myPostsData) {
      _isLoading = false;
      data2.addAll(myPostsData);
      hasMore = (myPostsData.length < 20)?false:true;
      _controller.add(data2);
    });
  }

  void dispose() {
    _controller.close();
  }

}

class UserPostsModel {
  late Stream<List<PostDTO>> stream;
  late bool hasMore;

  late bool _isLoading;
  late List<PostDTO> data2;
  late StreamController<List<PostDTO>> _controller;
  late int maxID;
  late int userID;

  String url1 = AppConstants.USER_POSTS;
  // String url2 = AppConstants.SEARCH_POSTS;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  // String descr="";
  // List<int> expertiseIds=[];

  UserPostsModel(UserDTO user) {
    data2 = <PostDTO>[];
    _controller = StreamController<List<PostDTO>>.broadcast();
    _isLoading = false;
    maxID = 0;
    userID= user.userID;
    // this.expertiseIds = expertiseIds;
    // this.descr = descr;
    stream = _controller.stream.map((List<PostDTO> postsData) {
      return postsData.toList();
    });

    hasMore = true;
    // if(expertiseIds.length>0)
      refresh();
  }

  // // Add deletePost method
  // Future<void> deletePost(PostDTO post) async {
  //   print("**delete called with ${post.descr}**");
  //   data2.remove(post); // Remove the post from the internal list
  //   _controller.add(data2); // Update the stream with the new list
  // }

  Future<List<PostDTO>> getUserPostsData(int userID) async {
    final RESTUtil _getPosts = RESTUtil(
      baseUrl: url1,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    List<PostDTO> list = [];

    try {
      // Fetch the current user from the local database (Hive in this case)
      // UserDTO? user = await _dbHelper.getCurrentUser("cuser");

      if (userID > 0) {
        CommonHelper.logDebug("Retrieved user: ${userID}");
      } else {
        CommonHelper.logDebug("No user found in models");
        throw Exception('No user found');
      }

      // Construct the request payload
      // Map<String, String> requestBody = <String, String>{
      //   'json': json.encode({
      //     "user_id":user.userID,
      //     "descr": descr1,
      //     "expertise_csv": expertiseIds1,
      //     "max_question_id": this.maxID,
      //     if(showPublicPosts==1)"show_public_posts": showPublicPosts,
      //   })
      // };

      // CommonHelper.logDebug("Request body in models is ${requestBody.toString()}");

      // Make the POST request using RESTUtil
      final response = await _getPosts.get("${url1}${userID}/${maxID}", requireAuth: true);

      // Check the response status and handle accordingly
      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        list = List<PostDTO>.from(parsed.map((model) => PostDTO.fromJson(model)));
        // SearchPageState.isLoading=false;
      } else {
        throw Exception('Failed to fetch posts');
      }
    } catch (error) {
      CommonHelper.logDebug("Error: $error");
      throw Exception('Failed to fetch posts');
    }

    return list;
  }

  Future<void> refresh() {
    return loadMore2(clearCachedData: true);
  }

  Future<void> loadMore2({bool clearCachedData = false}) {
    CommonHelper.logDebug("load more");
    // String url = url1;
    if(data2.isEmpty == false){
      if(data2.last.createdOn!.isEmpty){
        maxID=0;
      }else{
        maxID=data2.last.id!.toInt();
        CommonHelper.logDebug("max_question_id is ${maxID}");
        // url = url2;
      }
    }

    if (clearCachedData) {
      //_data = List<PostDTO>();
      hasMore = true;
    }
    if (_isLoading || !hasMore) {
      CommonHelper.logDebug(_isLoading.toString());
      //return Future.value();
    }
    _isLoading = true;
    //createdOn = _data.last.createdOn.toString();
    return getUserPostsData(userID).then((searchPostsData) {
      _isLoading = false;
      data2.addAll(searchPostsData);
      hasMore = (searchPostsData.length < 20)?false:true;
      _controller.add(data2);
    });
  }

  void dispose() {
    _controller.close();
  }

}