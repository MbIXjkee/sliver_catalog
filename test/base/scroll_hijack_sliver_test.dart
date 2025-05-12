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
        // ignore: lines_longer_than_80_chars
        'calculation progress for ScrollHijackProgressBehavior.onlyConsumingSpace:',
        () {
          testWidgets(
            'Initial consumingProgress is zero',
            (tester) async {
              await tester.pumpWidget(createTestWidget());

              expect(find.text('0.00'), findsOneWidget);
            },
          );

          testWidgets(
            'consumingProgress updates proportionally while consuming space',
            (tester) async {
              await tester.pumpWidget(createTestWidget());

              await scrollTo(100, tester);

              expect(find.text('0.50'), findsOneWidget);

              await scrollTo(200, tester);

              expect(find.text('1.00'), findsOneWidget);
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
        // ignore: lines_longer_than_80_chars
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

          testWidgets(
            'consumingProgress updates proportionally while consuming space',
            (tester) async {
              await tester.pumpWidget(
                createTestWidget(
                  ScrollHijackProgressBehavior.consumingSpaceAndMoving,
                ),
              );

              await scrollTo(100, tester);

              expect(find.text('0.20'), findsOneWidget);

              await scrollTo(200, tester);

              expect(find.text('0.40'), findsOneWidget);
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
        // ignore: lines_longer_than_80_chars
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
    },
  );
}
