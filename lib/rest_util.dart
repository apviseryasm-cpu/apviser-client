import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import 'CommonHelper.dart';

class RESTUtil {
  final String baseUrl;
  final String username;
  final String password;

  RESTUtil({required this.baseUrl, required this.username, required this.password});

  String _basicAuthHeader() {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $credentials';
  }

  Future<http.Response> get(String endpoint, {bool requireAuth=true}) async {

    if(kDebugMode){
      CommonHelper.logDebug("inside get Endpoint: $endpoint");
    }

    // Skip connectivity check for the web, or provide an alternative
    if (!kIsWeb) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          throw NoInternetException('No internet connection');
        }
      } catch (e) {
        CommonHelper.logDebug("Connectivity check failed: $e");
        // Optionally handle the exception
      }
    }

    final url = Uri.parse(endpoint);
    final response = await http.get(url, headers: {
      if (requireAuth) ...{
        'Authorization': _basicAuthHeader(),
      },
      'Accept': 'application/json',
    });
    _handleResponse(response);
    return response;
  }

  Future<http.Response> postForm(String endpoint, Map<String, String> formData) async {
    if(kDebugMode){
      CommonHelper.logDebug("inside postForm Endpoint: $endpoint");
      CommonHelper.logDebug("Payload: ${formData.toString()}");
    }

    // Skip connectivity check for the web, or provide an alternative
    if (!kIsWeb) {
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          throw NoInternetException('No internet connection');
        }
      } catch (e) {
        CommonHelper.logDebug("Connectivity check failed: $e");
        // Optionally handle the exception
      }
    }

    final url = Uri.parse(endpoint);
    try {
      final response = await http.post(url, headers: {
        'Authorization': _basicAuthHeader(),
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      }, body: formData);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _handleResponse(response);
        return response;
      } else {
        CommonHelper.logDebug("Standard POST request failed with status: ${response.statusCode}, triggering fallback.");
        throw Exception('Standard POST failed');
      }
    } catch (e) {
      CommonHelper.logDebug("Standard POST failed, attempting multipart fallback. Error: $e");

      // Fallback to multipart approach
      try {
        Map<String, String> headers = <String, String>{
          'Authorization': _basicAuthHeader(),
          'Accept': 'application/json',
        };

        final multipartRequest = http.MultipartRequest('POST', url)
          ..headers.addAll(headers)
          ..fields.addAll(formData);

        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);

        _handleResponse(response);
        return response;
      } catch (e) {
        CommonHelper.logDebug("Multipart fallback failed. Error: $e");
        throw Exception('Failed to send POST request: $e');
      }
    }
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      CommonHelper.logDebug("Error: ${response.statusCode} ${response.reasonPhrase}");
      throw Exception('Error: ${response.statusCode} ${response.reasonPhrase}');
    } else {
      if(kDebugMode){
        CommonHelper.logDebug("Response body: ${response.body}");
      }
    }
  }
  void _handleResponse2(http.StreamedResponse response) {
    if (response.statusCode >= 400) {
      CommonHelper.logDebug("Error: ${response.statusCode} ${response.reasonPhrase}");
      throw Exception('Error: ${response.statusCode} ${response.reasonPhrase}');
    } else {
      CommonHelper.logDebug("Response body: ${response.stream.bytesToString()}");
    }
  }
}

class NoInternetException implements Exception {
  final String message;
  NoInternetException(this.message);
}
