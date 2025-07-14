import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// Defines the behavior for calculating progress in [ScrollHijackSliver].
///
/// This determines which parts of the sliver's layout and scroll offset
/// are considered when computing the normalized progress value
/// (from 0.0 to 1.0).
enum ScrollHijackProgressBehavior {
  /// Progress is calculated only based on how much of the scroll extent
  /// has been consumed by the sliver relative to consumingSpaceSize.
  ///
  /// Treated as:
  /// `progress = consumedExtent / consumingSpaceSize`
  onlyConsumingSpace,

  /// Progress is calculated based on the consumed extent and how much of
  /// the sliver has already been scrolled past (outside the viewport).
  ///
  /// Treated as:
  /// `progress = (consumedExtent + scrolledOutExtent) /
  /// (consumingSpaceSize + childExtent)`
  consumingSpaceAndMoving,
}

/// A custom sliver widget that consumes a specified amount of scrollable space
/// before allowing its child to start scrolling. This widget is useful for
/// creating custom content animation based on scroll progress.
///
/// The [ScrollHijackSliver] widget takes a [consumingSpaceSize] parameter,
/// which defines the amount of scrollable space it consumes before
/// start moving, [progressBehavior] to define how to process the progress,
/// and a [builder] function that builds the child widget.
///
/// The consuming progress (how much of the space has been scrolled as a value
/// between 0.0 and 1.0) is exposed as a [ValueListenable] to the builder
/// function, allowing dynamic updates based on the scroll progress.
/// The meaning of progress depends on [progressBehavior]:
/// - For [ScrollHijackProgressBehavior.onlyConsumingSpace], 0 means no space
///   has been consumed, and 1 means the entire [consumingSpaceSize]
///   has been consumed.
/// - For [ScrollHijackProgressBehavior.consumingSpaceAndMoving], 0 means
///   no space has been consumed, and 1 means both the consuming space and the
///   child have fully scrolled through the viewport.
///
/// Note:
/// - Changing progress does not trigger a widget rebuild.
///   Instead, the [ValueListenable] updates independently and should be
///   observed (e.g., with [ValueListenableBuilder]) to reflect changes.
/// - This widget is only compatible with sliver protocol.
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
/// See also:
///
/// * [ScrollHijackProgressBehavior] — defines how progress is calculated.
/// * [ValueListenableBuilder] — to react to scroll progress changes.
/// * [RenderSliver] — base protocol for custom sliver rendering.
class ScrollHijackSliver extends StatefulWidget {
  /// The size of the space that should be consumed.
  final double consumingSpaceSize;

  /// Describes how the progress is calculated.
  final ScrollHijackProgressBehavior progressBehavior;

  /// A builder function that builds the child subtree.
  final Widget Function(
    BuildContext context,
    ValueListenable<double> consumingProgress,
  ) builder;

  const ScrollHijackSliver({
    super.key,
    required this.consumingSpaceSize,
    required this.builder,
    this.progressBehavior = ScrollHijackProgressBehavior.onlyConsumingSpace,
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
      progressBehavior: widget.progressBehavior,
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

    if (_toHandle != _consumingProgress.value) {
      if (!_ticker.isActive) {
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  void _onTick(Duration _) {
    _consumingProgress.value = _toHandle;

    _ticker.stop();
  }
}

class _HijackSliver extends SingleChildRenderObjectWidget {
  final double consumingSpaceSize;
  final ScrollHijackProgressBehavior progressBehavior;
  final void Function(double progress) onProgressChanged;

  const _HijackSliver({
    required this.consumingSpaceSize,
    required this.progressBehavior,
    required this.onProgressChanged,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _HijackRenderSliver(
      consumingSpaceSize: consumingSpaceSize,
      progressBehavior: progressBehavior,
      onProgressChanged: onProgressChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _HijackRenderSliver renderObject,
  ) {
    renderObject
      ..consumingSpaceSize = consumingSpaceSize
      ..progressBehavior = progressBehavior
      ..onProgressChanged = onProgressChanged;
  }
}

class _HijackRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  double _consumingSpaceSize;
  ScrollHijackProgressBehavior _progressBehavior;
  void Function(double progress) _onProgressChanged;

  bool get _isConsumingSpace => constraints.scrollOffset <= _consumingSpaceSize;

  double get _correctedScrollOffset =>
      constraints.scrollOffset - _consumingSpaceSize;

  double get consumingSpaceSize => _consumingSpaceSize;
  set consumingSpaceSize(double value) {
    if (_consumingSpaceSize == value) {
      return;
    }
    _consumingSpaceSize = value;
    markNeedsLayout();
  }

  ScrollHijackProgressBehavior get progressBehavior => _progressBehavior;
  set progressBehavior(ScrollHijackProgressBehavior value) {
    if (_progressBehavior == value) {
      return;
    }
    _progressBehavior = value;
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
    required double consumingSpaceSize,
    required ScrollHijackProgressBehavior progressBehavior,
    required void Function(double progress) onProgressChanged,
  })  : _consumingSpaceSize = consumingSpaceSize,
        _progressBehavior = progressBehavior,
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
    final scrollExtent = childExtent + _consumingSpaceSize;

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
          _correctedScrollOffset > 0.0,
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
      AxisDirection.up => Offset.zero,
      AxisDirection.left => Offset.zero,
      AxisDirection.right =>
        _isConsumingSpace ? Offset.zero : Offset(-_correctedScrollOffset, 0.0),
      AxisDirection.down =>
        _isConsumingSpace ? Offset.zero : Offset(0.0, -_correctedScrollOffset),
    };

    childParentData.paintOffset = paintOffset;
  }

  void _updateConsumingProgress() {
    final scrollOffset = constraints.scrollOffset;
    final totalExtent =
        _progressBehavior == ScrollHijackProgressBehavior.onlyConsumingSpace
            ? _consumingSpaceSize
            : geometry!.scrollExtent;
    final progress = clampDouble(scrollOffset / totalExtent, 0.0, 1.0);

    onProgressChanged(progress);
  }
}
