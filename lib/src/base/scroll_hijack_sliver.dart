import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollHijackSliver extends StatefulWidget {
  final double consumingSpaceSize;
  final Widget Function(
    BuildContext context,
    ValueListenable<double> consumingProgress,
  ) builder;

  const ScrollHijackSliver({
    super.key,
    required this.consumingSpaceSize,
    required this.builder,
  });

  @override
  State<ScrollHijackSliver> createState() => _ScrollHijackSliverState();
}

class _ScrollHijackSliverState extends State<ScrollHijackSliver> {
  final ValueNotifier<double> _consumingProgress = ValueNotifier(0.0);

  @override
  void dispose() {
    _consumingProgress.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HijackSliver(
      consumingSpaceSize: widget.consumingSpaceSize,
      child: widget.builder(
        context,
        _consumingProgress,
      ),
    );
  }
}

class _HijackSliver extends SingleChildRenderObjectWidget {
  final double consumingSpaceSize;

  const _HijackSliver({
    required this.consumingSpaceSize,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _HijackRenderSliver(
      consumingProgress: consumingSpaceSize,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _HijackRenderSliver renderObject,
  ) {
    renderObject.consumingProgress = consumingSpaceSize;
  }
}

class _HijackRenderSliver extends RenderSliverSingleBoxAdapter {
  double _consumingProgress;

  double get consumingProgress => _consumingProgress;
  set consumingProgress(double value) {
    if (_consumingProgress == value) {
      return;
    }
    _consumingProgress = value;
    markNeedsLayout();
  }

  _HijackRenderSliver({
    required double consumingProgress,
  }) : _consumingProgress = consumingProgress;

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    final constraints = this.constraints;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final childExtent = switch (constraints.axis) {
      Axis.horizontal => child!.size.width,
      Axis.vertical => child!.size.height,
    };
    // The scroll extent is the size of the child plus the amount of space
    // this sliver consumes additionally.
    final scrollExtent = childExtent + _consumingProgress;

    final paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    setChildParentData(child!, constraints, geometry!);
  }
}
