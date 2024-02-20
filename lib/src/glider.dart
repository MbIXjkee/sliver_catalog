import 'package:flutter/material.dart';
import 'package:sliver_catalog/src/base/leaving_transform_render_sliver.dart';

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

final class GliderRenderSliver extends LeavingTransformRenderSliver {
  GliderExitSide _exitSide;

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
  Matrix4? performTransform(Size childSize, double leavingProgress) {
    final double childCrossExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childCrossExtent = childSize.height;
        break;
      case Axis.vertical:
        childCrossExtent = childSize.width;
        break;
    }

    final dx = childCrossExtent * leavingProgress;
    final translation = dx * (exitSide == GliderExitSide.left ? -1 : 1);
    return Matrix4.identity()..translate(translation);
  }
}

/// Describes the side to which widget is moving out.
enum GliderExitSide {
  /// From right to left.
  left,

  /// From left to right.
  right,
}
