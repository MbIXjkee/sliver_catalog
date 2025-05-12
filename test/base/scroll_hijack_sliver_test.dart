// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_catalog/src/base/scroll_hijack_sliver.dart';

void main() {
  group(
    'ScrollHijackSliver tests:',
    () {
      const contentKey = Key('contetn');
      late ScrollController controller;

      setUp(() {
        controller = ScrollController();
      });

      tearDown(() {
        controller.dispose();
      });

      Widget createTestWidget([
        ScrollHijackProgressBehavior behavior =
            ScrollHijackProgressBehavior.onlyConsumingSpace,
      ]) {
        return MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                ScrollHijackSliver(
                  consumingSpaceSize: 200.0,
                  progressBehavior: behavior,
                  builder: (context, progress) {
                    return SizedBox(
                      key: contentKey,
                      height: 300,
                      child: Center(
                        child: ValueListenableBuilder<double>(
                          valueListenable: progress,
                          builder: (context, value, _) {
                            return Text(
                              value.toStringAsFixed(2),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                for (int i = 0; i < 10; i++)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      Future<void> scrollTo(double position, WidgetTester tester) async {
        controller.jumpTo(position);
        await tester.pumpAndSettle();
      }

      testWidgets(
        'should not generate unnecessary frames',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          // This is quite a primitive way to test it, but does work.
          // Should not throw timeout when nothing happen.
          await tester.pumpAndSettle();
        },
      );

      group(
        'calculation progress for ScrollHijackProgressBehavior.onlyConsumingSpace:',
        () {
          testWidgets(
            'Initial consumingProgress is zero',
            (tester) async {
              await tester.pumpWidget(createTestWidget());

              expect(find.text('0.00'), findsOneWidget);
            },
          );

          group(
            'consumingProgress updates proportionally while consuming space',
            () {
              final testCases = [
                (scrollOffset: 0.0, expectedProgress: '0.00'),
                (scrollOffset: 25.0, expectedProgress: '0.13'),
                (scrollOffset: 50.0, expectedProgress: '0.25'),
                (scrollOffset: 75.0, expectedProgress: '0.38'),
                (scrollOffset: 100.0, expectedProgress: '0.50'),
                (scrollOffset: 150.0, expectedProgress: '0.75'),
                (scrollOffset: 200.0, expectedProgress: '1.00'),
                (scrollOffset: 300.0, expectedProgress: '1.00'),
              ];

              for (final testCase in testCases) {
                final (:scrollOffset, :expectedProgress) = testCase;

                testWidgets(
                  'shows $expectedProgress for scrollOffset=$scrollOffset',
                  (tester) async {
                    await tester.pumpWidget(createTestWidget());
                    await scrollTo(scrollOffset, tester);
                    expect(find.text(expectedProgress), findsOneWidget);
                  },
                );
              }
            },
          );

          testWidgets(
            'consumingProgress caps at 1.0 once consuming space is exceeded',
            (tester) async {
              await tester.pumpWidget(createTestWidget());

              await scrollTo(300, tester);

              expect(find.text('1.00'), findsOneWidget);
            },
          );
        },
      );

      group(
        'calculation progress for ScrollHijackProgressBehavior.consumingSpaceAndMoving:',
        () {
          testWidgets(
            'Initial consumingProgress is zero',
            (tester) async {
              await tester.pumpWidget(
                createTestWidget(
                  ScrollHijackProgressBehavior.consumingSpaceAndMoving,
                ),
              );

              expect(find.text('0.00'), findsOneWidget);
            },
          );

          group(
            'consumingProgress updates proportionally for consumingSpaceAndMoving',
            () {
              final testCases = [
                (scrollOffset: 0.0, expectedProgress: '0.00'),
                (scrollOffset: 50.0, expectedProgress: '0.10'),
                (scrollOffset: 100.0, expectedProgress: '0.20'),
                (scrollOffset: 150.0, expectedProgress: '0.30'),
                (scrollOffset: 200.0, expectedProgress: '0.40'),
                (scrollOffset: 250.0, expectedProgress: '0.50'),
                (scrollOffset: 400.0, expectedProgress: '0.80'),
                (scrollOffset: 500.0, expectedProgress: '1.00'),
                (scrollOffset: 600.0, expectedProgress: '1.00'),
              ];

              for (final testCase in testCases) {
                final (:scrollOffset, :expectedProgress) = testCase;

                testWidgets(
                  'shows $expectedProgress for scrollOffset=$scrollOffset',
                  (tester) async {
                    await tester.pumpWidget(
                      createTestWidget(
                        ScrollHijackProgressBehavior.consumingSpaceAndMoving,
                      ),
                    );
                    await scrollTo(scrollOffset, tester);
                    expect(
                      find.text(expectedProgress, skipOffstage: false),
                      findsOneWidget,
                    );
                  },
                );
              }
            },
          );

          testWidgets(
            'consumingProgress continues to increase as child scrolls out',
            (tester) async {
              await tester.pumpWidget(
                createTestWidget(
                  ScrollHijackProgressBehavior.consumingSpaceAndMoving,
                ),
              );

              await scrollTo(350, tester);

              expect(find.text('0.70'), findsOneWidget);

              await scrollTo(500, tester);

              expect(find.text('1.00', skipOffstage: false), findsOneWidget);
            },
          );

          testWidgets(
            'consumingProgress caps at 1.0 after all scrolled out',
            (tester) async {
              await tester.pumpWidget(
                createTestWidget(
                  ScrollHijackProgressBehavior.consumingSpaceAndMoving,
                ),
              );

              await scrollTo(600, tester);

              expect(find.text('1.00', skipOffstage: false), findsOneWidget);
            },
          );
        },
      );

      testWidgets(
        'Child content remains visible and moves after consuming phase correctly',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          // Before scrolling, child at top
          expect(
            tester.getTopLeft(find.byKey(contentKey)).dy,
            equals(0.0),
          );

          await scrollTo(200, tester);

          expect(
            tester.getTopLeft(find.byKey(contentKey)).dy,
            equals(0.0),
          );

          await scrollTo(250, tester);

          expect(
            tester.getTopLeft(find.byKey(contentKey)).dy,
            closeTo(-50.0, 0.0),
          );
        },
      );

      group(
        'initial scroll offset should be handled correctly in progress calculation',
        () {
          final testCases = [
            (
              behavior: ScrollHijackProgressBehavior.onlyConsumingSpace,
              offset: 0.0,
              progress: '0.00'
            ),
            (
              behavior: ScrollHijackProgressBehavior.onlyConsumingSpace,
              offset: 50.0,
              progress: '0.25'
            ),
            (
              behavior: ScrollHijackProgressBehavior.onlyConsumingSpace,
              offset: 100.0,
              progress: '0.50'
            ),
            (
              behavior: ScrollHijackProgressBehavior.onlyConsumingSpace,
              offset: 150.0,
              progress: '0.75'
            ),
            (
              behavior: ScrollHijackProgressBehavior.onlyConsumingSpace,
              offset: 200.0,
              progress: '1.00'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 0.0,
              progress: '0.00'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 50.0,
              progress: '0.10'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 100.0,
              progress: '0.20'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 200.0,
              progress: '0.40'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 250.0,
              progress: '0.50'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 400.0,
              progress: '0.80'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 500.0,
              progress: '1.00'
            ),
            (
              behavior: ScrollHijackProgressBehavior.consumingSpaceAndMoving,
              offset: 600.0,
              progress: '1.00'
            ),
          ];

          for (final testCase in testCases) {
            final (:behavior, :offset, :progress) = testCase;

            testWidgets(
              '$behavior with offset=$offset',
              (tester) async {
                // Need to recreate controller.
                controller.dispose();
                controller = ScrollController(initialScrollOffset: offset);
                await tester.pumpWidget(createTestWidget(behavior));
                await tester.pumpAndSettle();

                expect(
                  find.text(progress, skipOffstage: false),
                  findsOneWidget,
                );
              },
            );
          }
        },
      );
    },
  );
}
