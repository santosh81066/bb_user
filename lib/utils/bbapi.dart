class Bbapi {
  static const String baseUrl = "https://www.gocodedesigners.com";
  static const String register = "$baseUrl/register/";
  static const String registration = "$baseUrl/bbusereg";
  static const String update_user = "$baseUrl/update_user/";
  static const String mobilecheck = "$baseUrl/check_mobile_exists/";
  static const String login_otp = "$baseUrl/verify_phone_number/";
  static const String login_mail = "$baseUrl/bbadminlogin";
  static const String properties = "$baseUrl/properties/";
  static const String post_review = "$baseUrl/post_review/";
  static const String get_review = "$baseUrl/get_reviews/";
  static const String booked_dates = "$baseUrl/booked_dates/";
  static const String book_property = "$baseUrl/book_property/";

  static String get getUsers => '$baseUrl/users'; // List users
  static String get updateUser => '$baseUrl/users/update'; // Update user
  static String get deleteUser => '$baseUrl/users/delete'; // Delete user
}
