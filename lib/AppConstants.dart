import 'package:flutter/material.dart';

class AppConstants {
  // Server user login url
  // static const String SERVER_IP = "http://localhost/apviserphp/web/WS/";
  static const String APVISER_WEB_LINK = "https://web.apviser.com";
  static const String APVISER_MAIN_LINK = "https://apviser.com";
  static const String SERVER_IP = "https://apviser.com/apviser/web/WS/";
  static const double APP_MAX_WIDTH = 800; // Define max width suitable for web and mobile
  static const String URL_LOGIN = "${SERVER_IP}user/login/";
  static const String MY_QUESTIONS = "${SERVER_IP}user/getMyQuestions/";
  static const String MY_QUESTIONS2 = "${SERVER_IP}user/getMyQuestions2/";
  static const String URL_FRIEND_REQUEST = "${SERVER_IP}user/addFriend/";
  static const String URL_SUGGEST_FRIEND = "${SERVER_IP}user/suggestFriend/";
  static const String URL_FRIENDS_REQUEST = "${SERVER_IP}user/addFriends/";
  static const String URL_FRIEND_LIST = "${SERVER_IP}user/getFriends/";
  static const String URL_FRIEND_LIST2 = "${SERVER_IP}user/getFriends2/";
  static const String GET_EXPERTISE = "${SERVER_IP}user/getExpertise/";
  static const String GET_ORDERS = "${SERVER_IP}getOrders/";
  static const String ASK_FOR_REVIEW = "${SERVER_IP}review/askForReview/";
  static const String ASK_FOR_REVIEW_NEW = "${SERVER_IP}review/askForReviewNew/";
  static const String UPDATE_QUESTION = "${SERVER_IP}review/editQuestion/";
  static const String HIDE_QUESTION = "${SERVER_IP}review/hideQuestion/";
  static const String TOGGLE_QUESTION = "${SERVER_IP}review/togglePost/";
  static const String SHOW_QUESTION = "${SERVER_IP}review/showQuestion/";
  static const String DELETE_QUESTION = "${SERVER_IP}review/deleteQuestion/";
  static const String RELATED_QUESTIONS = "${SERVER_IP}review/getRelatedQuestions/";
  static const String RELATED_QUESTIONS2 = "${SERVER_IP}review/getRelatedQuestions2/";
  static const String VOTE_TYPES = "${SERVER_IP}review/getVoteTypes/";
  static const String SUBMIT_REVIEW = "${SERVER_IP}review/submitReview/";
  static const String URL_REGISTER = "${SERVER_IP}user/addUser/";
  static const String URL_DEVICE_TOKEN = "${SERVER_IP}user/registerPushNotificationToken/";
  static const String UPDATE_USER_EXPERTISE = "${SERVER_IP}user/updateUserExpertise/";
  static const String UPDATE_USER_SUGGESTED_EXPERTISE = "${SERVER_IP}user/updateSuggestedUserExpertise/";
  static const String USER_NOTIFICATIONS = "${SERVER_IP}user/getNotifications/";
  static const String URL_UPDATE = "${SERVER_IP}user/updateUser/";
  static const String GET_MY_EXPERTISE = "${SERVER_IP}user/getMyExpertise/";
  static const String RATED_BY_ME = "${SERVER_IP}user/ratedByMe/";
  static const String ANSWERS_DETAILS_BY_QUESTION = "${SERVER_IP}user/getRelatedItemsSingle/";
  static const String QUESTION_DETAILS_BY_ID = "${SERVER_IP}review/getQuestionDetailsByID/";
  static const String VOTERS_OF_QUESTION = "${SERVER_IP}user/getVotersOfQuestion/";
  static const String GET_CREATED_ITEMS = "${SERVER_IP}user/getCreatedItems/";
  static const String GET_OPTIONS_BY_QUESTION = "${SERVER_IP}review/getOptionsByQuestionID/";
  static const String GET_USER_BY_ID = "${SERVER_IP}user/getUserDetailsByID/";
  static const String ADD_EXPERTISE = "${SERVER_IP}user/addExpertise/";
  static const String SEND_OTP = "${SERVER_IP}user/sendOTP/";
  static const String APPROVE_FRIEND = "${SERVER_IP}user/approveFriend/";
  static const String DISABLE_NOTIFICATION = "${SERVER_IP}user/disableNotification/";
  static const String COMET_CHAT_URL = "https://api.cometchat.com/v1.8/users";
  static const int INITITAL_QUESTIONS_FETCH = 10;
  static const String COMET_CHANNEL_ID = "2";
  static const String APVISER_CHANNEL_ID = "12";
  static const String APVISER_CHAT_CHANNEL_ID = "13";
  static const String APVISER_CHANNEL_NAME = "apviser_channel";
  static const String APVISER_CHANNEL_CHAT = "apviser_channel_chat";
  static const String APVISER_NOTIF_GROUP_ID = "apviser_notif_group_id";
  static NotificationManager? NOTIFICATION_MANAGER;
  // static const String FCM_APPLICATION_ID = "1:453905060766:android:fd430a76a6b35388";
  // static const String FCM_WEB_API_KEY = "AIzaSyBCHc7lCLJkTn2DsWcPIPhXYsl5tpVeFW0";
  static const String FCM_APPLICATION_ID = "1:453905060766:android:1956fa25af6b209b29fc8f";
  static const String FCM_WEB_API_KEY = "AIzaSyBmbzO6lvmtww_bp21lHwHYKEvHbQHssOI";
  // static const String COMET_API_KEY="d98b612496ce80df1c873a5b7e536325ebc43565";
  // static const String COMET_CHANNEL_GUID="supergroup"; // GUID of joined group
  static const String GET_PUBLIC_ITEMS = "${SERVER_IP}user/getRelatedItems/";
  static const String GET_PUBLIC_ITEMS2 = "${SERVER_IP}user/getRelatedItems2/";
  static const String GET_USER_PROFILE = "${SERVER_IP}user/getUserProfileByID/";
  static const String UPDATE_USER_LOCATION = "${SERVER_IP}user/updateUserLocation/";
  static const String GET_USER_LOCATION = "${SERVER_IP}user/getUserLocationDetails/";
  static const String GENERIC_UPDATE = "${SERVER_IP}user/genericUpdate/";
  static const String UPDATE_PROFILE_PICTURE = "${SERVER_IP}user/updateProfilePictue/";
  static const String GET_SUGGESTED_REFERALS_LIST = "${SERVER_IP}user/getSuggestReferalsList/";
  static const String SEARCH_POSTS = "${SERVER_IP}user/searchPosts/";
  static const String UPDATE_SOCIAL_MEDIA = "${SERVER_IP}user/updateSocialMedia/";
  static const String DEVICE_LOGS = "${SERVER_IP}user/uploadDeviceLogs/";
  static const String LIKES_AND_COMMENTS = "${SERVER_IP}review/likesAndComments/";
  static const String GET_CHAT_TOKEN = "${SERVER_IP}user/generateChatToken/";
  static const String GET_COMMENTS = "${SERVER_IP}user/getCommentsByQuestionID/";
  static const String BUMP_POST = "${SERVER_IP}review/bumppost/";
  static const String CHAT_NOTIFICATION = "${SERVER_IP}user/sendChatNotification/";
  static const String SUGGESTED_EXPERTISE = "${SERVER_IP}user/getSuggestedExpertise/";
  static const String USER_POSTS = "${SERVER_IP}user/getPostsByUserID/";
  static const String MY_CHATS = "${SERVER_IP}user/getMyChats/";
  static const String GET_LATEST_EXPERTISE = "${SERVER_IP}user/getLatestExpertise/";
  static const String SUGGEST_EXPERTISE = "${SERVER_IP}user/suggestExpertise/";
  static const String SUGGEST_TOP_EXPERTISE = "${SERVER_IP}user/suggestTopExpertise/";
  static const String SUGGEST_EXPERTS_BY_PHONE = "${SERVER_IP}user/suggestExpertsByPhone/";
  static const String TAG_EXPERTISE_TO_USER = "${SERVER_IP}user/tagExpertiseToUser/";
  /*[
  {"phone":"98798797", "fullName":"test name", "expertise":"1,2,3,4", "referrerID":1073, "questionID":567},
  {"phone":"54354345564", "fullName":"dddb gsgdd", "expertise":"1,2,4,6", "referrerID":1073, "questionID":874}
  ]*/


