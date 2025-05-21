import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contactsupport.dart';

// Support service class
class SupportService {
  static const String baseUrl = 'http://www.gocodedesigners.com';

  Future<SupportResponse> submitSupportRequest(SupportRequest request) async {
    try {
      final url = Uri.parse('$baseUrl/bbusersupport');

      final requestBody = {
        "fullname": request.fullname,
        "email": request.email,
        "subject": request.subject,
        "message": request.message,
        "user_id": request.userId,
      };

      if (kDebugMode) {
        print('Sending support request to: $url');
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return SupportResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to submit support request. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting support request: $e');
      }
      rethrow;
    }
  }
}

// Support response model
class SupportResponse {
  final int statusCode;
  final bool success;
  final List<String> messages;
  final SupportData? data;

  SupportResponse({
    required this.statusCode,
    required this.success,
    required this.messages,
    this.data,
  });

  factory SupportResponse.fromJson(Map<String, dynamic> json) {
    return SupportResponse(
      statusCode: json['statusCode'] ?? 0,
      success: json['success'] ?? false,
      messages: List<String>.from(json['messages'] ?? []),
      data: json['data'] != null ? SupportData.fromJson(json['data']) : null,
    );
  }
}

// Support data model (based on your Postman response)
class SupportData {
  final int id;
  final String fullname;

  SupportData({
    required this.id,
    required this.fullname,
  });

  factory SupportData.fromJson(Map<String, dynamic> json) {
    return SupportData(
      id: json['id'] ?? 0,
      fullname: json['fullname'] ?? '',
    );
  }
}

// Provider for the support service
final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService();
});

// Provider for managing the support state
final supportStateProvider =
StateNotifierProvider<SupportStateNotifier, AsyncValue<SupportResponse?>>(
        (ref) {
      final supportService = ref.read(supportServiceProvider);
      return SupportStateNotifier(supportService);
    });

// State notifier for support operations
class SupportStateNotifier extends StateNotifier<AsyncValue<SupportResponse?>> {
  final SupportService _supportService;

  SupportStateNotifier(this._supportService) : super(const AsyncValue.data(null));

  Future<void> submitSupportRequest(SupportRequest request) async {
    state = const AsyncValue.loading();

    try {
      final response = await _supportService.submitSupportRequest(request);
      state = AsyncValue.data(response);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void resetState() {
    state = const AsyncValue.data(null);
  }
}