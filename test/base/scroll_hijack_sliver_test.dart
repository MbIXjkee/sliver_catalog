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

      Widget createTestWidget() {
        return MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                ScrollHijackSliver(
                  consumingSpaceSize: 200.0,
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
        // first time for handling position by render.
        await tester.pump();
        // second time for updating the UI next frame.
        await tester.pump();
      }

      testWidgets(
        'Initial consumingProgress is zero',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          await tester.pump(const Duration(milliseconds: 50));

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

          expect(tester.getTopLeft(find.byKey(contentKey)).dy,
              closeTo(-50.0, 0.0));
        },
      );
    },
  );
}
