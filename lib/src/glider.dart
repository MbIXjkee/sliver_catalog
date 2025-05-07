import 'package:flutter/material.dart';
import 'package:sliver_catalog/src/base/leaving_viewport_transform_render_sliver.dart';

/// The sliver widget that slides left or right while moving out
/// from the screen.
/// 
/// See also:
/// [SingleChildRenderObjectWidget] a base class implements a transform applied
/// to the child based on the progress of the leaving.
class GliderSliver extends SingleChildRenderObjectWidget {
  /// The side to which the widget is moving out relative to the main axis of
  /// the viewport.
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

final class GliderRenderSliver extends LeavingViewportTransformedRenderSliver {
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

    final shifting = childCrossExtent * leavingProgress;
    final translation = shifting * (exitSide == GliderExitSide.left ? -1 : 1);

    if (constraints.axis == Axis.horizontal) {
      return Matrix4.identity()..translate(.0, -translation);
    }

    return Matrix4.identity()..translate(translation);
  }
}

/// Describes possible values for the side to which the content is moving out
/// relative to the main axis of the viewport.
enum GliderExitSide {
  /// From the right to the left.
  left,

  /// From the left to the right.
  right,
}
