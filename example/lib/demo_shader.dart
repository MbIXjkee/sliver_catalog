import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';
import 'package:sliver_catalog_example/common/image_urls.dart';
import 'package:sliver_catalog_example/common/content_example.dart';

/// An example of using the LeavingViewportShaderSliver to apply a custom
/// shader effect to the content.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DemoShaderScreen(shaderName: 'custom'),
    );
  }
}

class DemoShaderScreen extends StatefulWidget {
  final String shaderName;

  const DemoShaderScreen({super.key, required this.shaderName});

  @override
  State<DemoShaderScreen> createState() => _DemoShaderScreenState();
}

class _DemoShaderScreenState extends State<DemoShaderScreen> {
  late final Future<ui.FragmentShader?> _shaderFuture;

  @override
  void initState() {
    super.initState();

    _shaderFuture = _initShader();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: urls
            .map(
              (url) => FutureBuilder<ui.FragmentShader?>(
                initialData: null,
                future: _shaderFuture,
                builder: (context, snapshot) {
                  final shader = snapshot.data;

                  return LeavingViewportShaderSliver.fromFragmentShader(
                    shader: shader,
                    child: ContentExample(
                      url: url,
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Future<ui.FragmentShader?> _initShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/${widget.shaderName}.frag',
      );
      final shader = program.fragmentShader();

      return shader;
    } catch (e) {
      debugPrint('Failed to init shader ${widget.shaderName}: $e');
      return null;
    }
  }
}
