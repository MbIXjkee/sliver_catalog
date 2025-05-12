import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

void main() {
  group('LeavingViewportShaderSliver tests', () {
    late final ui.FragmentShader shader;
    late _MockLeavingViewportShader mockShader;
    late ScrollController controller;
    late bool buttonPressed;

    setUpAll(() async {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/template.frag',
      );
      shader = program.fragmentShader();

      registerFallbackValue(Size.zero);
      registerFallbackValue(Offset.zero);
    });

    setUp(() {
      buttonPressed = false;
      controller = ScrollController();
      mockShader = _MockLeavingViewportShader();
      when(() => mockShader.shader).thenReturn(shader);
    });

    tearDown(() {
      controller.dispose();
    });

    tearDownAll(() {
      shader.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              LeavingViewportShaderSliver(
                shader: mockShader,
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        buttonPressed = true;
                      },
                      child: const Text('Test Button'),
                    ),
                  ),
                ),
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

    testWidgets(
      'should not throw an error when the shader is not set',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                controller: controller,
                slivers: [
                  LeavingViewportShaderSliver(
                    shader: null,
                    child: Container(height: 200, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        );

        final dynamic exception = tester.takeException();
        expect(exception, isNull);

        expect(find.byType(LeavingViewportShaderSliver), findsOneWidget);
      },
    );

    group('shader apply', () {
      testWidgets(
        'shader is not applied when there is no offset',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          verifyNever(() => mockShader.shader);
          verifyNever(
            () => mockShader.tuneValue(
              childSize: any(named: 'childSize'),
              paintOffset: any(named: 'paintOffset'),
              progress: any(named: 'progress'),
            ),
          );
        },
      );

      testWidgets(
        'shader is applied when there is an offset',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          controller.jumpTo(100);
          await tester.pumpAndSettle();

          verify(() => mockShader.shader).called(1);
          verify(
            () => mockShader.tuneValue(
              childSize: any(named: 'childSize'),
              paintOffset: const Offset(0, -100),
              progress: 0.5,
            ),
          ).called(1);
        },
      );

      testWidgets(
        'shader is not applied when the child is not visible',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          controller.jumpTo(200);
          await tester.pumpAndSettle();

          verifyNever(() => mockShader.shader);
          verifyNever(
            () => mockShader.tuneValue(
              childSize: any(named: 'childSize'),
              paintOffset: any(named: 'paintOffset'),
              progress: any(named: 'progress'),
            ),
          );
        },
      );
    });

    group('hit test', () {
      testWidgets(
        'should find target correctly',
        (tester) async {
          await tester.pumpWidget(createTestWidget());

          controller.jumpTo(100);
          await tester.pumpAndSettle();

          final screenWidth = tester.getSize(find.byType(MaterialApp)).width;
          await tester.tapAt(
            Offset(
              screenWidth / 2,
              0,
            ),
          );
          await tester.pump();

          expect(buttonPressed, isTrue);
        },
      );
    });
  });
}

class _MockLeavingViewportShader extends Mock
    implements LeavingViewportShader {}
