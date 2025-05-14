// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

void main() {
  group('LeavingViewportTransformedRenderSliver', () {
    late RenderBox child;

    setUp(() {
      child = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tight(const Size(150, 150)),
      )..parentData = SliverPhysicalParentData();
    });

    group('layout', () {
      late _TestLayoutSliver sliver;

      setUp(() {
        sliver = _TestLayoutSliver()..child = child;
      });

      test('layout without scroll offset produces no transform', () {
        const constraints = SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0.0,
          precedingScrollExtent: 0.0,
          overlap: 0.0,
          remainingPaintExtent: 200.0,
          crossAxisExtent: 300.0,
          crossAxisDirection: AxisDirection.right,
          viewportMainAxisExtent: 200.0,
          remainingCacheExtent: 0.0,
          cacheOrigin: 0.0,
        );

        sliver.layout(constraints);

        expect(sliver.paintTransform, isNull);

        expect(sliver.geometry!.paintExtent, equals(150.0));
      });

      test(
        'layout with scroll offset set transformation defined by subclass',
        () {
          const constraints = SliverConstraints(
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            userScrollDirection: ScrollDirection.idle,
            scrollOffset: 50.0,
            precedingScrollExtent: 0.0,
            overlap: 0.0,
            remainingPaintExtent: 200.0,
            crossAxisExtent: 300.0,
            crossAxisDirection: AxisDirection.right,
            viewportMainAxisExtent: 200.0,
            remainingCacheExtent: 0.0,
            cacheOrigin: 0.0,
          );

          sliver.layout(constraints);

          expect(sliver.paintTransform, isNotNull);
          expect(sliver.paintTransform, equals(sliver.lastReturnedTransform));
        },
      );
    });

    group('paint', () {
      late _PaintTestSliver sliver;

      setUp(() {
        sliver = _PaintTestSliver()
          ..child = child
          ..setTestPaintTransform(Matrix4.diagonal3Values(0.5, 0.5, 1.0));
      });

      test('paint applies correct TransformLayer', () {
        final rootLayer = ContainerLayer();
        final context = PaintingContext(
          rootLayer,
          const Rect.fromLTWH(0, 0, 300, 300),
        );

        sliver.paint(context, Offset.zero);

        expect(rootLayer.firstChild, isA<TransformLayer>());
        final transformLayer = rootLayer.firstChild as TransformLayer;
        expect(transformLayer.transform, equals(sliver.paintTransform));
      });
    });

    group('hitTest', () {
      late _HitTestSliver sliver;

      setUp(() {
        sliver = _HitTestSliver()..child = child;
      });

      group('should return value from specific implementation', () {
        const testCases = [
          true,
          false,
        ];
        for (final testValue in testCases) {
          test('case $testValue', () {
            sliver.setTestHit(testValue: testValue);

            final result = SliverHitTestResult();
            final hit = sliver.hitTestChildren(
              result,
              mainAxisPosition: 0.0,
              crossAxisPosition: 0.0,
            );

            expect(hit, equals(testValue));
          });
        }
      });

      test(
        'should delegate adjusted hit point to child if specific implementation is not defined',
        () {
          final hitChild = _HitTestBox();
          sliver
            ..child = hitChild
            ..setTestPaintTransform(Matrix4.diagonal3Values(0.5, 0.5, 1.0))
            ..setTestHit(testValue: null);

          final result = SliverHitTestResult();
          sliver.hitTestChildren(
            result,
            mainAxisPosition: 0.0,
            crossAxisPosition: 0.0,
          );

          expect(hitChild.triedPosition, isNotNull);
        },
      );

      test(
        'should correctly adjust hit test point for vertical orientation',
        () {
          final hitChild = _HitTestBox();
          sliver
            ..child = hitChild
            ..setTestOrientation(isVertical: true)
            ..setTestPaintTransform(Matrix4.diagonal3Values(0.5, 0.5, 1.0))
            ..setTestHit(testValue: null);

          final result = SliverHitTestResult();
          sliver.hitTestChildren(
            result,
            mainAxisPosition: 10.0,
            crossAxisPosition: 15.0,
          );

          final childHit = hitChild.triedPosition;
          expect(childHit, isNotNull);
          expect(childHit!.dx, equals(30.0));
          expect(childHit.dy, equals(20.0));
        },
      );

      test(
        'should correctly adjust hit test point for horizontal orientation',
        () {
          final hitChild = _HitTestBox();
          sliver
            ..child = hitChild
            ..setTestOrientation(isVertical: false)
            ..setTestPaintTransform(Matrix4.diagonal3Values(0.5, 0.5, 1.0))
            ..setTestHit(testValue: null);

          final result = SliverHitTestResult();
          sliver.hitTestChildren(
            result,
            mainAxisPosition: 10.0,
            crossAxisPosition: 15.0,
          );

          final childHit = hitChild.triedPosition;
          expect(childHit, isNotNull);
          expect(childHit!.dx, equals(20.0));
          expect(childHit.dy, equals(30.0));
        },
      );
    });
  });
}

// A dummy implementation of LeavingViewportTransformedRenderSliver.
class _TestLayoutSliver extends LeavingViewportTransformedRenderSliver {
  Matrix4? lastReturnedTransform;

  @override
  Matrix4? performTransform(Size childSize, double leavingProgress) {
    lastReturnedTransform = Matrix4.diagonal3Values(
      leavingProgress,
      leavingProgress,
      1.0,
    );

    return lastReturnedTransform;
  }
}

class _PaintTestSliver extends _TestLayoutSliver {
  @override
  bool get needsCompositing => true;

  @override
  SliverGeometry? get geometry => const SliverGeometry(
        visible: true,
      );
}

class _HitTestSliver extends _TestLayoutSliver {
  static const _verticalConstraints = SliverConstraints(
    axisDirection: AxisDirection.down,
    growthDirection: GrowthDirection.forward,
    userScrollDirection: ScrollDirection.idle,
    scrollOffset: 0.0,
    precedingScrollExtent: 0.0,
    overlap: 0.0,
    remainingPaintExtent: 200.0,
    crossAxisExtent: 300.0,
    crossAxisDirection: AxisDirection.right,
    viewportMainAxisExtent: 200.0,
    remainingCacheExtent: 0.0,
    cacheOrigin: 0.0,
  );
  static const _horizontalConstraints = SliverConstraints(
    axisDirection: AxisDirection.right,
    growthDirection: GrowthDirection.forward,
    userScrollDirection: ScrollDirection.idle,
    scrollOffset: 0.0,
    precedingScrollExtent: 0.0,
    overlap: 0.0,
    remainingPaintExtent: 200.0,
    crossAxisExtent: 300.0,
    crossAxisDirection: AxisDirection.down,
    viewportMainAxisExtent: 200.0,
    remainingCacheExtent: 0.0,
    cacheOrigin: 0.0,
  );

  bool? hasHit;
  bool vertical = true;

  // ignore: use_setters_to_change_properties
  void setTestHit({required bool? testValue}) {
    hasHit = testValue;
  }

  // ignore: use_setters_to_change_properties
  void setTestOrientation({required bool isVertical}) {
    vertical = isVertical;
  }

  @override
  bool? performSpecificHitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    return hasHit;
  }

  @override
  SliverGeometry? get geometry => const SliverGeometry(
        hitTestExtent: 100,
      );

  @override
  SliverConstraints get constraints =>
      vertical ? _verticalConstraints : _horizontalConstraints;
}

class _HitTestBox extends RenderBox {
  Offset? triedPosition;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    triedPosition = position;
    return false;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }
}
