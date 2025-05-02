import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// A base implementation of the sliver that performs a transformation
/// during the leaving of the visual part of the viewport.
///
/// Transformation is defined by the function [performTransform].
///
/// The size of this render object is based on the child size. And the progress
/// of the transformation is calculated based on the visible part of this object
/// compared to the whole size of the object.
///
/// If the size is bigger than the viewport size, the transformation starts as
/// soon as the latest part appears in the visible part of the viewport, and the
/// calculation of the progress is based on the size of the visible part of the
/// object compared to the viewport size.
abstract class LeavingViewportTransformedRenderSliver
    extends RenderSliverSingleBoxAdapter {
  final _transformLayer = LayerHandle<TransformLayer>();
  Matrix4? _paintTransform;

  @protected
  Matrix4? get paintTransform => _paintTransform;

  /// A function that defines the transformation applied to the child.
  Matrix4? performTransform(Size childSize, double leavingProgress);

  /// Function that allows inheritance to define a special behavior of the
  /// hit test.
  /// Null by default means there is no hit test override.
  bool? performHitTest({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return null;
  }

  @override
  void performLayout() {
    _paintTransform = null;

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
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    final cacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: childExtent,
    );

    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );

    setChildParentData(child!, constraints, geometry!);

    final sizeLimit = math.min(childExtent, constraints.remainingPaintExtent);
    if (constraints.scrollOffset > 0 &&
        paintedChildSize > 0 &&
        paintedChildSize < sizeLimit) {
      _paintTransform = performTransform(
        childSize,
        1 - paintedChildSize / sizeLimit,
      );
    }
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

    super.applyPaintTransform(child, transform);
  }

  @override
  bool hitTest(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    // Check if hit test is overridden.
    final overrideHaveHit = performHitTest(
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );

    if (overrideHaveHit == null) {
      // Follow the default hit test behavior for the sliver.
      final transform = _paintTransform ?? Matrix4.identity();
      final inverse = Matrix4.tryInvert(transform);
      if (inverse == null) {
        // Matrix is not invertible, so we can't perform hit test.
        return false;
      }

      // Calculate the raw offset based on the main and cross axis positions.
      final rawOffset = constraints.axis == Axis.horizontal
          ? Offset(mainAxisPosition, crossAxisPosition)
          : Offset(crossAxisPosition, mainAxisPosition);

      final localOffset = MatrixUtils.transformPoint(inverse, rawOffset);

      // Calculate the adjusted main and cross axis positions to provide to the
      // child for checking hit test.
      final adjustedMain =
          constraints.axis == Axis.horizontal ? localOffset.dx : localOffset.dy;
      final adjustedCross =
          constraints.axis == Axis.horizontal ? localOffset.dy : localOffset.dx;

      var haveHit = hitTestChildren(
        result,
        mainAxisPosition: adjustedMain,
        crossAxisPosition: adjustedCross,
      );

      if (!haveHit) {
        // If the hit test didn't hit any children, we can check if the sliver
        // itself has hit, which is unlikely to happen since it is just a
        // container for transforming the child.
        haveHit = hitTestSelf(
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        );
      }

      if (haveHit) {
        result.add(
          SliverHitTestEntry(
            this,
            mainAxisPosition: mainAxisPosition,
            crossAxisPosition: crossAxisPosition,
          ),
        );
        return true;
      }
    } else if (overrideHaveHit) {
      // Rely on information from the override.
      result.add(
        SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        ),
      );
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _transformLayer.layer = null;
    super.dispose();
  }

  @pragma('vm:prefer-inline')
  void _paintChild(PaintingContext context, Offset offset) {
    final childParentData = child!.parentData! as SliverPhysicalParentData;
    context.paintChild(child!, offset + childParentData.paintOffset);
  }
}