  static const String HINT_TEXT_OCCUPATION = "e.g., Engineer, Dentist, Banker etc";
  static const String HINT_TEXT_ABOUT = "e.g., 'I am a dentist who loves creating perfect smiles' or 'Graphic designer specializing in branding and logos.'";
  static const String HINT_TEXT_OFFER_SERVICES = "Tick this box if you're also available to offer your services or expertise to others.";
  static const String TEXT_NO_MORE_POSTS = "That's all folks!";
  static const String TEXT_NO_POSTS = "No posts yet! Start sharing your thoughts or questions with your network.";
  static const String TEXT_NO_EXPERTISE = "Hmm... nothing here right now. Try exploring other topics!";
  static const String TEXT_NO_FRIENDS = "It’s a bit quiet here... Connect with friends and start building your vibe!.";
  static const String TEXT_NO_NOTIFICATIONS = "No buzz right now, but your activity history will appear here soon!";
  static const String TEXT_WRONG_OTP = "Oops! That doesn’t seem right. Please check the OTP and try again.";
  static const String TEXT_REGISTRATION_SUCCESSFUL = "Registration successful";
  static const String TEXT_REGISTRATION_FAIL = "Registration failed. Please try again";
  static const String TEXT_SIGNIN_SUCCESSFUL = "Signed in successfully!";
  static const String TEXT_WELCOME_BACK = "Welcome back!";
  static const String TEXT_OTP_EMPTY = "OTP cannot be empty";
  static const String TEXT_FAILED_SIGNIN = "Failed to sign in";
  static const String TEXT_SOME_ERROR = "Some error occurred";
  static const String BUTTON_TEXT_VERIFY_OTP = "Verify OTP";
  static const String EMPTY_EXPERTISE_MESSAGE = "Your question has been submitted successfully. None of your friends have the selected expertise, but it will still be visible to your direct friends.";
  //static const String BUTTON_TEXT_VERIFY_OTP = "No one in your friends list has this expertise (e.g., mechanic, painter, etc.). Try expanding your network or asking publicly!";
  static const String USER_AGREEMENT = """
    <h2>Apviser User Agreement</h2>
    <p><strong>Last Updated:</strong> [Date]</p>
    <h3>1. Acceptance of Terms</h3>
    <ul>
      <li>By accessing or using Apviser, you agree to abide by these terms.</li>
    </ul>
    <h3>2. User Eligibility</h3>
    <ul>
      <li>You must be at least 13 years old (or legal age in your country) to use Apviser.</li>
    </ul>
    <h3>3. Privacy Policy</h3>
    <p>Your use of Apviser is governed by our <a href='#'>Privacy Policy</a>.</p>
  """;

