class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();

  factory AuthStateManager() {
    return _instance;
  }

  AuthStateManager._internal();

  bool ignoreNextAuthChange = false;
}
