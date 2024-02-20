import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sliver_catalog/src/base/leaving_transform_render_sliver.dart';

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

  SpinnerRenderSliver({
    required SpinnerAnchorSide anchorSide,
    double maxAngle = _kQuarterTurnsInRadians,
  })  : _anchorSide = anchorSide,
        _maxAngle = maxAngle;

  @override
  Matrix4? performTransform(Size childSize, double leavingProgress) {
    final angle = _maxAngle * leavingProgress;
    final rotation = angle * (anchorSide == SpinnerAnchorSide.left ? -1 : 1);

    // TODO(mjk): horizontal scrolling?
    final translation = _calculateTranslation(
      Size(
        childSize.width,
        geometry!.paintExtent,
      ),
    );

    return Matrix4.identity()
      ..translate(translation.dx, translation.dy)
      ..rotateZ(rotation)
      ..translate(-translation.dx, -translation.dy);
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
