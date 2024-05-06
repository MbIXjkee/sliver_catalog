import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sliver_catalog/src/base/leaving_transform_render_sliver.dart';

const double _kQuarterTurnsInRadians = math.pi / 2.0;

/// The sliver widget that rotates around one of the latest side corners
/// while moving out from the screen.
/// The widget doesn't have its own size, and all calculations are based on the
/// child dimensions.
/// When the last part of this widget leaves the screen, it is rotated to
/// [maxAngle] radians around the anchor point.
/// Before this moment, rotation is proportional to the part of the widget that
/// has already left the screen.
/// If the size of the widget is bigger than the available viewport size,
/// the rotation starts as soon as the anchor point appears in the visible
/// part of the viewport, and the calculations of the rotation are based on the
/// size of the visible part of the viewport.
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

final class SpinnerRenderSliver extends LeavingTransformRenderSliver {
  SpinnerAnchorSide _anchorSide;
  double _maxAngle;

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

  bool get _isReversed =>
      constraints.normalizedGrowthDirection == GrowthDirection.reverse;

  SpinnerRenderSliver({
    required SpinnerAnchorSide anchorSide,
    double maxAngle = _kQuarterTurnsInRadians,
  })  : _anchorSide = anchorSide,
        _maxAngle = maxAngle;

  @override
  Matrix4? performTransform(Size childSize, double leavingProgress) {
    final angle = _maxAngle * leavingProgress;
    final rotation = angle * (anchorSide == SpinnerAnchorSide.left ? -1 : 1);

    late final Size size;
    if (constraints.axis == Axis.horizontal) {
      size = Size(
        geometry!.paintExtent,
        childSize.height,
      );
    } else {
      size = Size(
        childSize.width,
        geometry!.paintExtent,
      );
    }

    final translation = _calculateTranslation(size);

    return Matrix4.identity()
      ..translate(translation.dx, translation.dy)
      ..rotateZ(_isReversed ? -rotation : rotation)
      ..translate(-translation.dx, -translation.dy);
  }

  Offset _calculateTranslation(Size size) {
    late final FractionalOffset offset;
    if (constraints.axis == Axis.horizontal) {
      offset = _anchorSide == SpinnerAnchorSide.left
          ? FractionalOffset.bottomRight
          : FractionalOffset.topRight;
    } else {
      if (_isReversed) {
        offset = _anchorSide == SpinnerAnchorSide.left
            ? FractionalOffset.topLeft
            : FractionalOffset.topRight;
      } else {
        offset = _anchorSide == SpinnerAnchorSide.left
            ? FractionalOffset.bottomLeft
            : FractionalOffset.bottomRight;
      }
    }

    return offset.alongSize(size);
  }
}

// TODO: описать норм.
/// Defines the side of the anchor relative the main axis of the viewport.
enum SpinnerAnchorSide {
  /// Anchor at the left side.
  left,

  /// Anchor at the right side.
  right,
}
