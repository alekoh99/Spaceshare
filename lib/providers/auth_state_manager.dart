import 'package:get/get.dart';

class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();

  factory AuthStateManager() {
    return _instance;
  }

  AuthStateManager._internal();

  final _isSigningIn = false.obs;
  final _isSignedIn = false.obs;
  final _lastError = Rx<String?>(null);
  final _retryCount = 0.obs;
  final _lastSignInAttempt = Rx<DateTime?>(null);
  final _currentUid = Rx<String?>(null);

  RxBool get isSigningIn => _isSigningIn;
  RxBool get isSignedIn => _isSignedIn;
  Rx<String?> get lastError => _lastError;
  RxInt get retryCount => _retryCount;
  Rx<String?> get currentUid => _currentUid;

  void setSigningIn() {
    _isSigningIn.value = true;
    _lastError.value = null;
    _lastSignInAttempt.value = DateTime.now();
  }

  void setSignedIn(String uid) {
    _isSigningIn.value = false;
    _isSignedIn.value = true;
    _currentUid.value = uid;
    _lastError.value = null;
    _retryCount.value = 0;
  }

  void setSignedOut() {
    _isSigningIn.value = false;
    _isSignedIn.value = false;
    _currentUid.value = null;
    _lastError.value = null;
    _retryCount.value = 0;
  }

  void setError(String error) {
    _isSigningIn.value = false;
    _lastError.value = error;
    _retryCount.value = _retryCount.value + 1;
  }

  void clearError() {
    _lastError.value = null;
  }

  bool canRetry() {
    if (_lastSignInAttempt.value == null) return true;
    
    final timeSinceLastAttempt = DateTime.now().difference(_lastSignInAttempt.value!);
    const retryDelay = Duration(seconds: 3);
    
    return timeSinceLastAttempt > retryDelay && _retryCount.value < 5;
  }

  void reset() {
    _isSigningIn.value = false;
    _isSignedIn.value = false;
    _currentUid.value = null;
    _lastError.value = null;
    _retryCount.value = 0;
    _lastSignInAttempt.value = null;
  }
}
