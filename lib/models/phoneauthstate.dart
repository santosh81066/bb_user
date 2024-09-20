class PhoneAuthState {
  final int countdown;
  final bool wait;
  final String? verificationId; // To store Firebase verification ID
  final bool? vrfCompleted; 
  final String? otp;

  PhoneAuthState({
    this.countdown = 45,
    this.wait = true,
    this.verificationId,
    this.vrfCompleted = false,
    this.otp,
  });

  PhoneAuthState copyWith({
    int? countdown,
    bool? wait,
    String? verificationId,
    bool? vrfCompleted,
    String? otp,
  }) {
    return PhoneAuthState(
      countdown: countdown ?? this.countdown,
      wait: wait ?? this.wait,
      verificationId: verificationId ?? this.verificationId,
      vrfCompleted: vrfCompleted ?? this.vrfCompleted,
      otp: otp??this.otp,
    );
  }
}
