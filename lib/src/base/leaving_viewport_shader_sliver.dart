import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// An interface abstraction over FragmentShader to be used with the
/// [LeavingViewportShaderSliver].
///
/// Implementers should supply the shader instance and properly update its
/// uniform parameters in [tuneValue] method.
abstract interface class LeavingViewportShader {
  /// Returns the active [ui.FragmentShader] that should be applied
  /// over the child.
  ui.FragmentShader get shader;

  /// Updates the shader's uniforms based on the child's size, its
  /// paint offset in the canvas, and effect applying progress.
  ///
  /// - [childSize]: The size of the sliver's child widget.
  /// - [paintOffset]: The top-left offset at which the child is painted.
  /// - [progress]: A value between 0.0 and 1.0 indicating the progress of
  /// the applying effect. 0.0 means there is no effect applied, while 1.0 means
  /// the effect is fully applied.
  void tuneValue({
    required Size childSize,
    required Offset paintOffset,
    required double progress,
  });
}

/// A default implementation of the [LeavingViewportShader] which operates
/// with a [ui.FragmentShader] following the uniform ordering:
///
/// uniform vec2 uSize - size of the child;
/// uniform vec2 uOffset - offset of the child in canvas;
/// uniform float uProgress - leaving progress/effect applying progress;
class DefaultLeavingViewportShader implements LeavingViewportShader {
  final ui.FragmentShader _shader;

  DefaultLeavingViewportShader({required ui.FragmentShader shader})
      : _shader = shader;

  @override
  ui.FragmentShader get shader => _shader;

  @override
  void tuneValue({
    required Size childSize,
    required Offset paintOffset,
    required double progress,
  }) {
    _shader
      ..setFloat(0, childSize.width)
      ..setFloat(1, childSize.height)
      ..setFloat(2, paintOffset.dx)
      ..setFloat(3, paintOffset.dy)
      ..setFloat(4, progress);
  }
}

/// A sliver widget that renders its child normally, then overlays a
/// fragment shader effect as the child scrolls out of the viewport.
///
/// Use [LeavingViewportShaderSliver.fromFragmentShader] for a shorthand
/// when you have a [ui.FragmentShader] matching the default uniforms ordering.
///
/// See also:
/// - [LeavingViewportShader] a contract for implementing custom ordering of
/// uniforms.
/// - [DefaultLeavingViewportShader] for a default shader implementation.
class LeavingViewportShaderSliver extends SingleChildRenderObjectWidget {
  /// The shader to be applied over the child.
  final LeavingViewportShader? shader;

  /// Creates an instance of [LeavingViewportShaderSliver].
  const LeavingViewportShaderSliver({
    super.key,
    required Widget super.child,
    required this.shader,
  });

  /// Convenience constructor of [LeavingViewportShaderSliver] that accepts 
  /// a raw [ui.FragmentShader].
  ///
  /// Wraps the provided shader in a [DefaultLeavingViewportShader].
  LeavingViewportShaderSliver.fromFragmentShader({
    super.key,
    required Widget super.child,
    required ui.FragmentShader? shader,
  }) : shader = shader != null
            ? DefaultLeavingViewportShader(shader: shader)
            : null;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _LeavingViewportShaderRenderSliver(shader: shader);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    // An internal method, there is no public exposure of it.
    // ignore: library_private_types_in_public_api
    _LeavingViewportShaderRenderSliver renderObject,
  ) {
    renderObject.shader = shader;
  }
}

final class _LeavingViewportShaderRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  LeavingViewportShader? _shader;
  double _progress = 0;

  LeavingViewportShader? get shader => _shader;
  set shader(LeavingViewportShader? value) {
    if (_shader == value) {
      return;
    }
    _shader = value;
    markNeedsPaint();
  }

  _LeavingViewportShaderRenderSliver({
    required LeavingViewportShader? shader,
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
      final tuningShader = shader;

      if (tuningShader != null && _progress > 0) {
        final childSize = child!.size;
        final rect = Rect.fromLTWH(
          paintChildOffset.dx,
          paintChildOffset.dy,
          childSize.width,
          childSize.height,
        );

        tuningShader.tuneValue(
          childSize: childSize,
          paintOffset: paintChildOffset,
          progress: _progress,
        );

        final paint = Paint()..shader = tuningShader.shader;
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
