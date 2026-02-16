import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Manages page lifecycle for better performance and state management
/// Handles:
/// - Page initialization and disposal
/// - Loading states
/// - Error handling
/// - Memory cleanup
class PageLifecycleManager with WidgetsBindingObserver {
  static final PageLifecycleManager _instance = PageLifecycleManager._internal();
  
  factory PageLifecycleManager() {
    return _instance;
  }
  
  PageLifecycleManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final Map<String, PageLifecycleListener> _listeners = {};

  void registerPage(String pageKey, PageLifecycleListener listener) {
    _listeners[pageKey] = listener;
    AppLogger.debug('PageLifecycle', 'Page registered: $pageKey');
  }

  void unregisterPage(String pageKey) {
    _listeners.remove(pageKey);
    AppLogger.debug('PageLifecycle', 'Page unregistered: $pageKey');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    for (final listener in _listeners.values) {
      switch (state) {
        case AppLifecycleState.resumed:
          listener.onResume?.call();
          break;
        case AppLifecycleState.paused:
          listener.onPause?.call();
          break;
        case AppLifecycleState.detached:
          listener.onDetached?.call();
          break;
        case AppLifecycleState.hidden:
          listener.onHidden?.call();
          break;
        default:
          break;
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listeners.clear();
  }
}

/// Listener interface for page lifecycle events
class PageLifecycleListener {
  final VoidCallback? onResume;
  final VoidCallback? onPause;
  final VoidCallback? onDetached;
  final VoidCallback? onHidden;

  PageLifecycleListener({
    this.onResume,
    this.onPause,
    this.onDetached,
    this.onHidden,
  });
}

/// Widget for managing page initialization and cleanup
class PageLifecycleWidget extends StatefulWidget {
  final String pageKey;
  final Widget child;
  final Future<void> Function()? onInit;
  final Future<void> Function()? onDispose;
  final bool enableLogging;

  const PageLifecycleWidget({super.key, 
    required this.pageKey,
    required this.child,
    this.onInit,
    this.onDispose,
    this.enableLogging = true,
  });

  @override
  State<PageLifecycleWidget> createState() => _PageLifecycleWidgetState();
}

class _PageLifecycleWidgetState extends State<PageLifecycleWidget>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (widget.enableLogging) {
        AppLogger.debug('PageLifecycle', 'Initializing: ${widget.pageKey}');
      }
      
      await widget.onInit?.call();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.enableLogging) {
          AppLogger.debug('PageLifecycle', 'Initialized: ${widget.pageKey}');
        }
      }
    } catch (e) {
      AppLogger.error('PageLifecycle', 'Init failed for ${widget.pageKey}', e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (widget.enableLogging) {
        AppLogger.debug('PageLifecycle', 'Page paused: ${widget.pageKey}');
      }
    } else if (state == AppLifecycleState.resumed) {
      if (widget.enableLogging) {
        AppLogger.debug('PageLifecycle', 'Page resumed: ${widget.pageKey}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  Future<void> _cleanup() async {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      if (widget.enableLogging) {
        AppLogger.debug('PageLifecycle', 'Disposing: ${widget.pageKey}');
      }
      
      await widget.onDispose?.call();
      
      if (widget.enableLogging) {
        AppLogger.debug('PageLifecycle', 'Disposed: ${widget.pageKey}');
      }
    } catch (e) {
      AppLogger.error('PageLifecycle', 'Dispose failed for ${widget.pageKey}', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
