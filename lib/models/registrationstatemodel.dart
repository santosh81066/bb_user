import 'dart:io';

class RegistrationState {
  final String? errorMessage;
  final String? message;
  final bool isLoading;
  final File? profileImage;
  final String? username;
  final String? email;
  final String? password;
  final String? contactNumber;

  // Constructor for initial state
  RegistrationState({
    this.errorMessage,
    this.message,
    this.isLoading = false,
    this.profileImage,
    this.contactNumber,
    this.email,
    this.password,
    this.username
  });

  // Define the initial state
  factory RegistrationState.initial() {
    return RegistrationState(
      errorMessage: null,
      message: null,
      isLoading: false,
    );
  }

  factory RegistrationState.fromJson(Map<String, dynamic> json) {
    return RegistrationState(
      message: json['message'] as String?,
      errorMessage: json['errorMessage'] as String?,
      // Handle other fields appropriately if needed
    );
  }

  // Success state
  factory RegistrationState.success({String? message}) {
    return RegistrationState(
      errorMessage: null,
      message: message,
      isLoading: false,
    );
  }

  // Failure state
  factory RegistrationState.failure({String? errorMessage}) {
    return RegistrationState(
      errorMessage: errorMessage,
      message: null,
      isLoading: false,
    );
  }

  // Loading state
  factory RegistrationState.loading() {
    return RegistrationState(
      errorMessage: null,
      message: null,
      isLoading: true,
    );
  }

  // Updated copyWith method to preserve all fields
  RegistrationState copyWith({
    String? errorMessage,
    String? message,
    bool? isLoading,
    File? profileImage,
    String? username,
    String? email,
    String? password,
    String? contactNumber,
  }) {
    return RegistrationState(
      errorMessage: errorMessage ?? this.errorMessage,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      profileImage: profileImage ?? this.profileImage,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      contactNumber: contactNumber ?? this.contactNumber,
    );
  }
}