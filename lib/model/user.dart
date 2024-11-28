class User {
  String username;
  bool isLoggedIn;
  bool isCaretaker;
  String token = '';
  User({required this.username, required this.isLoggedIn, required this.isCaretaker, required this.token});
}
