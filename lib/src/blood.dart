import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';
import 'package:sliver_catalog/src/utils/shader_storage.dart';

/// A widget that applies a blood covering effect to the content of a sliver
/// using a predefined shader effect.
///
/// See also:
/// [LeavingViewportShaderSliver] a base for this sliver, that applies a passed
/// shader to the child during the leaving of the visual part of the viewport.
class BloodSliver extends StatefulWidget {
  final Widget child;

  const BloodSliver({
    super.key,
    required this.child,
  });

  @override
  State<BloodSliver> createState() => _BloodSliverState();
}

class _BloodSliverState extends State<BloodSliver> {
  late final Future<DefaultLeavingViewportShader?> _shaderFuture;

  @override
  void initState() {
    super.initState();

    // False alarm - we just init a future for future builder.
    // ignore: discarded_futures
    _shaderFuture = _initShader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DefaultLeavingViewportShader?>(
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

  Future<DefaultLeavingViewportShader?> _initShader() async {
    try {
      final shader = await ShaderStorage.instance.getShader(
        SupportedShaders.blood,
      );

      return DefaultLeavingViewportShader(shader: shader);

      // Any problem but not specific leads to failure using the shader.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('Failed to init blood shader: $e');
      return null;
    }
  }
}
