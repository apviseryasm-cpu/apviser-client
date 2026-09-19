import 'dart:convert';

import 'package:Apviser/CommonHelper.dart';
import 'package:Apviser/widgets/app_bar.dart';
// import 'package:dart_quill_delta/src/delta/delta.dart';
import 'package:delta_to_html/delta_to_html.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../AppConstants.dart';
import '../DatabaseHelper.dart';
import '../colours.dart';
import '../models/UserDTO.dart';
import '../models/PostsDTO.dart';
import '../rest_util.dart';
// import '../widgets/multiselect_dropdown.dart';
// Assuming AppConstants has the user photo path
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;

import '../widgets/select_expertise2.dart';
import 'custom_poll_options.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart';
//import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class CreatePost extends StatefulWidget {
  String questionType;
  final TabController? tabController;
  final PostDTO? postData;
  final int postID;
  final int userID;

  CreatePost(
      {this.questionType = "",
      this.tabController,
      this.postData,
      this.postID = 0,
      this.userID = 0});

  @override
  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  Uint8List? _postImage;
  // final TextEditingController _questionController = TextEditingController();
  QuillController _controller = QuillController.basic();
  File? _selectedImage; // To store the image file

  List<ValueItem<String>> selectedExpertise = [];
  // List<String> newExpertiseList = [];
  bool _showError = false;
  bool _showExpertiseError = false;
  UserDTO? user; // Declare the user at the class level
  late PostDTO postDTO;
  final HiveDatabaseHelper _dbHelper = HiveDatabaseHelper.instance;

  // Simulating current user info from Hive or another source
  String userName = ""; // Replace with actual user data
  String imageName = ""; // Replace with actual user data
  String userPhoto =
      "${AppConstants.APVISER_IMAGES_PATH_FULL}user_photo.png"; // Replace with actual user photo
  // UserDTO? user = await _dbHelper.getCurrentUser("cuser");
  // List<ValueItem<String>> selectedExpertise = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  String _postVisibility = "public"; // Default: Public visibility
  int _postDuration = 2000; // Default: 7 days

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
    if (widget.postID > 0) {
      _fetchPostDetails(widget.postID, widget.userID); // Fetch post details if we are in edit mode
    } else {
      _isLoading = false;
      _initializeForEdit();
    }
  }

  // 3. HTML to Delta Converter
  List<Map<String, dynamic>> _convertHtmlToDeltaJson(String html) {
    if (html.isEmpty) return [{'insert': '\n'}];

    // Basic HTML parsing (for simple cases)
    final cleanHtml = html
        .replaceAll('<p>', '')
        .replaceAll('</p>', '\n')
        .replaceAll('<br>', '\n');

    return [{'insert': cleanHtml}];
  }

  void _initializeForEdit() {
    if (widget.postData != null) {
      // _controller.document = Document.fromHtml(widget.postData!.descr!) as Document;
      String html = widget.postData!.descr!;
      final document = _htmlToDocument(html);
      // final safeHtml = html.trim().endsWith('\n') ? html : '$html\n';
      // final deltaJson = _convertHtmlToDeltaJson(html);

      _controller = QuillController(
        document: document,
        selection: TextSelection.collapsed(offset: 0),
      );
      // if (html.isNotEmpty) {
      //   try {
      //
      //
      //     // Convert HTML to Delta
      //     // final delta = Delta()..insert('\n'); // Start with a newline
      //     // final document = Document.fromDelta(delta);
      //     // String htmlContent = DeltaToHTML.encodeJson(delta);
      //     // // Parse HTML and update document
      //     // final htmlDelta = HtmlToDeltaConverter().convert(html);
      //     final html = postDetails['descr'] ?? '';
      //     final deltaJson = _convertHtmlToDeltaJson(html);
      //
      //     document.toDelta().concat(htmlDelta);
      //
      //     // Initialize controller
      //     _controller = QuillController(
      //       document: document,
      //       selection: const TextSelection.collapsed(offset: 0),
      //     );
      //   } catch (e) {
      //     debugPrint('Error parsing HTML: $e');
      //     _controller = QuillController.basic(); // Fallback
      //   }
      // } else {
      //   _controller = QuillController.basic();
      // }
      if (widget.postData!.postImage != null) {
        _postImage = base64Decode(widget.postData!.postImage!);
      }
    }
  }

  Future<void> _fetchPostDetails(int postID, int userID) async {
    try {
      final restUtil = RESTUtil(
        baseUrl: AppConstants.ANSWERS_DETAILS_BY_QUESTION,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final Map<String, dynamic> payload = {
        'question_id': postID ?? '',
        'user_id': userID,
      };

      CommonHelper.logDebug("_fetchPostDetails payload ${payload.toString()}");

      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.isNotEmpty) {
          var postDetails = responseData[0];
          _populateFields(postDetails);
          postDTO = PostDTO.fromJson(responseData[0]);
          widget.questionType = postDTO.type.toString();
          CommonHelper.logDebug("post type is ${postDTO.type}");
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to load post details",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      CommonHelper.logDebug("Error fetching post details: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Document _htmlToDocument(String html) {
    return Document.fromJson(_htmlToDelta(html));
  }

  List<Map<String, dynamic>> _htmlToDelta(String html) {
    final delta = <Map<String, dynamic>>[];
    final textBuffer = StringBuffer();
    final attributeStack = <Map<String, dynamic>>[];
    final tagStack = <String>[]; // Track opened tags
    bool inListItem = false;

    void flushBuffer() {
      if (textBuffer.isEmpty) return;

      final attributes = attributeStack.fold<Map<String, dynamic>>(
        {},
            (combined, attr) => {...combined, ...attr},
      );

      delta.add({
        'insert': textBuffer.toString(),
        if (attributes.isNotEmpty) 'attributes': attributes,
      });

      textBuffer.clear();
    }

    final tagPattern = RegExp(
      r'<(/?)([a-zA-Z]+)(?:\s+[^>]*)?>|(&[a-z]+;)',
      caseSensitive: false,
    );

    int pos = 0;
    while (pos < html.length) {
      final match = tagPattern.firstMatch(html.substring(pos));
      if (match == null) {
        textBuffer.write(html.substring(pos));
        break;
      }

      if (match.start > 0) {
        textBuffer.write(html.substring(pos, pos + match.start));
      }

      if (match.group(3) != null) {
        // Handle HTML entities (like &nbsp;)
        textBuffer.write(_convertHtmlEntity(match.group(3)!));
        pos += match.end;
        continue;
      }

      final isClosing = match.group(1) == '/';
      final tag = match.group(2)!.toLowerCase();

      if (!isClosing) {
        switch (tag) {
          case 'b':
            flushBuffer(); // ✅ Prevent previous text from inheriting bold
            attributeStack.add({'bold': true});
            tagStack.add(tag);
            break;
          case 'i':
            flushBuffer();
            attributeStack.add({'italic': true});
            tagStack.add(tag);
            break;
          case 'u':
            flushBuffer();
            attributeStack.add({'underline': true});
            tagStack.add(tag);
            break;
          case 's':
          case 'strike':
            flushBuffer();
            attributeStack.add({'strike': true});
            tagStack.add(tag);
            break;
          case 'a':
            flushBuffer();
            final href = RegExp(r'href="([^"]*)"')
                .firstMatch(match.group(0)!)?.group(1);
            if (href != null) {
              attributeStack.add({'link': href});
              tagStack.add(tag);
            }
            break;
          case 'br':
            flushBuffer();
            delta.add({'insert': '\n'});
            break;
          case 'p':
            flushBuffer();
            break;
          case 'ol':
          case 'ul':
            inListItem = true;
            break;
          case 'li':
            flushBuffer();
            if (inListItem) {
              attributeStack.add({'list': tag == 'ol' ? 'ordered' : 'bullet'});
              tagStack.add(tag);
            }
            break;
        }
      } else {
        switch (tag) {
          case 'b':
          case 'i':
          case 'u':
          case 's':
          case 'strike':
          case 'a':
          case 'li':
            flushBuffer();
            if (attributeStack.isNotEmpty) {
              attributeStack.removeLast();
            }
            if (tagStack.isNotEmpty) {
              tagStack.removeLast();
            }
            break;
          case 'p':
            flushBuffer();
            delta.add({'insert': '\n'});
            break;
          case 'ol':
          case 'ul':
            inListItem = false;
            break;
        }
      }

      pos += match.end;
    }

    flushBuffer();

    if (delta.isEmpty || delta.last['insert'] != '\n') {
      delta.add({'insert': '\n'});
    }

    return delta;
  }


  String _convertHtmlEntity(String entity) {
    return switch (entity) {
      '&nbsp;' => ' ',
      '&lt;' => '<',
      '&gt;' => '>',
      '&amp;' => '&',
      _ => entity,
    };
  }

  String _stripTrailingBreaks(String html) {
    return html.replaceFirst(RegExp(r'(<br\s*/?>\s*)+$', caseSensitive: false), '');
  }


  void _populateFields(Map<String, dynamic> postDetails) {
    // Ensure HTML ends with newline (Quill requirement)
    String html = _stripTrailingBreaks(postDetails['descr'] ?? '');

    // Ensure newline at end for Quill
    if (!html.trimRight().endsWith('\n')) {
      html += '\n';
    }

    final deltaJson = _htmlToDelta(html);
    final document = Document.fromDelta(Delta.fromJson(deltaJson));

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    // _controller.document = Document.fromHtml(postDetails['descr'] ?? '') as Document; sdfsafd

    if (postDetails['post_image'] != null && postDetails['post_image'] != "") {
      CommonHelper.logDebug(postDetails['post_image']);
      //_postImage = base64Decode(AppConstants.APVISER_IMAGES_PATH_FULL+postDetails['post_image']);
      String imageUrl =
          "${AppConstants.APVISER_IMAGES_PATH_FULL}${postDetails['post_image']}";
      downloadImageAsBase64(imageUrl);
    }
    selectedExpertise = (postDetails['expertise_details'] as List)
        .map((expertise) => ValueItem<String>.fromJson(expertise))
        .toList();
    CommonHelper.logDebug("selected expertise are $selectedExpertise");

    userName = postDetails['user_full_name'];
    imageName = postDetails['post_image'];
    _postDuration = int.tryParse(postDetails['expiry_in_days'])!;
    _postVisibility = (int.tryParse(postDetails['post_visibility'])! == 1 ? "contacts" :  "public");
  }

  Future<void> downloadImageAsBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        setState(() {
          _postImage = response.bodyBytes; // Store image bytes as Uint8List
        });
      } else {
        CommonHelper.logDebug("Error downloading image: ${response.statusCode}");
      }
    } catch (e) {
      CommonHelper.logDebug("Error: $e");
    }
  }

  Future<void> _initializeUser() async {
    user = await _dbHelper.getCurrentUser("cuser"); // Get user from database
    CommonHelper.logDebug("cuser id is ${user?.userID}");
    userPhoto =
        "${AppConstants.APVISER_IMAGES_PATH_FULL + user!.photo}"; // Replace with actual user photo
    setState(() {}); // Call setState to update the UI if needed
  }

  Future<void> _submitQuestion() async {
    if (_isSubmitting) return; // Prevent duplicate submissions

    setState(() => _isSubmitting = true); // Disable form interaction

    List deltaJson = _controller.document.toDelta().toJson();
    CommonHelper.logDebug(DeltaToHTML.encodeJson(deltaJson));
    String description = DeltaToHTML.encodeJson(deltaJson);
    // return;
    // Validation
    if (description.trim().isEmpty) {
      setState(() {
        _showError = true;
        _isSubmitting = false; // Re-enable form interaction
      });
      return;
    }

    if (selectedExpertise.isEmpty) {
      setState(() {
        _showExpertiseError = true;
        _isSubmitting = false; // Re-enable form interaction
      });
      return;
    }

    // Prepare data
    String base64Image = _postImage != null ? base64Encode(_postImage!) : '';
    int hasImage = base64Image.isNotEmpty ? 1 : 0;
    // String description = _controller.document.text;
    final List<int> expertiseIds =
        selectedExpertise.map((option) => option.value.toInt()).toList();

    final List<String> newExpertiseList = selectedExpertise
        .where((expertise) => expertise.value == -1) // Filter newly added expertise
        .map((expertise) => expertise.label) // Extract the label (name)
        .toList();

    Map<String, dynamic> requestData = {
      "userID": user!.userID,
      "expertise": expertiseIds,
      "new_expertise": newExpertiseList,
      "description": description,
      "post_image": base64Image,
      "type": widget.postID > 0
          ? widget.postData?.type
          : AppConstants.getPollType(widget.questionType),
      "options": [],
      if (widget.postID > 0) "question_id": widget.postID,
      "image_name": imageName,
      "contains_image": hasImage,
      "expiry_in_days": _postDuration == 2000 ? -1 : _postDuration,
      "post_visibility": (_postVisibility == "public" ? 0 : 1),
    };
    // CommonHelper.logDebug(requestData);
    // return;
    if (AppConstants.getPollType(widget.questionType) == 3 ||
        widget.postData?.type == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomPollOptionsScreen(
            userID: user!.userID,
            description: description,
            expertise: expertiseIds,
            newExpertiseList: newExpertiseList,
            hasImage: hasImage,
            postDuration: _postDuration == 2000 ? -1 : _postDuration,
            postVisibility: (_postVisibility == "public" ? 0 : 1),
            base64Image: base64Image,
            postData: widget.postData,
          ),
        ),
      );
      setState(() => _isSubmitting = false); // Re-enable form interaction
    } else {
      await _createPost(requestData); // Submit post
    }
  }

  String _getFunPollTitle(String type) {
    switch (type) {
      case 'Normal Poll' || '1':
        return '🚦 Honk Honk!';
      case 'Custom Poll' || '3':
        return '🎨 Create Your Chaos';
      case 'Answer Poll' || '2':
        return '📢 Shout Your Truth';
      case 'Handshake' || '4':
        return '🤝 Seal the Deal';
      default:
        return type;
    }
  }

  String _getQuestionTypeInfo(String type) {
    switch (type) {
      case 'Normal Poll' || '1':
        return '🚦 Quick signal to your network. Tap reactions, fast opinions!';
      case 'Custom Poll' || '3':
        return '🎨 Ask it your way! Customize answers, shape the vote.';
      case 'Answer Poll' || '2':
        return '🧠 Ask and they shall answer. Ideal for open opinions.';
      case 'Handshake' || '4':
        return '🤝 Request ideas, suggestions, or offers from experts.';
      default:
        return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    final double fieldWidth = MediaQuery.of(context).size.width * 0.9; // Adjust width dynamically

    return Scaffold(
      appBar:
      CustomAppBar(fontSize: 13.0, title: _getFunPollTitle(widget.questionType), actions: [

        // Visibility Drawer Button (☰)
        IconButton(
          icon: Icon(Icons.visibility, color: AppColors.secondary),
          onPressed: _showPostVisibilityDrawer,
        ),

        // Duration Picker Button (⏳)
        IconButton(
          icon: Icon(Icons.timer, color: AppColors.secondary),
          onPressed: _showDurationPicker,
        ),

        // Submit Button (✔ or ➡️)
        IconButton(
          icon: Icon(
            widget.postID > 0
                ? (widget.postData?.type == 3
                ? Icons.navigate_next
                : Icons.update)
                : (AppConstants.getPollType(widget.questionType) == 3
                ? Icons.navigate_next
                : Icons.check),
          ),
          color: AppColors.secondary,
          onPressed: _isSubmitting ? null : _submitQuestion,
        ),

      ], showBackButton: true,),

      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          :
      SafeArea( // Wrap your main content too
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppConstants.APP_MAX_WIDTH, // Set predefined width
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0), // Add left & right padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align content to the start
                      mainAxisSize: MainAxisSize.min, // Minimize vertical space
                      children: [
                        // User Info Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(userPhoto),
                              radius: 30.0,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getQuestionTypeInfo(widget.questionType),
                                        style: TextStyle(fontSize: 12, color: Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        ,
                        SizedBox(height: 16.0),

                        // Question Text Area
                        // SizedBox(
                        //   width: fieldWidth,
                        //   child: TextField(
                        //     controller: _questionController,
                        //     maxLines: 5,
                        //     decoration: InputDecoration(
                        //       labelText: "What's on your mind?",
                        //       errorText: _showError ? 'Question is required' : null,
                        //       border: OutlineInputBorder(),
                        //     ),
                        //   ),
                        // ),

                        SizedBox(
                          width: fieldWidth,
                          child: Column(
                            children: [
                              QuillToolbar.simple(
                                configurations: QuillSimpleToolbarConfigurations(
                                    controller: _controller,

                                    buttonOptions: QuillSimpleToolbarButtonOptions(
                                      base: const QuillToolbarBaseButtonOptions(),
                                      // italic: const QuillToolbarToggleStyleButtonOptions(),
                                      // bold: const QuillToolbarToggleStyleButtonOptions(),
                                      // linkStyle: const QuillToolbarLinkStyleButtonOptions(),
                                    ),
                                    // showImageButton: false, // Disable image uploads
                                    showAlignmentButtons: false,
                                    showCenterAlignment: false,
                                    showBackgroundColorButton: false,
                                    showCodeBlock: false,
                                    showClearFormat: false,
                                    // showClipboardCopy: false,
                                    // showClipboardCut: false,
                                    // showClipboardPaste: false,
                                    showColorButton: false,
                                    showDirection: false,
                                    showDividers: false,
                                    showFontFamily: false,
                                    showFontSize: false,
                                    showHeaderStyle: false,
                                    showIndent: false,
                                    showInlineCode: false,
                                    showJustifyAlignment: false,
                                    // showLineHeightButton: false,
                                    showLeftAlignment: false,
                                    showListCheck: false,
                                    showQuote: false,
                                    showSearchButton: false,
                                    showRightAlignment: false,
                                    showSmallButton: false,
                                    showSubscript: false,
                                    showSuperscript: false,
                                    showUnderLineButton: false
                                ),
                              ),
                              Container(
                                height: 200, // Adjust the height as needed
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: QuillEditor.basic(
                                  // controller: _controller,
                                  // readOnly: false,
                                  // autoFocus: false,
                                  // expands: false,
                                  // padding: EdgeInsets.all(8)
                                  configurations: QuillEditorConfigurations(controller: _controller, autoFocus: true),
                                ),
                              ),
                              if (_showError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Question is required',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.0),

                        // Image Upload Section
                        Center(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 400,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                image: _postImage != null
                                    ? DecorationImage(
                                  image: MemoryImage(_postImage!),
                                  fit: BoxFit.cover,
                                )
                                    : null,
                              ),
                              child: _postImage == null
                                  ? Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey[800],
                              )
                                  : null,
                            ),
                          ),
                        ),

                        if (_postImage != null)
                          Column(
                            children: [
                              SizedBox(height: 10),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _removeImage,
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  label: Text('Remove Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.0),
                            ],
                          ),

                        // Expertise Selection with Padding
                        SizedBox(
                          width: fieldWidth,
                          child: AbsorbPointer(
                            absorbing: _isSubmitting, // Disable interaction when form is submitting
                            child: SelectExpertiseWidget2(
                              userId: user!.userID,
                              initialSelectedOptions: selectedExpertise,
                              isEditable: true,
                              labelText: "Tag Relevant Expertise",
                              onSelectionChanged: (options) {
                                setState(() {
                                  selectedExpertise = options;
                                });
                              },
                            ),
                          ),
                        ),

                        if (_showExpertiseError)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Please select at least one expertise.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        SizedBox(height: 16.0),

                        if (_selectedImage != null)
                          SizedBox(
                            width: fieldWidth,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )

    );
  }

  void _removeImage() {
    setState(() {
      _postImage = null; // Remove the uploaded image
    });
  }

  Future<void> _pickImage() async {
    // Hide Android system bars before picker
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.secondary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            // Fix: ensure full screen cropper
            hideBottomControls: false,
            statusBarColor: AppColors.primary,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(height: 300),
          ),
        ],
      );

      if (croppedFile != null) {
        Uint8List croppedBytes = await croppedFile.readAsBytes();

        final img.Image? decodedImage = img.decodeImage(croppedBytes);
        if (decodedImage != null) {
          Uint8List resizedBytes;
          if (croppedBytes.lengthInBytes > 5 * 1024 * 1024) {
            final resizedImage = img.copyResize(decodedImage, width: 300);
            resizedBytes = Uint8List.fromList(
                img.encodeJpg(resizedImage, quality: 85));
          } else {
            resizedBytes = croppedBytes;
          }
          setState(() {
            _postImage = resizedBytes;
          });
        }
      }
    }

    // Restore system UI after picker/cropper is closed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }


  // Future<void> _pickImage() async {
  //   final ImagePicker _picker = ImagePicker();
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //
  //   if (image != null) {
  //     // Crop the image
  //     CroppedFile? croppedFile = await ImageCropper().cropImage(
  //       sourcePath: image.path,
  //       uiSettings: [
  //         AndroidUiSettings(
  //           toolbarTitle: 'Crop Image 1',
  //           toolbarColor: AppColors.primary,
  //           toolbarWidgetColor: AppColors.secondary,
  //           initAspectRatio: CropAspectRatioPreset.square,
  //           lockAspectRatio: false,
  //         ),
  //         IOSUiSettings(
  //           minimumAspectRatio: 1.0,
  //         ),
  //         WebUiSettings(
  //           context: context,
  //           presentStyle: WebPresentStyle.dialog,
  //           size: const CropperSize(
  //             height: 300,
  //           ),
  //         ),
  //       ],
  //     );
  //
  //     if (croppedFile != null) {
  //       Uint8List croppedBytes = await croppedFile.readAsBytes();
  //
  //       // Decode the image to check its dimensions
  //       final img.Image? decodedImage = img.decodeImage(croppedBytes);
  //
  //       if (decodedImage != null) {
  //         // Resize the image only if necessary
  //         Uint8List resizedBytes;
  //         if (croppedBytes.lengthInBytes > 5 * 1024 * 1024) {
  //           // Compress or resize the image to meet the size limit
  //           final resizedImage = img.copyResize(decodedImage,
  //               width: 300); // Adjust dimensions as needed
  //           resizedBytes = Uint8List.fromList(
  //               img.encodeJpg(resizedImage, quality: 85)); // Quality adjustment
  //         } else {
  //           // Use the original cropped image if under size limit
  //           resizedBytes = croppedBytes;
  //         }
  //
  //         // Update the state with the processed image
  //         setState(() {
  //           _postImage = resizedBytes;
  //         });
  //       } else {
  //         Fluttertoast.showToast(
  //           msg: "Failed to process the image. Please try again.",
  //           toastLength: Toast.LENGTH_SHORT,
  //           gravity: ToastGravity.BOTTOM,
  //           backgroundColor: Colors.red,
  //           textColor: Colors.white,
  //           fontSize: 16.0,
  //         );
  //       }
  //     }
  //   } else {
  //     // Fluttertoast.showToast(
  //     //   msg: "No image selected. Please try again.",
  //     //   toastLength: Toast.LENGTH_SHORT,
  //     //   gravity: ToastGravity.BOTTOM,
  //     //   backgroundColor: Colors.red,
  //     //   textColor: Colors.white,
  //     //   fontSize: 16.0,
  //     // );
  //     CommonHelper.logDebug("No image selected. Please try again.");
  //   }
  // }

  String _normalizeHtml(String html) {
    // Replace 2+ consecutive <br> with just one <br>
    return html.replaceAll(RegExp(r'(<br\s*/?>\s*){2,}', caseSensitive: false), '<br>');
  }


  Future<void> _createPost(Map<String, dynamic> payload) async {
    try {
      // Call the web service
      final restUtil = RESTUtil(
        baseUrl: widget.postID > 0
            ? AppConstants.UPDATE_QUESTION
            : AppConstants.ASK_FOR_REVIEW_NEW,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil
          .postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['error'] == false) {
          // Determine the message based on whether it's a new post or an update
          final actionMessage = widget.postID > 0 ? "updated" : "created";

          CommonHelper.showMessage(
              context, "Post $actionMessage successfully!", 5);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Post $actionMessage successfully!')),
          // );

          if (widget.postID > 0) {
            // updated
            // Get the updated post from the response
            final updatedPost =
                PostDTO.fromJson(responseData['updated_vote_info'][0]);
            CommonHelper.logDebug("updated descr is ${updatedPost.descr}");
            // Redirect user to "My Posts" tab after successful submission
            widget.tabController?.index = 1; // Switch to the "My Posts" tab
            Navigator.pop(context, updatedPost);
          } else {
            // created
            // print("updated descr is ${updatedPost.descr}");
            // Redirect user to "My Posts" tab after successful submission
            // widget.tabController?.index = 1; // Switch to the "My Posts" tab
            final updatedPost =
                PostDTO.fromJson(responseData['updated_vote_info'][0]);
            //Navigator.pop(context);
            Navigator.pop(context, updatedPost);
            Navigator.pop(context, updatedPost);
          }
        } else if (responseData['error'] == true &&
            responseData['error_msg'].contains(
                "there is no one in your friends list with the mentioned expertise")) {

          final updatedPost = PostDTO.fromJson(responseData['updated_vote_info'][0]);
          CommonHelper.showMessage(context, AppConstants.EMPTY_EXPERTISE_MESSAGE, 5);
          Navigator.pop(context, updatedPost); // Close the bottom drawer
          Navigator.pop(context, updatedPost); // Close the bottom drawer
        } else {
          Fluttertoast.showToast(
            msg: "Failed to ${widget.postID > 0 ? "update" : "create"} post.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to reach the server. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      CommonHelper.logDebug("Failed to ${widget.postID > 0 ? "update" : "create"} post: $e");
      Fluttertoast.showToast(
        msg: "An error occurred. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() => _isSubmitting = false); // Re-enable form interaction
    }
  }

/*
  Future<void> _createPost_GPT_Test(Map<String, dynamic> payload) async {
    try {
      // Call the web service
      final restUtil = RESTUtil(
        baseUrl: widget.postID > 0 ? AppConstants.UPDATE_QUESTION : AppConstants.ASK_FOR_REVIEW,
        username: AppConstants.CREDENTIALS_USERNAME,
        password: AppConstants.CREDENTIALS_PASSWORD,
      );

      final response = await restUtil.postForm(restUtil.baseUrl, {'json': json.encode(payload)});

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['error'] == false) {
          // Determine the message based on whether it's a new post or an update
          final actionMessage = widget.postID > 0 ? "updated" : "created";

          Fluttertoast.showToast(
            msg: "Post $actionMessage successfully!",
            toastLength: Toast.LENGTH_LONG, // Ensure the toast stays longer
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0,
          );

          if (widget.postID > 0) {
            // Updated post
            final updatedPost = PostDTO.fromJson(responseData['updated_vote_info'][0]);
            widget.tabController?.index = 0; // Switch to Posts tab
          } else {
            // New post
            widget.tabController?.index = 0; // Switch to Posts tab
          }

          Navigator.pop(context); // Go back to the main screen
        } else {
          _showErrorToast(responseData['error_msg'] ?? "Failed to create post.");
        }
      } else {
        _showErrorToast("Failed to reach the server. Please try again.");
      }
    } catch (e) {
      _showErrorToast("An error occurred. Please try again.");
    } finally {
      setState(() => _isSubmitting = false); // Re-enable form interaction
    }
  }
*/
  // void _showErrorToast(String message) {
  //   Fluttertoast.showToast(
  //     msg: message,
  //     toastLength: Toast.LENGTH_LONG,
  //     gravity: ToastGravity.BOTTOM,
  //     backgroundColor: Colors.red,
  //     textColor: Colors.white,
  //     fontSize: 16.0,
  //   );
  // }

  // void _showVisibilityDrawer() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: Icon(Icons.public),
  //             title: Text("Public"),
  //             trailing: _postVisibility == "public" ? Icon(Icons.check, color: AppColors.primary) : null,
  //             onTap: () {
  //               setState(() {
  //                 _postVisibility = "public";
  //               });
  //               Navigator.pop(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(Icons.group),
  //             title: Text("Contacts"),
  //             trailing: _postVisibility == "contacts" ? Icon(Icons.check, color: AppColors.primary) : null,
  //             onTap: () {
  //               setState(() {
  //                 _postVisibility = "contacts";
  //               });
  //               Navigator.pop(context);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  void _showPostVisibilityDrawer() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea( // Add SafeArea here
          child: Container(
            // padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Your existing options...
                // 🔹 Heading
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Who can see your post",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 🔹 Visibility Options
                ListTile(
                  leading: Icon(Icons.public, color: Colors.blue),  // 🌍 Public icon
                  title: Text("Public (Visible to all relevant experts)"),
                  trailing: _postVisibility == "public"
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _postVisibility = "public");
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.group, color: Colors.green),  // 👥 Contacts-only icon
                  title: Text("Direct Friends Only"),
                  trailing: _postVisibility == "contacts"
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _postVisibility = "contacts");
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
        // return Container(
        //   padding: const EdgeInsets.all(16.0),
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     crossAxisAlignment: CrossAxisAlignment.start,  // Align heading to the left
        //     children: [
        //
        //     ],
        //   ),
        // );
      },
    );
  }


  // void _showDurationPicker() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [1, 3, 7, 30, "Never"].map((dynamic days) {
  //           int duration = (days is int) ? days : 2000; // Convert "Never" to 2000
  //
  //           return ListTile(
  //             leading: Icon(Icons.timer),
  //             title: Text(days == "Never" ? "Never" : "$days days"), // Handle "Never"
  //             trailing: _postDuration == duration
  //                 ? Icon(Icons.check, color: AppColors.primary)
  //                 : null,
  //             onTap: () {
  //               setState(() {
  //                 _postDuration = duration; // Ensure it stores only int
  //               });
  //               Navigator.pop(context);
  //             },
  //           );
  //         }).toList(),
  //       );
  //     },
  //   );
  // }
  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea( // Add SafeArea here
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Heading
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "Allow Interaction For",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Duration Options
                ...[1, 3, 7, 30, "No Limit"].map((dynamic days) {
                  int duration = (days is int) ? days : 2000; // Convert "Never" to 2000

                  return ListTile(
                    leading: Icon(
                      days == "No Limit" ? Icons.timer_off : Icons.timer,  // ⏳ Timer for days, ⏰ Off for Never
                      color: days == "Never" ? Colors.red : Colors.blue,
                    ),
                    title: Text(days == "No Limit" ? "No Limit (No expiration)" : "$days days"), // Handle "Never"
                    trailing: _postDuration == duration
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _postDuration = duration; // Ensure it stores only int
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
        // return Container(
        //   padding: const EdgeInsets.all(16.0),
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     crossAxisAlignment: CrossAxisAlignment.start,  // Align heading to the left
        //
        //   ),
        // );
      },
    );
  }


}
