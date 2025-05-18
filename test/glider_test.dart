import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

void main() {
  group('GliderSliver', () {
    testWidgets(
      'Use glider in scrollable should no exception',
      (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GliderSliver(
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
      'Use glider in no scrollable should throw exception',
      (tester) async {
        final widget = SizedBox(
          child: GliderSliver(
            child: Container(),
          ),
        );

        await tester.pumpWidget(widget);

        expect(tester.takeException(), isInstanceOf<FlutterError>());
      },
    );

    testWidgets(
      'Move glidrt out of screen should not throw exception',
      (tester) async {
        final key = UniqueKey();
        final widget = MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                GliderSliver(
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

    group('GliderRenderSliver', () {
      late GliderRenderSliver sliver;
      late RenderBox child;

      setUp(() {
        child = RenderConstrainedBox(
          additionalConstraints: const BoxConstraints.expand(height: 100),
        )..parentData = SliverPhysicalParentData();

        sliver = GliderRenderSliver()..child = child;
      });

      group('initial properties should be set correctly', () {
        const testCases = [
          GliderExitSide.left,
          GliderExitSide.right,
        ];

        for (final exitSide in testCases) {
          test('exitSide: $exitSide', () {
            final sliver = GliderRenderSliver(exitSide: exitSide);
            expect(sliver.exitSide, exitSide);
          });
        }
      });

      test('exitSide setter triggers layout', () {
        // Меняем свойство — должно пометить layout как нуждающийся в обновлении
        sliver.exitSide = GliderExitSide.right;

        expect(sliver.debugNeedsLayout, isTrue);
      });

      group('performTransform should contain correct translation', () {
        final testCases = [
          // === VERTICAL, LEFT ===
          (
            description: 'Vertical, left exit, scrollOffset 0 → no transform',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.left,
            scrollOffset: 0.0,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Vertical, left exit, scrollOffset 100 → full left',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.left,
            scrollOffset: 100.0,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Vertical, left exit, scrollOffset 50 → half right',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 50.0,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: 150.0, // half of cross axis extent
          ),
          (
            description: 'Vertical, left exit, scrollOffset 33 → third right',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 33.33,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: 99.99, // third of cross axis extent
          ),
          (
            description:
                'Vertical, left exit, scrollOffset 99 → almost gone right',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 99.9999999999,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: 300, // almost left the screen
          ),
          // === VERTICAL, RIGHT ===
          (
            description: 'Vertical, right exit, scrollOffset 0 → no transform',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 0.0,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Vertical, right exit, scrollOffset 100 → fully out',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 100.0,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Vertical, right exit, scrollOffset 50 → half right',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 50.0,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: 150.0, // half of cross axis extent
          ),
          (
            description: 'Vertical, right exit, scrollOffset 33 → third right',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 33.33,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: 99.99, // third of cross axis extent
          ),
          (
            description:
                'Vertical, right exit, scrollOffset 99 → almost gone right',
            axisDirection: AxisDirection.down,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.right,
            exitSide: GliderExitSide.right,
            scrollOffset: 99.9999999999,
            childConstraints: const BoxConstraints.expand(height: 100.0),
            expectedTranslation: 300.0, // almost left the screen
          ),
          // === HORIZONTAL, LEFT ===
          (
            description: 'Horizontal, left exit, scrollOffset 0 → no transform',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.left,
            scrollOffset: 0.0,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Horizontal, left exit, scrollOffset 100 → fully out',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.left,
            scrollOffset: 100.0,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Horizontal, left exit, scrollOffset 50 → half down',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.left,
            scrollOffset: 50.0,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: 150.0, // half of cross axis extent
          ),
          (
            description: 'Horizontal, left exit, scrollOffset 33 → third down',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.left,
            scrollOffset: 33.33,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: 99.99, // third of cross axis extent
          ),
          (
            description:
                'Horizontal, left exit, scrollOffset 99 → almost gone down',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.left,
            scrollOffset: 99.9999999999,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: 300.0, // almost left the screen
          ),
          // === HORIZONTAL, RIGHT EXIT ===
          (
            description:
                'Horizontal, right exit, scrollOffset 0 → no transform',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.right,
            scrollOffset: 0.0,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Horizontal, right exit, scrollOffset 100 → fully out',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.right,
            scrollOffset: 100.0,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: null,
          ),
          (
            description: 'Horizontal, right exit, scrollOffset 50 → half up',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.right,
            scrollOffset: 50.0,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: -150.0, // half of cross axis extent
          ),
          (
            description: 'Horizontal, right exit, scrollOffset 33 → third up',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.right,
            scrollOffset: 33.33,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: -99.99, // third of cross axis extent
          ),
          (
            description:
                'Horizontal, right exit, scrollOffset 99 → almost gone up',
            axisDirection: AxisDirection.right,
            growthDirection: GrowthDirection.forward,
            crossAxisDirection: AxisDirection.down,
            exitSide: GliderExitSide.right,
            scrollOffset: 99.9999999999,
            childConstraints: const BoxConstraints.expand(width: 100.0),
            expectedTranslation: -300.0, // almost left the screen
          ),
        ];

        for (final testCase in testCases) {
          final (
            :description,
            :axisDirection,
            :growthDirection,
            :crossAxisDirection,
            :exitSide,
            :scrollOffset,
            :childConstraints,
            :expectedTranslation
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

            final sliver = GliderRenderSliver(exitSide: exitSide);
            final child = RenderConstrainedBox(
              additionalConstraints: childConstraints,
            )..parentData = SliverPhysicalParentData();

            sliver
              ..child = child
              ..layout(constraints);

            final transform = sliver.paintTransform;

            if (expectedTranslation == null) {
              expect(transform, isNull);
            } else {
              expect(transform, isA<Matrix4>());
              final actualTranslation = axisDirection == AxisDirection.right
                  ? _getTranslateY(transform!)
                  : _getTranslateX(transform!);
              expect(actualTranslation, closeTo(expectedTranslation, 0.001));
            }
          });
        }
      });
    });
  });
}

double _getTranslateX(Matrix4 matrix) => matrix.storage[12];
double _getTranslateY(Matrix4 matrix) => matrix.storage[13];