  static const String userAgreementTitle = "1. Acceptance of Terms";
  static const String lastUpdated = "Last Updated: 31 Jan 2025";

  static const String section1Title = "1. Acceptance of Terms";
  static const String section1Content = "By accessing or using Apviser, you confirm that you have read, understood, and agreed to these terms. If you do not agree, please discontinue use immediately.";

  static const String section2Title = "2. User Eligibility";
  static const List<String> section2Points = ["You must be at least 13 years old (or the minimum legal age in your country) to use Apviser. If you are under 18, you confirm that you have parental or guardian consent."
  ];

  static const String section3Title = "3. Account Registration & Security";
  static const String section3Content = """• You must provide accurate and up-to-date information when creating an account.
•	You are responsible for maintaining the confidentiality of your login credentials.
•	You are solely responsible for any activity occurring under your account.
  """;

  static const String section4Title = "4. User Responsibilities";
  static const String section4Content = """• You agree to use Apviser for lawful purposes only.
•	You will not engage in harassment, hate speech, or any form of abuse toward other users.
•	You will not impersonate others or misrepresent your identity.
  """;

  static const String section5Title = "5. Content Guidelines";
  static const String section5Content = """• Users can share opinions, polls, and recommendations, but must ensure content is respectful and does not violate any laws.
•	Apviser reserves the right to remove content that is inappropriate, misleading, or offensive.
•	Users retain ownership of their content but grant Apviser a license to use, display, and distribute it within the platform.
  """;

  static const String section6Title = "6. Privacy Policy";
  static const String section6Content = """Your use of Apviser is also governed by our Privacy Policy, which details how we collect, store, and use your personal data. By using the platform, you consent to our data practices.""";

