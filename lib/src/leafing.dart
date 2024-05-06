import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

///
class LeafingSliver extends SingleChildRenderObjectWidget {
  final ui.FragmentShader shader;

  /// Creates an instance of [LeafingSliver].
  const LeafingSliver({
    super.key,
    required Widget super.child,
    required this.shader,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return LeafingRenderSliver(shader: shader);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    LeafingRenderSliver renderObject,
  ) {
    renderObject.shader = shader;
  }
}

final class LeafingRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  ui.FragmentShader _shader;
  double _progress = 0;

  ui.FragmentShader get shader => _shader;
  set shader(ui.FragmentShader value) {
    if (_shader == value) {
      return;
    }
    _shader = value;
    markNeedsPaint();
  }

  LeafingRenderSliver({
    required ui.FragmentShader shader,
  }) : _shader = shader;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void performLayout() {
    _progress = 0;
    final constraints = this.constraints;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final childSize = child!.size;
    final double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = childSize.width;
        break;
      case Axis.vertical:
        childExtent = childSize.height;
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
      _progress = 1 - paintedChildSize / childExtent;
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
      final childParentData = child!.parentData! as SliverPhysicalParentData;
      final paintChildOffset = offset + childParentData.paintOffset;
      context.paintChild(child!, paintChildOffset);

      if (_progress > 0) {
        final childSize = child!.size;

        final rect = Rect.fromLTWH(
          paintChildOffset.dx,
          paintChildOffset.dy,
          childSize.width,
          childSize.height,
        );

        final paint = Paint()
          ..shader = (shader
            ..setFloat(0, rect.width)
            ..setFloat(1, rect.height)
            ..setFloat(2, 1 - _progress));
        context.canvas.drawRect(rect, paint);
      }
    }
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
