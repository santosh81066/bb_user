// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Model for the review request
class ReviewRequest {
  final String review;
  final int rating;
  final int userId;
  final int? propertyId;
  final int? hallId;
  final List<String> imagePaths;

  ReviewRequest({
    required this.review,
    required this.rating,
    required this.userId,
    this.propertyId,
    this.hallId,
    required this.imagePaths,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'review': review,
      'rating': rating.toString(),
      'userid': userId.toString(),
    };

    if (propertyId != null) {
      map['property_id'] = propertyId.toString();
    }

    if (hallId != null) {
      map['hall_id'] = hallId.toString();
    }

    return map;
  }
}

// Model for the review response
class ReviewResponse {
  final int statusCode;
  final bool success;
  final List<String> messages;
  final dynamic data;

  ReviewResponse({
    required this.statusCode,
    required this.success,
    required this.messages,
    this.data,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      statusCode: json['statusCode'] as int,
      success: json['success'] as bool,
      messages: (json['messages'] as List).map((e) => e as String).toList(),
      data: json['data'],
    );
  }
}

// Service class for handling API calls
class ReviewService {
  final String baseUrl = 'https://www.gocodedesigners.com';

  Future<ReviewResponse> submitReview(ReviewRequest reviewRequest) async {
    final Uri uri = Uri.parse('$baseUrl/bbaddreview');

    try {
      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      reviewRequest.toMap().forEach((key, value) {
        request.fields[key] = value;
      });

      // Add image files
      for (String imagePath in reviewRequest.imagePaths) {
        final file = File(imagePath);
        final fileName = imagePath.split('/').last;

        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            imagePath,
            contentType: MediaType('image', _getImageType(fileName)),
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      return ReviewResponse.fromJson(jsonResponse);
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  String _getImageType(String fileName) {
    if (fileName.endsWith('.png')) {
      return 'png';
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'jpeg';
    } else {
      return 'octet-stream';
    }
  }
}
