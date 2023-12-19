import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The sliver widget that slipping left or right while moving out
/// from the screen. Widget has no own sizes, and bases all calculations on the
/// child dimensions.
class GliderSliver extends SingleChildRenderObjectWidget {
  /// Describe the side to which widget is moving out.
  final GliderExitSide exitSide;

  /// Creates an instance of [GliderSliver].
  const GliderSliver({
    super.key,
    required Widget super.child,
    this.exitSide = GliderExitSide.left,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GliderRenderSliver(exitSide: exitSide);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    GliderRenderSliver renderObject,
  ) {
    renderObject.exitSide = exitSide;
  }
}

final class GliderRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  GliderExitSide _exitSide;

  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();
  Matrix4? _paintTransform;

  GliderExitSide get exitSide => _exitSide;
  set exitSide(GliderExitSide value) {
    if (_exitSide == value) {
      return;
    }
    _exitSide = value;
    markNeedsLayout();
  }

  GliderRenderSliver({
    GliderExitSide exitSide = GliderExitSide.left,
  }) : _exitSide = exitSide;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void performLayout() {
    _paintTransform = null;

    final constraints = this.constraints;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final childSize = child!.size;
    final double childExtent;
    final double childCrossExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = childSize.width;
        childCrossExtent = childSize.height;
        break;
      case Axis.vertical:
        childExtent = childSize.height;
        childCrossExtent = childSize.width;
        break;
    }

    final paintedChildSize = calculatePaintOffset(
      constraints,
      from: 0.0,
      to: childExtent,
    );
    final cacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: childExtent,
    );

    final scrollOffset = constraints.scrollOffset;

    if (scrollOffset > 0 && paintedChildSize > 0) {
      final dx = childCrossExtent * (1 - paintedChildSize / childExtent);
      final translation = dx * (exitSide == GliderExitSide.left ? -1 : 1);
      _paintTransform = Matrix4.identity()..translate(translation);
    }

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );

    _setChildParentData(child!, constraints, geometry!);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry!.visible) {
      _transformLayer.layer = context.pushTransform(
        needsCompositing,
        offset,
        _paintTransform ?? Matrix4.identity(),
        _paintChild,
        oldLayer: _transformLayer.layer,
      );
    } else {
      _transformLayer.layer = null;
    }
  }

  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    if (_paintTransform != null) {
      transform.multiply(_paintTransform!);
    }
    final childParentData = child.parentData! as SliverPhysicalParentData;

    // for make it more readable
    // ignore: cascade_invocations
    childParentData.applyPaintTransform(transform);
  }

  @override
  void dispose() {
    _transformLayer.layer = null;
    super.dispose();
  }

  void _paintChild(PaintingContext context, Offset offset) {
    final childParentData = child!.parentData! as SliverPhysicalParentData;
    context.paintChild(child!, offset + childParentData.paintOffset);
  }

  void _setChildParentData(
    RenderObject child,
    SliverConstraints constraints,
    SliverGeometry geometry,
  ) {
    final childParentData = child.parentData! as SliverPhysicalParentData;
    var dx = 0.0;
    var dy = 0.0;
    switch (applyGrowthDirectionToAxisDirection(
      constraints.axisDirection,
      constraints.growthDirection,
    )) {
      case AxisDirection.up:
        dy = -(geometry.scrollExtent -
            (geometry.paintExtent + constraints.scrollOffset));
        break;
      case AxisDirection.right:
        dx = -constraints.scrollOffset;
        break;
      case AxisDirection.down:
        dy = -constraints.scrollOffset;
        break;
      case AxisDirection.left:
        dx = -(geometry.scrollExtent -
            (geometry.paintExtent + constraints.scrollOffset));
        break;
    }

    childParentData.paintOffset = Offset(dx, dy);
  }
}

/// Describes the side to which widget is moving out.
enum GliderExitSide {
  /// From right to left.
  left,

  /// From left to right.
  right,
}
