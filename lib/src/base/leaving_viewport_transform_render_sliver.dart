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
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    assert(geometry!.hitTestExtent > 0.0);
    if (child != null) {
      // Например, если у тебя есть матрица трансформации:
      final transform = _paintTransform ?? Matrix4.identity();

      // Инвертируем
      final inverse = Matrix4.tryInvert(transform);
      if (inverse == null) return false;

      // Преобразуем точку
      final localOffset = MatrixUtils.transformPoint(
        inverse,
        Offset(crossAxisPosition, mainAxisPosition),
      );

      // Используем преобразованные координаты
      return hitTestBoxChild(
        BoxHitTestResult.wrap(result),
        child!,
        mainAxisPosition: localOffset.dy,
        crossAxisPosition: localOffset.dx,
      );
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
