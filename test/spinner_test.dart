// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_catalog/src/spinner.dart';

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
        final widget = SizedBox(
          child: SpinnerSliver(
            child: Container(),
          ),
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

    group('performTransform should contain correct rotation', () {
      final testCases = [
        // === VERTICAL, LEFT ANCHOR ===
        // there is no transformation, we didn't start to rotate
        (
          description:
              'Vertical forward, left anchor, scrollOffset 0, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 0.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: null,
        ),
        // there is no transformation, the content is fully out the screen
        (
          description:
              'Vertical forward, left anchor, scrollOffset 100, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 100.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: null,
        ),
        (
          description:
              'Vertical forward, left anchor, scrollOffset 99.9, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 99.9,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: -1.568,
        ),
        (
          description:
              'Vertical forward, left anchor, scrollOffset 50, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: -0.785,
        ),
        (
          description: 'Vertical forward, left anchor, scrollOffset 50, from 1',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.0,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: -0.5,
        ),
        // === VERTICAL, RIGHT ANCHOR ===
        // No transformation: content just entered the viewport
        (
          description:
              'Vertical forward, right anchor, scrollOffset 0, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 0.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: null,
        ),
        // No transformation: content fully left the viewport
        (
          description:
              'Vertical forward, right anchor, scrollOffset 100, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 100.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: null,
        ),
        (
          description:
              'Vertical forward, right anchor, scrollOffset 99.9, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 99.9,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: 1.568,
        ),
        (
          description:
              'Vertical forward, right anchor, scrollOffset 50, from pi/2',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: 0.785,
        ),
        (
          description:
              'Vertical forward, right anchor, scrollOffset 50, from 1',
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.right,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.0,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(height: 100.0),
          expectedRotation: 0.5,
        ),
        // === HORIZONTAL, RIGHT ANCHOR ===
        // No transformation: just entering
        (
          description:
              'Horizontal forward, right anchor, scrollOffset 0, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 0.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: null,
        ),
        // No transformation: fully out
        (
          description:
              'Horizontal forward, right anchor, scrollOffset 100, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 100.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: null,
        ),
        (
          description:
              'Horizontal forward, right anchor, scrollOffset 99.9, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 99.9,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: 1.568,
        ),
        (
          description:
              'Horizontal forward, right anchor, scrollOffset 50, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.57,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: 0.785,
        ),
        (
          description:
              'Horizontal forward, right anchor, scrollOffset 50, from 1',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.right,
          maxAngle: 1.0,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: 0.5,
        ),
        // === HORIZONTAL, LEFT ANCHOR ===
        // No transformation: just entering
        (
          description:
              'Horizontal forward, left anchor, scrollOffset 0, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 0.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: null,
        ),
        // No transformation: fully out
        (
          description:
              'Horizontal forward, left anchor, scrollOffset 100, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 100.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: null,
        ),
        (
          description:
              'Horizontal forward, left anchor, scrollOffset 99.9, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 99.9,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: -1.568,
        ),
        (
          description:
              'Horizontal forward, left anchor, scrollOffset 50, from pi/2',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.57,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: -0.785,
        ),
        (
          description:
              'Horizontal forward, left anchor, scrollOffset 50, from 1',
          axisDirection: AxisDirection.right,
          growthDirection: GrowthDirection.forward,
          crossAxisDirection: AxisDirection.down,
          anchorSide: SpinnerAnchorSide.left,
          maxAngle: 1.0,
          scrollOffset: 50.0,
          childConstraints: const BoxConstraints.tightFor(width: 100.0),
          expectedRotation: -0.5,
        ),
      ];

      for (final testCase in testCases) {
        final (
          :description,
          :axisDirection,
          :growthDirection,
          :crossAxisDirection,
          :anchorSide,
          :maxAngle,
          :scrollOffset,
          :childConstraints,
          :expectedRotation
        ) = testCase;

        test(description, () {
          final constraints = SliverConstraints(
            axisDirection: axisDirection,
            growthDirection: growthDirection,
            userScrollDirection: ScrollDirection.idle,
            scrollOffset: scrollOffset,
            precedingScrollExtent: 0.0,
            overlap: 0.0,
            remainingPaintExtent: 600.0,
            crossAxisExtent: 300.0,
            crossAxisDirection: crossAxisDirection,
            viewportMainAxisExtent: 600.0,
            remainingCacheExtent: 850.0,
            cacheOrigin: clampDouble(-scrollOffset, 0, 250),
          );
          final sliver = SpinnerRenderSliver(
            anchorSide: anchorSide,
            maxAngle: maxAngle,
          );
          final child = RenderConstrainedBox(
            additionalConstraints: childConstraints,
          )..parentData = SliverPhysicalParentData();

          sliver
            ..child = child
            ..layout(constraints);

          final paintTransform = sliver.paintTransform;
          if (expectedRotation == null) {
            expect(paintTransform, isNull);
          } else {
            expect(paintTransform, isNotNull);
            expect(paintTransform, isA<Matrix4>());
            expect(
              _getActualRotationByMatrix(paintTransform!),
              closeTo(expectedRotation, 0.001),
            );
          }
        });
      }
    });

    group('performSpecificHitTestChildren', () {
      test('should not override hit testing for direct scrolling', () {
        const constraints = SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0,
          precedingScrollExtent: 0,
          overlap: 0,
          remainingPaintExtent: 100,
          crossAxisExtent: 100,
          crossAxisDirection: AxisDirection.left,
          viewportMainAxisExtent: 100,
          remainingCacheExtent: 100,
          cacheOrigin: 0,
        );
        sliver.layout(constraints);

        final result = sliver.performSpecificHitTestChildren(
          SliverHitTestResult(),
          mainAxisPosition: 10,
          crossAxisPosition: 10,
        );

        expect(result, isNull);
      });

      group('should pass decision over to the child', () {
        const testCases = [
          (
            childAnswer: true,
            expectation: isTrue,
          ),
          (
            childAnswer: false,
            expectation: isFalse,
          ),
        ];

        for (final testCase in testCases) {
          final (:childAnswer, :expectation) = testCase;

          test(
            'case: $childAnswer',
            () {
              const constraints = SliverConstraints(
                axisDirection: AxisDirection.down,
                growthDirection: GrowthDirection.reverse,
                userScrollDirection: ScrollDirection.idle,
                scrollOffset: 0.0,
                precedingScrollExtent: 0.0,
                overlap: 0.0,
                remainingPaintExtent: 600.0,
                crossAxisExtent: 300.0,
                crossAxisDirection: AxisDirection.right,
                viewportMainAxisExtent: 600.0,
                remainingCacheExtent: 850.0,
                cacheOrigin: 0,
              );
              final hitTestBox = _HitTestBox()..testHitTest = childAnswer;
              sliver
                ..child = hitTestBox
                ..layout(constraints);

              final result = sliver.performSpecificHitTestChildren(
                SliverHitTestResult(),
                mainAxisPosition: 10,
                crossAxisPosition: 10,
              );
              expect(result, expectation);
            },
          );
        }
      });

      test(
        'should correctly adjust hit point before passing to the child (vertical)',
        () {
          const constraints = SliverConstraints(
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.reverse,
            userScrollDirection: ScrollDirection.idle,
            scrollOffset: 0.0,
            precedingScrollExtent: 0.0,
            overlap: 0.0,
            remainingPaintExtent: 600.0,
            crossAxisExtent: 300.0,
            crossAxisDirection: AxisDirection.right,
            viewportMainAxisExtent: 600.0,
            remainingCacheExtent: 850.0,
            cacheOrigin: 0,
          );
          final hitTestBox = _HitTestBox();
          sliver
            ..child = hitTestBox
            ..layout(constraints)
            ..performSpecificHitTestChildren(
              SliverHitTestResult(),
              mainAxisPosition: 10,
              crossAxisPosition: 10,
            );

          expect(
            hitTestBox.triedPosition,
            const Offset(10, 590),
          );
        },
      );

      test(
        'should correctly adjust hit point before passing to the child (horizontal)',
        () {
          const constraints = SliverConstraints(
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.reverse,
            userScrollDirection: ScrollDirection.idle,
            scrollOffset: 0.0,
            precedingScrollExtent: 0.0,
            overlap: 0.0,
            remainingPaintExtent: 600.0,
            crossAxisExtent: 300.0,
            crossAxisDirection: AxisDirection.down,
            viewportMainAxisExtent: 600.0,
            remainingCacheExtent: 850.0,
            cacheOrigin: 0,
          );
          final hitTestBox = _HitTestBox();
          sliver
            ..child = hitTestBox
            ..layout(constraints)
            ..performSpecificHitTestChildren(
              SliverHitTestResult(),
              mainAxisPosition: 10,
              crossAxisPosition: 10,
            );

          expect(
            hitTestBox.triedPosition,
            const Offset(590, 10),
          );
        },
      );
    });
  });
}

class _HitTestBox extends RenderBox {
  bool _hittestResult = false;
  Offset? triedPosition;

  // ignore: avoid_setters_without_getters
  set testHitTest(bool value) {
    _hittestResult = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    triedPosition = position;
    return _hittestResult;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
  }
}

double _getActualRotationByMatrix(Matrix4 matrix) {
  final a = matrix.entry(0, 0);
  final b = matrix.entry(1, 0);

  return math.atan2(b, a);
}
