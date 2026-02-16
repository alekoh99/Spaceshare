import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

/// Custom refresh indicator styling
class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      child: child,
    );
  }
}

/// Enhanced scroll view with smooth physics
class EnhancedScrollView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final VoidCallback? onRefresh;
  final EdgeInsets? padding;

  const EnhancedScrollView({
    super.key,
    required this.children,
    this.controller,
    this.onRefresh,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: padding,
      child: Column(children: children),
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: () async => onRefresh?.call(),
        color: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        child: content,
      );
    }

    return content;
  }
}

/// Micro-interaction feedback widget - shows haptic and visual feedback
class InteractiveFeedback extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Duration duration;
  final bool enableHaptic;

  const InteractiveFeedback({
    super.key,
    required this.onPressed,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.enableHaptic = true,
  });

  @override
  State<InteractiveFeedback> createState() => _InteractiveFeedbackState();
}

class _InteractiveFeedbackState extends State<InteractiveFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    widget.onPressed();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Swipe-to-reveal actions widget
class SwipeToReveal extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context)? secondaryChild;
  final VoidCallback? onSwipe;
  final double swipeThreshold;

  const SwipeToReveal({
    super.key,
    required this.child,
    this.secondaryChild,
    this.onSwipe,
    this.swipeThreshold = 50,
  });

  @override
  State<SwipeToReveal> createState() => _SwipeToRevealState();
}

class _SwipeToRevealState extends State<SwipeToReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Offset _lastPosition;

  @override
  void initState() {
    super.initState();
    _lastPosition = Offset.zero;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHorizontalDrag(DragUpdateDetails details) {
    if (details.delta.dx < 0) {
      _lastPosition = Offset(details.delta.dx, 0);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_lastPosition.dx.abs() > widget.swipeThreshold) {
      _controller.forward().then((_) {
        widget.onSwipe?.call();
      });
    } else {
      _controller.reverse();
    }
    _lastPosition = Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleHorizontalDrag,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          if (widget.secondaryChild != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: widget.secondaryChild!(context),
              ),
            ),
          SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0),
            ).animate(_controller),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Bounce animation on scroll
class BounceTransition extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;
  final double bounceAmount;

  const BounceTransition({
    super.key,
    required this.child,
    this.scrollController,
    this.bounceAmount = 10,
  });

  @override
  State<BounceTransition> createState() => _BounceTransitionState();
}

class _BounceTransitionState extends State<BounceTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..repeat(reverse: true);

    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController?.hasClients ?? false) {
      if (widget.scrollController!.position.atEdge) {
        _controller.forward();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (sin(_controller.value * 3.14) * widget.bounceAmount)),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Floating action button with pulse animation
class PulsingFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;

  const PulsingFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip = '',
    this.backgroundColor = AppTheme.primaryColor,
    this.foregroundColor = Colors.white,
  });

  @override
  State<PulsingFAB> createState() => _PulsingFABState();
}

class _PulsingFABState extends State<PulsingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        tooltip: widget.tooltip,
        backgroundColor: widget.backgroundColor,
        child: Icon(
          widget.icon,
          color: widget.foregroundColor,
        ),
      ),
    );
  }
}