  static const String section7Title = "7. Service Modifications & Availability";
  static const String section7Content = """• Apviser reserves the right to modify, suspend, or discontinue any features at any time without notice.
•	We do not guarantee uninterrupted service and are not responsible for downtimes or technical issues.
  """;

  static const String section8Title = "8. Limitation of Liability";
  static const String section8Content = """• Apviser is provided "as is" without warranties of any kind.
•	We are not responsible for any direct, indirect, or incidental damages arising from the use of our platform.
•	Users are solely responsible for interactions and transactions that occur within the platform.
  """;

  static const String section9Title = "9. Termination of Account";
  static const String section9Content = """• Apviser reserves the right to suspend or terminate accounts that violate this agreement.
•	Users may delete their account at any time through account settings.
  """;

  static const String section10Title = "10. Changes to This Agreement";
  static const String section10Content = """We may update this Agreement from time to time. Continued use of Apviser after updates means you accept the revised terms.""";
  static const String BUMPED_MESSAGE1 = "Post successfully bumped, but no friends with matching expertise were found. Download the app to expand your network and reach a wider audience.";


  //static const int DEVICE_LOGS_LEVEL = Log.ERROR;  // later change this value to take from the DB because we will be able to change it without bullding a seperate build for mobile deep reporting
  // static const int DEVICE_LOGS_LEVEL = Log.DEBUG;  // later change this value to take from the DB because we will be able to change it without bullding a seperate build for mobile deep reporting

  // static const String APVISER_IMAGES_PATH = "http://localhost/apviserphp/images/thumb_";
  static const String APVISER_IMAGES_PATH = "https://apviser.com/apviser/web/WS/image.php?name=thumb_";
  // static const String APVISER_IMAGES_PATH_FULL = "http://localhost/apviserphp/images/";
  static const String APVISER_IMAGES_PATH_FULL = "https://apviser.com/apviser/web/WS/image.php?name=";
  static const String LOCATION_API = "http://ip-api.com/json";

  static const String CREDENTIALS_USERNAME = "raza";
  static const String CREDENTIALS_PASSWORD = "raza";

  static const int MIN_FRIENDS_TO_ADD = 1;
  static const int QUESTION_DESCRIPTION_TRIM_LENGTH = 200;

  static List<String> notificationsList = [];
  static List<UserChatsDTO> chatNotificationsList = [];

  static const String URL_LOCATION = "http://locationmatcher-com.stackstaging.com/addLocation/";
  static const String DELETE_LOCATION = "http://locationmatcher-com.stackstaging.com/deleteLocation/";
  static const String SEE_MORE = "see more";
  static const String WEB_CLIENT_ID = "453905060766-fe70bcstn9eaug7ujlpg0tog0jrutt88.apps.googleusercontent.com";
  // static const String GET_ORDERS = "http://locationmatcher-com.stackstaging.com/getOrders/";

  static List<TagModel> OCCUPATIONS_LIST = [];

  static Map<String, int> COUNTRY_DIALING_CODES = {};

  static void initMapCountryCodes() {
    COUNTRY_DIALING_CODES = {
      "au": 61,
      "at": 43,
      "bd": 880,
      "ca": 1,
      "in": 91,
      "pk": 92,
      "ae": 971,
      "": 971
    };
  }

  static dynamic getPollType(dynamic questionType) {
    if (questionType is String) {
      switch (questionType) {
        case "Normal Poll":
          return 1;
        case "Custom Poll":
          return 3;
        case "Answer Poll":
          return 2;
        case "Handshake":
          return 4;
        default:
          return 1;
      }
    } else if (questionType is int) {
      switch (questionType) {
        case 1:
          return "Normal Poll";
        case 3:
          return "Custom Poll";
        case 2:
          return "Answer Poll";
        case 4:
          return "Handshake";
        default:
          return "Normal Poll";
      }
    } else {
      throw ArgumentError("Invalid argument type: must be int or String");
    }
  }


  static bool OCCUPATIONS_LIST_LOADED = false;

  static void initOccupation() {
    // Add initialization logic here
  }

  static const String THINK_OF_5_PEOPLE = "Think of five people that are closest to you.\nWhat advise do they normally seek of you? ";
}

class NotificationManager {
  // Placeholder for NotificationManager class
}

class TagModel {
  // Placeholder for TagModel class
}

class UserChatsDTO {
  // Placeholder for UserChatsDTO class
}
