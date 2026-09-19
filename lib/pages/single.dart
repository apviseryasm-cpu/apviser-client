import 'dart:convert';

import 'package:flutter/material.dart';
// Detect if running on web
import 'package:Apviser/widgets/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../AppConstants.dart';
import '../CommonHelper.dart';
import '../DatabaseHelper.dart';
import '../models/PostsDTO.dart';
import '../models/UserDTO.dart';
import '../rest_util.dart';
import '../widgets/cards/answer_card.dart';
import '../widgets/cards/custom_poll_card.dart';
import '../widgets/cards/handshake_card.dart';
import '../widgets/cards/normal_poll_card.dart';
import '../widgets/select_expertise2.dart';
import 'not_found.dart';

class SinglePostPage extends StatefulWidget {
  List<ValueItem<String>>? initialSelectedOptions;
  bool? isLoading = true;
  final int questionId;
  final String slug;

  SinglePostPage(
      {
        // this.initialSelectedOptions,
        // this.initSearchString,
  required this.questionId, required this.slug
        // this.cameThrough
      }); // Allow initialization with a hashtag

  @override
  SinglePostPageState createState() => SinglePostPageState();
}

class SinglePostPageState extends State<SinglePostPage> {
  final TextEditingController _searchController = TextEditingController();

  // late SearchPostsModel posts;
  final ScrollController scrollController = ScrollController();
  // final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  // UserDTO? user;
  bool isExpanded = true; // Track the visibility of the search controls
  // bool showWheel = false;
  // bool isSearching = false; // To track if the search is in progress
  late PostDTO? singlePost;

  @override
  void initState() {
    super.initState();
    singlePost = PostDTO();

    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // user = await _dbHelper.getCurrentUser("cuser");
    await getPostDetails();
    setState(() {
      widget.isLoading = false; // Start loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: singlePost?.descr != null
            ? CommonHelper.truncateText(singlePost!.descr!)
            : "Loading...",
        showBackButton: false,
      ),
      body: widget.isLoading!
          ? Center(child: CircularProgressIndicator())
          : singlePost == null
          ? Center(child: Text("Post not found"))
          : SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // 🔒 Non-interactive post content with constrained width
              AbsorbPointer(
                absorbing: true,
                child: Opacity(
                  opacity: 0.7,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppConstants.APP_MAX_WIDTH,
                    ),
                    child: Column(
                      children: [
                        if (singlePost!.type == 1) NormalCard(singlePost!)
                        else if (singlePost!.type == 2) AnswerCard(singlePost!)
                        else if (singlePost!.type == 3) CustomPollCard(singlePost!)
                          else if (singlePost!.type == 4) HandshakePollCard(singlePost!)
                            else NormalCard(singlePost!),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🌐 Clickable website link (still within same constrained width)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppConstants.APP_MAX_WIDTH,
                ),
                child: TextButton.icon(
                  onPressed: () async {
                    final url = Uri.parse("https://apviser.com");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: Icon(Icons.public, color: Colors.blueAccent),
                  label: Text(
                    "Explore more on apviser.com",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getPostDetails() async {
    // UserDTO? user = await _dbHelper.getCurrentUser("cuser");

    final RESTUtil restUtil = RESTUtil(
      baseUrl: AppConstants.ANSWERS_DETAILS_BY_QUESTION,
      username: AppConstants.CREDENTIALS_USERNAME,
      password: AppConstants.CREDENTIALS_PASSWORD,
    );

    final Map<String, dynamic> payload = {
      'question_id': widget.questionId,
      'user_id': 0,
      'slug': widget.slug,
    };

    try {
      final response = await restUtil.postForm(
        restUtil.baseUrl,
        {'json': json.encode(payload)},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => NotFoundPage()),
          );
          return;
        }
        setState(() {
          singlePost = PostDTO.fromJson(data[0]);
          widget.isLoading = false;
        });
      } else {
        setState(() => widget.isLoading = false);
      }
    } catch (error) {
      CommonHelper.logDebug("Error fetching reacted users: $error");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NotFoundPage()),
      );
    }

    // return postDTO;
  }
}