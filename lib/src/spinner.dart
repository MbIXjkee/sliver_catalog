import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sliver_catalog/src/base/leaving_viewport_transform_render_sliver.dart';

const double _kQuarterTurnsInRadians = math.pi / 2.0;

/// The sliver widget that rotates around one of the latest side corners
/// while moving out from the screen.
///
/// When the last part of this widget leaves the screen, it is rotated to
/// [maxAngle] radians around the anchor point.
/// Before this moment, rotation is proportional to the part of the widget that
/// has already left the screen.
///
/// See also:
/// [SingleChildRenderObjectWidget] a base class implements a transform applied
/// to the child based on the progress of the leaving.
class SpinnerSliver extends SingleChildRenderObjectWidget {
  /// The side of the rotation point.
  /// For the vertical scrolling, it means literally left or right side,
  /// unrelated to the scroll growth direction.
  /// For the horizontal scrolling, it means the top or bottom side,
  /// depending on the reverseness of the scroll direction.
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

final class SpinnerRenderSliver extends LeavingViewportTransformedRenderSliver {
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
      ..rotateZ(_calculateRotation(angle))
      ..translate(-translation.dx, -translation.dy);
  }

  @override
  bool performSpecificHitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    assert(geometry!.hitTestExtent > 0.0);
    if (child != null) {
      // Since we deal with the rotation, the default inverse doesn't work as
      // expected for reversed scrolling.
      // Rotation is based on the top left corner by default, which is match
      // with 0:0 in direct case. But for reverse case, the 0:0 point is
      // left bottom corner, and main and cross axis position is calculated
      // from that point. Rotation is still based on the top left cornerr.
      // To calculate hit test correctly we'll covert the main axis position
      // to be calculated from the top left corner always.
      final correctedMainOffset = _isReversed
          ? geometry!.paintExtent - mainAxisPosition
          : mainAxisPosition;

      return BoxHitTestResult.wrap(result).addWithPaintTransform(
        transform: paintTransform,
        position: Offset(crossAxisPosition, correctedMainOffset),
        hitTest: (result, position) {
          return child!.hitTest(result, position: position);
        },
      );
    }
    return false;
  }

  Offset _calculateTranslation(Size size) {
    late final FractionalOffset offset;
    if (constraints.axis == Axis.horizontal) {
      if (_isReversed) {
        offset = _anchorSide == SpinnerAnchorSide.left
            ? FractionalOffset.topLeft
            : FractionalOffset.bottomLeft;
      } else {
        offset = _anchorSide == SpinnerAnchorSide.left
            ? FractionalOffset.bottomRight
            : FractionalOffset.topRight;
      }
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

  double _calculateRotation(double angle) {
    final int sideMultiplicator;
    final int directionMultiplicator;

    if (constraints.axis == Axis.horizontal) {
      sideMultiplicator = anchorSide == SpinnerAnchorSide.left ? -1 : 1;
      directionMultiplicator = 1;
    } else {
      sideMultiplicator = anchorSide == SpinnerAnchorSide.left ? -1 : 1;
      directionMultiplicator = _isReversed ? -1 : 1;
    }

    return sideMultiplicator * directionMultiplicator * angle;
  }
}

/// Defines the side of the anchor relative the main axis of the viewport.
enum SpinnerAnchorSide {
  /// Anchor at the left side.
  left,

  /// Anchor at the right side.
  right,
}
