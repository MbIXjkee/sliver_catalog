import 'package:flutter/material.dart';
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
  });
}
