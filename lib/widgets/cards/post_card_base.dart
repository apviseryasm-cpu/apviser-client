import 'package:Apviser/models/PostsDTO.dart';
import 'package:Apviser/my_posts.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../AppConstants.dart';
import 'package:flutter/material.dart';
import '../../pages/create_post.dart';
import '../../rest_util.dart';

// Define a generic BaseState class with common functionality
abstract class BaseState<T extends StatefulWidget> extends State<T> {
  bool isLoading = false;
  // bool isPostHidden = false;

  // Initialize delete callback with a default no-op function
  late VoidCallback onDelete;

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  // Define any other common functionality
  void showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

}
