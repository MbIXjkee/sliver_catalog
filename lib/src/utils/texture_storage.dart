import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:sliver_catalog/src/utils/freeze_texture.dart';

/// A utility class to manage and load textures.
/// Localy caches the textures for prevent mass decoding the same image.
class TextureStorage {
  static final TextureStorage _instance = TextureStorage._internal();

  final _register = <String, FutureOr<ui.Image>>{};

  /// Return single instance of [TextureStorage].
  static TextureStorage get instance => _instance;

  /// Return single instance of [TextureStorage].
  factory TextureStorage() => _instance;

  TextureStorage._internal();

  /// Returns a texture for freeze effect.
  Future<ui.Image> getFreezeTexture() async {
    const key = 'freeze';
    final loadingTexture = _register[key];

    if (loadingTexture != null) {
      final texture = switch (loadingTexture) {
        final Future<ui.Image> future => await future,
        final ui.Image image => image,
      };

      return texture;
    } else {
      final decodingFuture = decodeImageFromList(freezeTexture);
      _register[key] = decodingFuture;

      final texture = await decodingFuture;
      _register[key] = texture;

      return texture;
    }
  }
}
