class AuthState {
  int? userId;
  String? profilePic;
  String? username;
  String? email;
  String? mobileno;
  String? gender;
  String? token;
  String? usertype;

  AuthState({
    this.userId,
    this.profilePic,
    this.username,
    this.email,
    this.mobileno,
    this.gender,
    this.token,
    this.usertype,
  });

  AuthState.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'] as int?;
    profilePic = json['profile_pic'] as String?;
    username = json['username'] as String?;
    email = json['email'] as String?;
    mobileno = json['mobile_no']?.toString(); // Fix: Convert to String
    gender = json['gender'] as String?;
    token = json['access_token'] as String?;
    usertype = json['user_role'] as String?;
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'profile_pic': profilePic,
        'username': username,
        'email': email,
        'mobile_no': mobileno,
        'gender': gender,
        'access_token': token,
        'user_role': usertype
      };

  AuthState copyWith({
    int? userId,
    String? profilePic,
    String? username,
    String? email,
    String? mobileno,
    String? gender,
    String? token,
    String? usertype,
    bool? userStatus,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      profilePic: profilePic ?? this.profilePic,
      username: username ?? this.username,
      email: email ?? this.email,
      mobileno: mobileno ?? this.mobileno,
      gender: gender ?? this.gender,
      token: token ?? this.token,
      usertype: usertype ?? this.usertype,
    );
  }

  AuthState clear() {
    return AuthState(
      userId: null,
      profilePic: null,
      username: null,
      email: null,
      mobileno: null,
      gender: null,
      token: null,
      usertype: null,
    );
  }
}
