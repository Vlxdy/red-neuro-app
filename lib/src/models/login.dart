class Login {
  String username;
  String password;

  Login(this.password, this.username);

  static empty() => Login('', '');

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['usuario'] = username.trim();
    data['contrasena'] = password.trim();
    return data;
  }
}
