import 'dart:async';

/// Debounce utility to prevent multiple rapid function calls
class Debounce {
  Timer? _timer;
  final Duration duration;

  Debounce({Duration? duration}) : duration = duration ?? const Duration(milliseconds: 500);

  /// Execute function after debounce duration
  void call(Function() callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
  }

  /// Cancel pending debounced call
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}

/// Throttle utility to limit function calls to once per interval
class Throttle {
  Timer? _timer;
  final Duration interval;
  bool _isThrottled = false;

  Throttle({Duration? interval}) : interval = interval ?? const Duration(milliseconds: 500);

  /// Execute function if not throttled
  void call(Function() callback) {
    if (!_isThrottled) {
      _isThrottled = true;
      callback();

      _timer = Timer(interval, () {
        _isThrottled = false;
      });
    }
  }

  /// Cancel throttle state
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _isThrottled = false;
  }

  void dispose() => cancel();
}
