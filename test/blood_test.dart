import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliver_catalog/sliver_catalog.dart';
import 'package:sliver_catalog/src/utils/shader_storage.dart';

void main() {
  group('BloodSliver', () {
    testWidgets('applies shader when it is loaded', (tester) async {
      final programLoading =
          ui.FragmentProgram.fromAsset('assets/shaders/template.frag');

      ShaderStorage.instance.setProgramForTest(
        SupportedShaders.blood,
        programLoading,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomScrollView(
            slivers: [
              BloodSliver(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      );

      await programLoading;
      await tester.pump(const Duration(seconds: 1));

      final sliverFinder = find.byType(LeavingViewportShaderSliver);
      expect(sliverFinder, findsOneWidget);
      final sliverWidget =
          tester.widget<LeavingViewportShaderSliver>(sliverFinder);
      expect(sliverWidget.shader, isNotNull);
    });

    testWidgets(
      'should work without crashing if shader fails to load',
      (tester) async {
        final failingFuture = Future<ui.FragmentProgram>.error(Exception(test))
          ..ignore();

        ShaderStorage.instance.setProgramForTest(
          SupportedShaders.blood,
          failingFuture,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: CustomScrollView(
              slivers: [
                BloodSliver(
                  child: SizedBox(
                    height: 100,
                  ),
                ),
              ],
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        final sliverFinder = find.byType(LeavingViewportShaderSliver);
        expect(sliverFinder, findsOneWidget);
        final sliverWidget =
            tester.widget<LeavingViewportShaderSliver>(sliverFinder);
        expect(sliverWidget.shader, isNull);
      },
    );
  });
}
