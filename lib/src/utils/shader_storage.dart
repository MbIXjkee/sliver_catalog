import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Enumerates predefined shaders supported by the package.
enum SupportedShaders {
  blood('packages/sliver_catalog/assets/shaders/blood.frag'),
  freezing('packages/sliver_catalog/assets/shaders/freezing.frag');

  final String path;

  const SupportedShaders(this.path);
}

/// A utility class to manage and load predefined shaders from assets.
class ShaderStorage {
  static final ShaderStorage _instance = ShaderStorage._internal();

  final _register = <SupportedShaders, FutureOr<ui.FragmentProgram>>{};

  /// Return single instance of [ShaderStorage].
  static ShaderStorage get instance => _instance;

  /// Return single instance of [ShaderStorage].
  factory ShaderStorage() => _instance;

  ShaderStorage._internal();

  /// Returns a requested shader.
  Future<ui.FragmentShader> getShader(SupportedShaders shader) async {
    final loadingProgram = _register[shader];
    if (loadingProgram != null) {
      final program = switch (loadingProgram) {
        final Future<ui.FragmentProgram> future => await future,
        final ui.FragmentProgram fp => fp,
      };

      return program.fragmentShader();
    } else {
      final programLoading = ui.FragmentProgram.fromAsset(shader.path);
      _register[shader] = programLoading;

      final fp = await programLoading;
      _register[shader] = fp;

      return fp.fragmentShader();
    }
  }

  @visibleForTesting
  void setProgramForTest(
    SupportedShaders key,
    FutureOr<ui.FragmentProgram> program,
  ) {
    _register[key] = program;
  }
}
