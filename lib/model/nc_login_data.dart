class NextCloudLoginDataKeys {
  static const String server = "server";
  static const String user = "user";
  static const String password = "password";
}

class NextCloudLoginData {
  Uri server;
  String user;
  String password;

  NextCloudLoginData(this.server, this.user, this.password);
}