import 'package:flutter/material.dart';

/// Animation utilities for smooth transitions and micro-interactions
class AnimationUtils {
  /// Standard curves for animations
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve smoothCurve = Curves.ease;
  static const Curve snappyCurve = Curves.easeOutQuart;
  static const Curve smoothCurveDecel = Curves.easeOutCubic;

  /// Standard durations
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration standardDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration verySlowDuration = Duration(milliseconds: 800);

  /// Build a fade-in animation
  static Widget buildFadeInAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration duration = standardDuration,
  }) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Build a slide-up animation
  static Widget buildSlideUpAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration duration = standardDuration,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: smoothCurveDecel),
      ),
      child: child,
    );
  }

  /// Build a scale animation
  static Widget buildScaleAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration duration = standardDuration,
    double beginScale = 0.8,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: beginScale, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: snappyCurve),
      ),
      child: child,
    );
  }

  /// Build combined fade and scale animation
  static Widget buildFadeScaleAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration duration = standardDuration,
  }) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Build a rotation animation
  static Widget buildRotationAnimation({
    required Widget child,
    required Animation<double> animation,
    Duration duration = standardDuration,
  }) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  /// Stagger animation list - each item animates with a delay
  static List<Widget> buildStaggerAnimation({
    required List<Widget> children,
    required Animation<double> parentAnimation,
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    return List.generate(children.length, (index) {
      final beginTime = (index * staggerDelay.inMilliseconds) /
          Duration.secondsPerMinute /
          1000;
      final interval = Interval(beginTime, 1.0, curve: Curves.easeInOut);

      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: parentAnimation,
            curve: interval,
          ),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: parentAnimation,
              curve: interval,
            ),
          ),
          child: children[index],
        ),
      );
    });
  }
}

/// Page route transition with custom animation
class SlidePageRoute extends PageRouteBuilder {
  final Widget page;

  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            final tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Fade page route transition
class FadePageRoute extends PageRouteBuilder {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Scale page route transition
class ScalePageRoute extends PageRouteBuilder {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutQuart),
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// Animated button with tap feedback
class AnimatedTapButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Duration duration;

  const AnimatedTapButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedTapButton> createState() => _AnimatedTapButtonState();
}

class _AnimatedTapButtonState extends State<AnimatedTapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Animated counter widget
class AnimatedCounter extends StatefulWidget {
  final int start;
  final int end;
  final Duration duration;
  final TextStyle textStyle;
  final String suffix;

  const AnimatedCounter({
    super.key,
    this.start = 0,
    required this.end,
    this.duration = const Duration(milliseconds: 800),
    this.textStyle = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    this.suffix = '',
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(begin: widget.start, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value}${widget.suffix}',
          style: widget.textStyle,
        );
      },
    );
  }
}

/// Animated progress bar with smooth transitions
class AnimatedProgressBar extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final Duration duration;
  final Color backgroundColor;
  final Color valueColor;
  final double height;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 500),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.valueColor = const Color(0xFF4CAF50),
    this.height = 8.0,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: LinearProgressIndicator(
            value: _animation.value,
            backgroundColor: widget.backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(widget.valueColor),
            minHeight: widget.height,
          ),
        );
      },
    );
  }
}

/// Smooth transition between two widgets
class AnimatedCrossFadeAdvanced extends StatefulWidget {
  final Widget firstChild;
  final Widget secondChild;
  final bool showFirst;
  final Duration duration;

  const AnimatedCrossFadeAdvanced({
    super.key,
    required this.firstChild,
    required this.secondChild,
    required this.showFirst,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedCrossFadeAdvanced> createState() =>
      _AnimatedCrossFadeAdvancedState();
}

class _AnimatedCrossFadeAdvancedState extends State<AnimatedCrossFadeAdvanced>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    if (!widget.showFirst) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCrossFadeAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showFirst != widget.showFirst) {
      if (widget.showFirst) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 1 - _controller.value,
          child: widget.firstChild,
        ),
        Opacity(
          opacity: _controller.value,
          child: widget.secondChild,
        ),
      ],
    );
  }
}
