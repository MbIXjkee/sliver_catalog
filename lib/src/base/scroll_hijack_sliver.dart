import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// A custom sliver widget that consumes a specified amount of scrollable space
/// before allowing its child to start scrolling. This widget is useful for
/// creating custom content animation based on scroll progress.
///
/// The [ScrollHijackSliver] widget takes a [consumingSpaceSize] parameter,
/// which defines the amount of scrollable space it consumes, and a [builder]
/// function that builds the child widget.
///
/// The consuming progress (how much of the space has been scrolled in
/// fractions of 1) is exposed as a [ValueListenable] to the builder function,
/// allowing dynamic updates based on the scroll progress. 0 means no space
/// has been consumed, and 1 means the entire space has already been consumed.
///
/// Change of the progress doesn't lead to automatic rebuild of the widget,
/// but changes only a value in notifier of the progress value.
///
/// Example usage:
/// ```dart
/// ScrollHijackSliver(
///   consumingSpaceSize: 100.0,
///   builder: (context, consumingProgress) {
///     return Container(
///       height: 200.0,
///       color: Colors.blue,
///       child: Center(
///         child: ValueListenableBuilder<double>(
///           valueListenable: consumingProgress,
///           builder: (context, value, child) {
///             return Text(
///               'Progress: $value',
///             );
///           },
///         ),
///       ),
///     );
///   },
/// )
/// ```
///
/// This widget is only compatible with sliver protocol.
class ScrollHijackSliver extends StatefulWidget {
  /// The size of the space that should be consumed.
  final double consumingSpaceSize;

  /// A builder function that builds the child subtree.
  final Widget Function(
    BuildContext context,
    ValueListenable<double> consumingProgress,
  ) builder;

  const ScrollHijackSliver({
    super.key,
    required this.consumingSpaceSize,
    required this.builder,
  }) : assert(
          consumingSpaceSize > 0,
          // ignore: lines_longer_than_80_chars
          'consumingSpaceSize must be positive, otherwise this sliver is useless',
        );

  @override
  State<ScrollHijackSliver> createState() => _ScrollHijackSliverState();
}

class _ScrollHijackSliverState extends State<ScrollHijackSliver>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _consumingProgress = ValueNotifier(0.0);
  late final Ticker _ticker;

  double _lastHandled = 0;
  double _toHandle = 0;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker
      ..stop(canceled: true)
      ..dispose();

    _consumingProgress.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HijackSliver(
      consumingSpaceSize: widget.consumingSpaceSize,
      onProgressChanged: _onProgressChanged,
      child: widget.builder(
        context,
        _consumingProgress,
      ),
    );
  }

  // ignore: use_setters_to_change_properties
  void _onProgressChanged(double newProgress) {
    _toHandle = newProgress;

    if (_toHandle != _lastHandled) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final last = _lastHandled;
    final current = _toHandle;
    if (last != current) {
      _consumingProgress.value =
          clampDouble(current / widget.consumingSpaceSize, 0.0, 1.0);
      _lastHandled = current;
    }

    _ticker.stop();
  }
}

class _HijackSliver extends SingleChildRenderObjectWidget {
  final double consumingSpaceSize;
  final void Function(double progress) onProgressChanged;

