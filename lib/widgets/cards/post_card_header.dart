import 'package:Apviser/models/UserDTO.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../AppConstants.dart';
import '../../CommonHelper.dart';
import '../../colours.dart';
import '../../models/PostsDTO.dart';
import '../../pages/full_photo.dart';
import '../../pages/search.dart';
import '../ProfileAvatar.dart';
import '../select_expertise2.dart';
import 'package:http/http.dart' as http;

class PostCardHeader extends StatelessWidget {
  final PostDTO postDTO;
  final bool? showReportAbuse;
  final bool? isSelectable;
  PostCardHeader({required this.postDTO, this.showReportAbuse=false, this.isSelectable=true});

  static final Map<String, bool> _imageCache = {}; // Cache for image existence

  // Future<bool> _isImageAvailable() async {
  //   try {
  //     String tt = AppConstants.APVISER_IMAGES_PATH_FULL + postDTO!.postImage!;
  //     final response = await http.head(Uri.parse(tt));
  //     return response.statusCode == 200 && response.headers['content-type']?.contains('image') == true;
  //   } catch (e) {
  //     debugPrint("Error checking image: $e");
  //     return false;
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: AppConstants.APP_MAX_WIDTH,
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Changed from center to start
            children: [
              // Profile Avatar aligned to top
              Align(
                alignment: Alignment.topLeft,
                child: ProfileAvatar(
                  size: 70,
                  user: UserDTO(userID: postDTO!.userId!, photo: postDTO!.photo!),
                  isCurrentUser: false,
                  cUserID: 0,
                ),
              ),
              const SizedBox(width: 10),
              // Text Information Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start, // Align content to top
                  children: [
                    Text(
                      _getPostDescription(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      softWrap: true,
                    ),
                    Text(
                      _getPostIcon(),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      softWrap: true,
                    ),

                    const SizedBox(height: 4.0),
                    Text(
                      CommonHelper.getPostAge(postDTO),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if(this.showReportAbuse==true)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.report),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Report Abuse"),
                            content: Text("If you believe this content violates safety policies, please email us at privacy@apviser.com."),
                            actions: [
                              TextButton(
                                child: Text("Close"),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          );
                        },
                      );
                    },
                  ),
                )
            ],
          ),
          const SizedBox(height: 5.0),
          Html(
            data: postDTO.descr!,
            style: {
              "body": Style(
                  fontSize: FontSize(15.0),
                  fontWeight: FontWeight.w500,
                  color: AppColors.black
              ),
            },
            shrinkWrap: true,
            onLinkTap: (url, _, __) {
              if (url != null) {
                _launchURL(url);
              }
            },
          ),
          if (postDTO.containsImage == 1) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: AppConstants.APP_MAX_WIDTH,
                maxHeight: 300,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullPhotoScreen(
                        currentUserId: 0,
                        currentPhoto: "${postDTO.postImage}",
                        isCurrentUser: false,
                        screenTitle: postDTO.descr!,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    "${AppConstants.APVISER_IMAGES_PATH_FULL}${postDTO.postImage}",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.grey[800]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: postDTO.expertiseDetails?.map((expertise) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(
                        initialSelectedOptions: [
                          ValueItem<String>(
                            value: expertise.expertiseId!,
                            label: expertise.name!,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Text(
                  "#${expertise.name}",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300, color: Colors.blue),
                ),
              );
            }).toList() ?? [],
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  String _getPostIcon() {
    String pronoun = _getPronoun(int.tryParse(postDTO.userGender.toString()) ?? 0);

    switch (postDTO.type) {
      case 1: // Normal Poll
        return  "🚦 Honk honk!"; // Post description
      case 2: // Answer Poll
        return "💬 Answers";
      case 3: // Custom Poll
        return  "📊 Poll";
      case 4: // Handshake
        return "🤝 SkillSwap";
      default: // Fallback case
        return "🚦 Honk honk!";
    }
  }

  String _getPostDescription() {
    String pronoun = _getPronoun(int.tryParse(postDTO.userGender.toString()) ?? 0);

    switch (postDTO.type) {
      case 1: // Normal Poll
        return "${postDTO.userFullName} needs your reaction. Which light are you?";
        // return "${postDTO.userFullName} shared a poll. Help $pronoun choose the best option.";

      case 2: // Answer Poll
        return "${postDTO.userFullName} just posted! Join the discussion and share your views!";
        // return "${postDTO.userFullName} asked a question. Help $pronoun find the best or most suitable answer.";

      case 3: // Custom Poll
        return "Help ${postDTO.userFullName} decide—vote in this custom poll!";

      case 4: // Handshake
        return "${postDTO.userFullName} is offering (or searching for) a service! Connect and make magic happen!";
        // return "${postDTO.userFullName} is offering or looking for a service. Help $pronoun get the best option.";

      default: // Fallback case
        return "${postDTO.userFullName} shared a post. Help $pronoun engage with it.";
    }
  }

  String _getPronoun(int? gender) {
    // Return the appropriate pronoun based on gender
    switch (gender) {
      case 1: // Male
        return "him";
      case 2: // Female
        return "her";
      default: // Unknown or non-binary
        return "him/her";
    }
  }

  String _getPostType(PostDTO postDTO) {
    switch (postDTO.type) {
      case 1:
        return "Poll";
      case 3:
        return "Custom Poll";
      case 2:
        return "Answer";
      case 4:
        return "Handshake";
      default:
        return "Post";
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Image'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain, // Ensure the image maintains aspect ratio within the screen
          errorBuilder: (context, error, stackTrace) {
            return Text("Failed to load image."); // Handle any potential error
          },
        ),
      ),
    );
  }
}
