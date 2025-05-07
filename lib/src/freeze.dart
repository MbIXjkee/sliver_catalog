import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

/// A widget that freezes the content of a sliver using
/// a predefined in the package shader effect.
/// 
/// See also:
/// [LeavingViewportShaderSliver] a base for this sliver, that applies a passed
/// shader to the child during the leaving of the visual part of the viewport.
class FreezeSliver extends StatefulWidget {
  final Widget child;

  const FreezeSliver({
    super.key,
    required this.child,
  });

  @override
  State<FreezeSliver> createState() => _FreezeSliverState();
}

class _FreezeSliverState extends State<FreezeSliver> {
  late final Future<ui.FragmentShader?> _shaderFuture;

  @override
  void initState() {
    super.initState();

    // False alarm - we just init a future for future builder.
    // ignore: discarded_futures
    _shaderFuture = _initShader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.FragmentShader?>(
      future: _shaderFuture,
      builder: (context, snapshot) {
        final shader = snapshot.data;

        return LeavingViewportShaderSliver(
          shader: shader,
          child: widget.child,
        );
      },
    );
  }

  Future<ui.FragmentShader?> _initShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'assets/shaders/freezing.frag',
      );
      final shader = program.fragmentShader();
      final byteData = await rootBundle.load('assets/textures/texture.png');
      final list = Uint8List.view(byteData.buffer);
      final image = await decodeImageFromList(list);
      shader.setImageSampler(0, image);

      return shader;

      // Any problem but not specific leads to failure using the shader.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('Failed to init freezing shader: $e');
      return null;
    }
  }
}
