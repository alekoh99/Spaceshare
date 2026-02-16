import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkConnectivity {
  static final NetworkConnectivity _instance = NetworkConnectivity._internal();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  final _isConnected = true.obs;

  factory NetworkConnectivity() {
    return _instance;
  }

  NetworkConnectivity._internal() {
    _initialize();
  }

  void _initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isConnected.value = result.isNotEmpty &&
          result.every((element) => element != ConnectivityResult.none);
    });

    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected.value = result.isNotEmpty &&
          result.every((element) => element != ConnectivityResult.none);
    } catch (e) {
      print('Error checking connectivity: $e');
    }
  }

  bool get isConnected => _isConnected.value;
  RxBool get isConnectedRx => _isConnected;

  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty &&
          result.every((element) => element != ConnectivityResult.none);
    } catch (e) {
      print('Error checking internet: $e');
      return false;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}

extension ConnectivityResultExtension on List<ConnectivityResult> {
  bool get isOnline =>
      isNotEmpty && every((element) => element != ConnectivityResult.none);
  bool get isOffline => isEmpty || every((element) => element == ConnectivityResult.none);
  bool get isWifi => contains(ConnectivityResult.wifi);
  bool get isMobile => contains(ConnectivityResult.mobile);
}
