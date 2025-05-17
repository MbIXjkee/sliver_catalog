import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

void main() {
  group('SpinnerSliver', () {
    testWidgets(
      'Use spinner in scrollable should no exception',
      (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SpinnerSliver(
                  child: Container(
                    height: 200,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(() => tester.pumpWidget(widget), returnsNormally);
      },
    );

    testWidgets(
      'Use spinner in no scrollable should throw exception',
      (tester) async {
        final widget = SpinnerSliver(
          child: Container(),
        );

        await tester.pumpWidget(widget);

        expect(tester.takeException(), isInstanceOf<FlutterError>());
      },
    );

    testWidgets(
      'Move spinner out of screen should not throw exception',
      (tester) async {
        final key = UniqueKey();
        final widget = MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SpinnerSliver(
                  child: Container(
                    key: key,
                    height: 400,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 1000,
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.drag(find.byKey(key), const Offset(0, 100));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('SpinnerRenderSliver', () {
    late SpinnerRenderSliver sliver;
    late RenderBox child;

    setUp(() {
      child = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.expand(height: 100),
      )..parentData = SliverPhysicalParentData();

      sliver = SpinnerRenderSliver(
        anchorSide: SpinnerAnchorSide.left,
      )..child = child;
    });

    group('initial properties should be set correctly', () {
      const testCases = [
        (anchorSide: SpinnerAnchorSide.left, maxAngle: math.pi / 2),
        (anchorSide: SpinnerAnchorSide.left, maxAngle: math.pi / 3),
        (anchorSide: SpinnerAnchorSide.left, maxAngle: math.pi / 6),
        (anchorSide: SpinnerAnchorSide.right, maxAngle: math.pi / 2),
        (anchorSide: SpinnerAnchorSide.right, maxAngle: math.pi / 3),
        (anchorSide: SpinnerAnchorSide.right, maxAngle: math.pi / 6),
      ];

      for (final testCase in testCases) {
        final (:anchorSide, :maxAngle) = testCase;

        test('anchorSide: $anchorSide, maxAngle: $maxAngle', () {
          final sliver = SpinnerRenderSliver(
            anchorSide: anchorSide,
            maxAngle: maxAngle,
          );

          expect(sliver.anchorSide, anchorSide);
          expect(sliver.maxAngle, closeTo(maxAngle, 0.001));
        });
      }
    });

    test('anchorSide setter triggers layout', () {
      sliver.anchorSide = SpinnerAnchorSide.right;
      final isNeedLayout = sliver.debugNeedsLayout;

      expect(isNeedLayout, isTrue);
    });

    test('maxAngle setter triggers layout', () {
      sliver.maxAngle = 0.5;
      final isNeedLayout = sliver.debugNeedsLayout;

      expect(isNeedLayout, isTrue);
    });

    group('performTransform should return correct result', () {
      final testCases = [
        (scrollOffset: 0.0, expectedTransform: null),
        (scrollOffset: 50.0, expectedTransform: Matrix4.identity()),
      ];

      for (final testCase in testCases) {
        final (:scrollOffset, :expectedTransform) = testCase;

        test('scrollOffset: $scrollOffset', () {
          final constraints = SliverConstraints(
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            userScrollDirection: ScrollDirection.idle,
            scrollOffset: scrollOffset,
            precedingScrollExtent: 0.0,
            overlap: 0.0,
            remainingPaintExtent: 200.0,
            crossAxisExtent: 300.0,
            crossAxisDirection: AxisDirection.right,
            viewportMainAxisExtent: 200.0,
            remainingCacheExtent: 200.0,
            cacheOrigin: 0.0,
          );

          sliver.layout(constraints);

          expect(sliver.paintTransform, expectedTransform);
        });
      }
    });
  });
}
