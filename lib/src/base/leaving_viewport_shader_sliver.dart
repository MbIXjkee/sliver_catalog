import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A base implementation of the sliver that applies a [shader] on top of the
/// child during the leaving of the visual part of the viewport.
///
/// Shader is a [ui.FragmentShader] which should operate with
/// the following params:
/// uniform vec2 uSize - size of the child;
/// uniform vec2 uOffset - offset of the child in canvas;
/// uniform float uProgress - leaving progress;
class LeavingViewportShaderSliver extends SingleChildRenderObjectWidget {
  /// The shader to apply to the child.
  final ui.FragmentShader? shader;

  /// Creates an instance of [LeavingViewportShaderSliver].
  const LeavingViewportShaderSliver({
    super.key,
    required Widget super.child,
    required this.shader,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return LeavingViewportShaderRenderSliver(shader: shader);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    LeavingViewportShaderRenderSliver renderObject,
  ) {
    renderObject.shader = shader;
  }
}

final class LeavingViewportShaderRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  ui.FragmentShader? _shader;
  double _progress = 0;

  ui.FragmentShader? get shader => _shader;
  set shader(ui.FragmentShader? value) {
    if (_shader == value) {
      return;
    }
    _shader = value;
    markNeedsPaint();
  }

  LeavingViewportShaderRenderSliver({
    required ui.FragmentShader? shader,
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
      final tunedShader = shader;

      if (tunedShader != null && _progress > 0) {
        final childSize = child!.size;
        final rect = Rect.fromLTWH(
          paintChildOffset.dx,
          paintChildOffset.dy,
          childSize.width,
          childSize.height,
        );

        tunedShader
          ..setFloat(0, childSize.width)
          ..setFloat(1, childSize.height)
          ..setFloat(2, paintChildOffset.dx)
          ..setFloat(3, paintChildOffset.dy)
          ..setFloat(4, _progress);

        final paint = Paint()..shader = tunedShader;
        context.canvas.drawRect(rect, paint);
      }
    }
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

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child);
    (child.parentData! as SliverPhysicalParentData)
        .applyPaintTransform(transform);
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return -constraints.scrollOffset;
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
