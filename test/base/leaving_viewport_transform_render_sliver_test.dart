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
