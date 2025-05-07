import 'package:flutter/foundation.dart';

class Review {
  final int id;
  final String reviewText;
  final int? propertyId;
  final int? hallId;
  final int userId;
  final int rating;
  String? propertyName;
  String? hallName;

  Review({
    required this.id,
    required this.reviewText,
    required this.propertyId,
    required this.hallId,
    required this.userId,
    required this.rating,
    this.propertyName,
    this.hallName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      reviewText: json['reviews'],
      propertyId: json['property_id'],
      hallId: json['hall_id'],
      userId: json['userid'],
      rating: json['rating'],
    );
  }
}
