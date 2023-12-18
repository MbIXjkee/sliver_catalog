import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const double _kQuarterTurnsInRadians = math.pi / 2.0;

/// The sliver widget that rotate around one of bottom corners while moving out
/// from the screen. Widget has no own sizes, and bases all calculations on the
/// child dimensions.
/// At the last moment of leaving the screen, this widget will be rotated to 
/// [maxAngle] radians around the anchor point. Before this moment rotation will
/// be proportional to the leaved part of the widget.
class SpinnerSliver extends SingleChildRenderObjectWidget {
  /// The side of the rotation point.
  final SpinnerAnchorSide anchorSide;

  /// The maximum angle of rotation in radians.
  final double maxAngle;

  /// Creates an instance of [SpinnerSliver].
  const SpinnerSliver({
    super.key,
    required Widget super.child,
    this.anchorSide = SpinnerAnchorSide.left,
    this.maxAngle = _kQuarterTurnsInRadians,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return SpinnerRenderSliver(anchorSide: anchorSide);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    SpinnerRenderSliver renderObject,
  ) {
    renderObject
      ..anchorSide = anchorSide
      ..maxAngle = maxAngle;
  }
}

final class SpinnerRenderSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  SpinnerAnchorSide _anchorSide;
  double _maxAngle;

  final LayerHandle<TransformLayer> _transformLayer =
      LayerHandle<TransformLayer>();
  Matrix4? _paintTransform;

  SpinnerAnchorSide get anchorSide => _anchorSide;
  set anchorSide(SpinnerAnchorSide value) {
    if (_anchorSide == value) {
      return;
    }
    _anchorSide = value;
    markNeedsLayout();
  }

  double get maxAngle => _maxAngle;
  set maxAngle(double value) {
    if (_maxAngle == value) {
      return;
    }
    _maxAngle = value;
    markNeedsLayout();
  }

  SpinnerRenderSliver({
    required SpinnerAnchorSide anchorSide,
    double maxAngle = _kQuarterTurnsInRadians,
  })  : _anchorSide = anchorSide,
        _maxAngle = maxAngle;

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
    final double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
        break;
      case Axis.vertical:
        childExtent = child!.size.height;
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
      final angle = _maxAngle * (1 - paintedChildSize / childExtent);
      final rotation = angle * (anchorSide == SpinnerAnchorSide.left ? -1 : 1);

      final translation = _calculateTranslation(
        Size(
          child!.size.width,
          paintedChildSize,
        ),
      );

      _paintTransform = Matrix4.identity()
        ..translate(translation.dx, translation.dy)
        ..rotateZ(rotation)
        ..translate(-translation.dx, -translation.dy);
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

  Offset _calculateTranslation(Size size) {
    switch (_anchorSide) {
      case SpinnerAnchorSide.left:
        return FractionalOffset.bottomLeft.alongSize(size);
      case SpinnerAnchorSide.right:
        return FractionalOffset.bottomRight.alongSize(size);
    }
  }
}

/// Describes the side of the anchor.
enum SpinnerAnchorSide {
  /// Anchor side is left.
  left,

  /// Anchor side is right.
  right,
}
