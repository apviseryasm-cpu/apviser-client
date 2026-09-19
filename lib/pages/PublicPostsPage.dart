import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Detect if running on web
import 'package:Apviser/colours.dart';
import 'package:Apviser/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import '../AppConstants.dart';
import '../DatabaseHelper.dart';
import '../models.dart';
import '../models/PostsDTO.dart';
import '../models/UserDTO.dart';
import '../post.dart';
import '../widgets/select_expertise2.dart';

class PublicPostsPage extends StatefulWidget {
  List<ValueItem<String>>? initialSelectedOptions;
  String? initSearchString;
  bool? isLoading = true;
  // String? cameThrough;

  PublicPostsPage(
      {
        this.initialSelectedOptions,
        this.initSearchString,
        // this.cameThrough
      }); // Allow initialization with a hashtag

  @override
  PublicPostsPageState createState() => PublicPostsPageState();
}

class PublicPostsPageState extends State<PublicPostsPage> {
  final TextEditingController _searchController = TextEditingController();

  late SearchPostsModel posts;
  final ScrollController scrollController = ScrollController();
  // final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;
  // UserDTO? user;
  bool isExpanded = true; // Track the visibility of the search controls
  // bool showWheel = false;
  // bool isSearching = false; // To track if the search is in progress

  @override
  void initState() {
    super.initState();

    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.offset) {
        posts.loadMoreSearch(tdescr: _searchController.text.trim());
      }
    });

    widget.initialSelectedOptions ??= [];
    widget.initSearchString ??= '';

    // Initialize SearchPostsModel
    List<int> expertiseIds = widget.initialSelectedOptions!
        .map((option) => option.value ?? 0)
        .toList();

    _searchController.text = widget.initSearchString!;

    if (expertiseIds.isNotEmpty || _searchController.text.isNotEmpty) {
      posts = SearchPostsModel(_searchController.text.trim(), expertiseIds);
      widget.isLoading = true;
    } else {
      posts = SearchPostsModel('', []); // No initial data fetch
      widget.isLoading = false;
      posts.hasMore = false;
    }
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    // user = await _dbHelper.getCurrentUser("cuser");
    setState(() {
      widget.isLoading = false; // Start loading
    });
  }

  Future<void> _performSearch(bool ishidden) async {
    if (_searchController.text.isEmpty &&
        (widget.initialSelectedOptions == null ||
            widget.initialSelectedOptions!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please provide search criteria.")),
      );
      return;
    }
    isExpanded=ishidden;
    setState(() {
      widget.isLoading = true;
    });


    posts.data2.clear();
    List<int> expertiseIds = widget.initialSelectedOptions!
        .map((option) => option.value ?? 0)
        .toList();

    posts.data2 = await posts.getSearchPostsData(
        _searchController.text.trim(), expertiseIds, showPublicPosts: 1);

    if (posts.data2.isEmpty) {
      posts.hasMore = false;
    }
    setState(() {
      widget.isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(title: "Apviser", showBackButton: false,),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppConstants.APP_MAX_WIDTH, // Limit container width
            ),
            child: Column(
              children: [
                // Collapsible Search Controls
                ExpansionPanelList(
                  elevation: 1,
                  expandedHeaderPadding: EdgeInsets.zero,
                  expansionCallback: (panelIndex, isCurrentlyExpanded) {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  children: [
                    ExpansionPanel(
                      isExpanded: isExpanded,
                      headerBuilder: (context, isExpanded) {
                        return ListTile(
                          title: Text(
                            'Search Options',
                            style: TextStyle(
                              color: AppColors.black, // Change font color to white
                            ),
                          ),
                        );
                      },
                      body: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search posts...',
                                labelStyle: TextStyle(
                                  color: AppColors.black, // Change label color to white
                                ),
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.clear, color: AppColors.black), // Icon color to white
                                  onPressed: () => _searchController.clear(),
                                ),
                              ),
                              style: TextStyle(
                                color: AppColors.black, // Text input color to white
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Expertise Selection
                            // if (user != null)
                              SelectExpertiseWidget2(
                                userId: -1,
                                initialSelectedOptions: widget.initialSelectedOptions ?? [],
                                isEditable: true,
                                onSelectionChanged: (newSelectedOptions) {
                                  setState(() {
                                    widget.initialSelectedOptions = newSelectedOptions;
                                    _performSearch(true);
                                  });
                                },
                              ),
                            const SizedBox(height: 16),
                            // Search Button
                            ElevatedButton.icon(
                              icon: Icon(Icons.search),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.secondary, // Set background color to white
                                side: BorderSide(color: AppColors.primary, width: 2), // Red border
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
                                ),
                              ),
                              label: Text(
                                'Search',
                                style: TextStyle(
                                  color: AppColors.black, // Change button text color to white
                                ),
                              ),
                              onPressed: () {
                                _performSearch(false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(thickness: 1, color: Colors.white), // Divider color to white

                // Search Results Section
                (_searchController.text.isEmpty &&
                    (widget.initialSelectedOptions == null ||
                        widget.initialSelectedOptions!.isEmpty))
                    ? Text(
                  "Select to Search",
                  style: TextStyle(
                    color: Colors.white, // Change font color to white
                  ),
                )
                    : Expanded(
                  child: StreamBuilder<List<PostDTO>>(
                    stream: posts.stream,
                    builder: (BuildContext context, AsyncSnapshot<List<PostDTO>> snapshot) {
                      if (widget.isLoading!) {
                        return Center(child: CircularProgressIndicator());
                      } else {
                        return RefreshIndicator(
                          onRefresh: posts.refresh,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            controller: scrollController,
                            separatorBuilder: (context, index) => Divider(color: Colors.white), // Divider color to white
                            itemCount: posts.data2.length + 1,
                            itemBuilder: (BuildContext context, int index) {
                              if (index < posts.data2.length) {
                                final post = posts.data2[index];
                                return Post(
                                  post: post,
                                  showMenu: false,
                                  onDelete: () => {},
                                  onEdit: () => {},
                                );
                              } else if (posts.hasMore) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              } else {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppConstants.TEXT_NO_MORE_POSTS,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary, // Change font color to white
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "🎉",
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: AppColors.primary, // Change font color to white
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
class PublicPostsPage extends StatelessWidget {
  const PublicPostsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // Redirect non-web users back
      Future.microtask(() => Navigator.pop(context));
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Public Posts"),
        backgroundColor: Colors.blue, // Custom color for anonymous page
      ),
      body: Center(
        child: Text("Displaying Public Posts Here...",
            style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
*/