class RegistrationState {
  final String? errorMessage;
  final String? message;
  final bool isLoading;

  // Constructor for initial state
  RegistrationState({
    this.errorMessage,
    this.message,
    this.isLoading = false,
  });

  // Define the initial state
  factory RegistrationState.initial() {
    return RegistrationState(
      errorMessage: null,
      message: null,
      isLoading: false,
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
}
