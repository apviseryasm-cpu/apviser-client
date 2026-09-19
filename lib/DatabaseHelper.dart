import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:Apviser/models/UserDTO.dart';
import 'package:hive_flutter/adapters.dart';

import 'CommonHelper.dart';
// import 'dart:html' as html; // Only used for the web fallback

class HiveDatabaseHelper {
  static const String _boxName = "userBox";

  // Singleton instance
  HiveDatabaseHelper._privateConstructor();
  static final HiveDatabaseHelper instance = HiveDatabaseHelper._privateConstructor();

  // Open the Hive box (equivalent to a table)
  Future<Box<UserDTO>> _openBox() async {
    return await Hive.openBox<UserDTO>(_boxName);
  }

  // Initialize Hive (should be called in main.dart or similar)
  static Future<void> initHive() async {
    Hive.initFlutter();
    Hive.registerAdapter(UserDTOAdapter());
  }

  // Insert or Update User
  Future<void> setUser(UserDTO user) async {
    var box = await _openBox();
    await box.put(user.userID, user); // Store user by ID
  }

  // Get User by ID
  Future<UserDTO?> getUser(int userId) async {
    var box = await _openBox();
    return box.get(userId);
  }

  // Get all users (if needed)
  Future<List<UserDTO>> getAllUsers() async {
    var box = await _openBox();
    return box.values.toList();
  }

  // Delete User by ID
  Future<void> deleteUser(int userId) async {
    var box = await _openBox();
    await box.delete(userId);
  }

  // Clear the entire box
  Future<void> clearBox() async {
    var box = await _openBox();
    await box.clear();
  }

  // Method to store a UserDTO with userID as the key
  // Future<void> storeCurrentUser(String key, UserDTO user) async {
  //   var box = await _openBox();
  //   await box.put(key, user);
  // }
  //
  // Future<UserDTO?> getCurrentUser(String key) async {
  //   var box = await _openBox();
  //   return box.get(key);
  // }

  Future<void> storeCurrentUser(String key, UserDTO user) async {
    try {
      var box = await _openBox();

      if (kIsWeb) {
        // Try storing with Hive
        await box.put(key, user);

        // Verify if it was stored successfully
        UserDTO? testUser = box.get(key);
        if (testUser == null) {
          throw Exception("Hive storage failed, falling back to localStorage.");
        }
      } else {
        // Store using Hive on Android/iOS
        await box.put(key, user);
      }
    } catch (e) {
        CommonHelper.logDebug(e.toString());
    }
  }

  Future<UserDTO?> getCurrentUser(String key) async {
    try {
      var box = await _openBox();

      // Attempt to get the user from Hive
      UserDTO? user = box.get(key);

      /*if (user == null && kIsWeb) {
        // If Hive fails on web, try localStorage fallback
        String? userData = html.window.localStorage[key];
        if (userData != null) {
          return UserDTO.fromJson(jsonDecode(userData));
        }
      }*/

      return user;
    } catch (e) {
      /*if (kIsWeb) {
        // Fallback to localStorage for web
        String? userData = html.window.localStorage[key];
        if (userData != null) {
          return UserDTO.fromJson(jsonDecode(userData));
        }
      }*/
      CommonHelper.logDebug("Error retrieving user: $e");
      return null;
    }
  }

}
