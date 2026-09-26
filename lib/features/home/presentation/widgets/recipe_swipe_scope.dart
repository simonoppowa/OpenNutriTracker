import 'package:flutter/material.dart';

/// Keeps one recipe action open across all meal sections on a screen.
class RecipeSwipeScope extends StatefulWidget {
  final Widget child;
  final bool active;

  const RecipeSwipeScope({super.key, required this.child, this.active = true});

  static RecipeSwipeController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_RecipeSwipeScope>()
      ?.controller;

  @override
  State<RecipeSwipeScope> createState() => _RecipeSwipeScopeState();
}

class _RecipeSwipeScopeState extends State<RecipeSwipeScope> {
  final _controller = RecipeSwipeController();

  @override
  void didUpdateWidget(RecipeSwipeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _controller.close();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) == false) _controller.close();
  }

  @override
  Widget build(BuildContext context) => _RecipeSwipeScope(
    controller: _controller,
    child: NotificationListener<ScrollStartNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) _controller.close();
        return false;
      },
      child: widget.child,
    ),
  );
}

class RecipeSwipeController {
  VoidCallback? _close;

  void open(VoidCallback close) {
    if (_close == close) return;
    this.close();
    _close = close;
  }

  void release(VoidCallback close) {
    if (_close == close) _close = null;
  }

  void close() {
    final close = _close;
    _close = null;
    close?.call();
  }
}

class _RecipeSwipeScope extends InheritedWidget {
  final RecipeSwipeController controller;

  const _RecipeSwipeScope({required this.controller, required super.child});

  @override
  bool updateShouldNotify(_RecipeSwipeScope oldWidget) =>
      controller != oldWidget.controller;
}