  const _HijackSliver({
    required this.consumingSpaceSize,
    required this.onProgressChanged,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _HijackRenderSliver(
      consumingProgress: consumingSpaceSize,
      onProgressChanged: onProgressChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _HijackRenderSliver renderObject,
  ) {
    renderObject
      ..consumingProgress = consumingSpaceSize
      ..onProgressChanged = onProgressChanged;
  }
}

class _HijackRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  double _consumingProgress;
  void Function(double progress) _onProgressChanged;

  bool get _isConsumingSpace => constraints.scrollOffset <= _consumingProgress;

  double get _correctedScrollOffset =>
      constraints.scrollOffset - _consumingProgress;

  double get consumingProgress => _consumingProgress;
  set consumingProgress(double value) {
    if (_consumingProgress == value) {
      return;
    }
    _consumingProgress = value;
    markNeedsLayout();
  }

  void Function(double progress) get onProgressChanged => _onProgressChanged;
  set onProgressChanged(void Function(double progress) value) {
    if (_onProgressChanged == value) {
      return;
    }
    _onProgressChanged = value;
    markNeedsLayout();
  }

  _HijackRenderSliver({
    required double consumingProgress,
    required void Function(double progress) onProgressChanged,
  })  : _consumingProgress = consumingProgress,
        _onProgressChanged = onProgressChanged;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

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

    final paintedChildSize = _calculatePaintExtent(childExtent);
    final cacheExtent = _calculateCacheExtent(childExtent);

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
    _setChildParentData(child!, constraints, geometry!);
    _updateConsumingProgress();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      final childParentData = child!.parentData! as SliverPhysicalParentData;
      final childPaintOffset = childParentData.paintOffset;
      context.paintChild(child!, offset + childPaintOffset);
    }
  }

  double _calculatePaintExtent(double childExtent) {
    final remainingPaintExtent = constraints.remainingPaintExtent;

    if (_isConsumingSpace) {
      // still consuming space;
      if (childExtent > remainingPaintExtent) {
        return remainingPaintExtent;
      }

      return childExtent;
    } else {
      // finish consuming, calculate moving
      final correctedScrollOffset = _correctedScrollOffset;

      final maxActiveExtent = correctedScrollOffset + remainingPaintExtent;

      return clampDouble(
        clampDouble(childExtent, correctedScrollOffset, maxActiveExtent) -
            clampDouble(0, correctedScrollOffset, maxActiveExtent),
        0.0,
        remainingPaintExtent,
      );
    }
  }

  double _calculateCacheExtent(double childExtent) {
    final remainingCacheExtent = constraints.remainingCacheExtent;

    if (_isConsumingSpace) {
      if (childExtent > remainingCacheExtent) {
        return remainingCacheExtent;
      }

      return childExtent;
    } else {
      // finish consuming, calculate moving
      final correctedScrollOffset = _correctedScrollOffset;

      var scrolledOverCache = correctedScrollOffset + constraints.cacheOrigin;
      if (scrolledOverCache < 0) {
        // Since cacheOrigin grows with scroll offset by module up to cache area
        // size, we can put it as a fact - we cannot calculate corrected
        // cacheOrigin, but it should be -correctedScrollOffset and give 0,
        // while we have negative value.
        scrolledOverCache = 0;
      }
      final maxPossibleExtent = correctedScrollOffset + remainingCacheExtent;

      return clampDouble(
        clampDouble(0, scrolledOverCache, maxPossibleExtent) -
            clampDouble(childExtent, scrolledOverCache, maxPossibleExtent),
        0.0,
        remainingCacheExtent,
      );
    }
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    if (_isConsumingSpace) {
      return 0;
    }

    return -_correctedScrollOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    (child.parentData! as SliverPhysicalParentData)
        .applyPaintTransform(transform);
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    assert(geometry!.hitTestExtent > 0.0);
    if (child != null) {
      return hitTestBoxChild(
        BoxHitTestResult.wrap(result),
        child!,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      );
    }
    return false;
  }

  void _setChildParentData(
    RenderObject child,
    SliverConstraints constraints,
    SliverGeometry geometry,
  ) {
    final childParentData = child.parentData! as SliverPhysicalParentData;
    final actualGrowthDirection = applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    );

    final paintOffset = switch (actualGrowthDirection) {
      AxisDirection.up => _isConsumingSpace
          ? Offset.zero
          : Offset(
              0.0,
              geometry.paintExtent +
                  constraints.scrollOffset -
                  geometry.scrollExtent,
            ),
      AxisDirection.left => _isConsumingSpace
          ? Offset.zero
          : Offset(
              geometry.paintExtent +
                  constraints.scrollOffset -
                  geometry.scrollExtent,
              0.0,
            ),
      AxisDirection.right =>
        _isConsumingSpace ? Offset.zero : Offset(-_correctedScrollOffset, 0.0),
      AxisDirection.down =>
        _isConsumingSpace ? Offset.zero : Offset(0.0, -_correctedScrollOffset),
    };

    childParentData.paintOffset = paintOffset;
  }

  void _updateConsumingProgress() {
    onProgressChanged(
      clampDouble(
        constraints.scrollOffset,
        0,
        consumingProgress,
      ),
    );
  }
}
