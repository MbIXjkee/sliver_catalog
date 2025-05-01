import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

void main() {
  runApp(const MyApp());
}

/// App widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DemoShaderScreen(shaderName: 'freezing3'),
      // home: const DemoSpinnerScreen(),
      // home: const DemoGliderScreen(),
    );
  }
}

/// Screen for demonstration spinner.
class DemoSpinnerScreen extends StatelessWidget {
  const DemoSpinnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        reverse: true,
        slivers: _urls
            .mapIndexed(
              (url, index) => SpinnerSliver(
                anchorSide: index.isOdd
                    ? SpinnerAnchorSide.left
                    : SpinnerAnchorSide.right,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    height: 300,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Screen for demonstration glider.
class DemoGliderScreen extends StatelessWidget {
  const DemoGliderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: _urls
            .mapIndexed(
              (url, index) => GliderSliver(
                exitSide:
                    index.isOdd ? GliderExitSide.left : GliderExitSide.right,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    height: 300,
                  ),
                ),
              ),
            )
            .toList(),
      ),
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
  /// Init shader.
  late final Future<ui.FragmentShader?> _shaderFuture;

  @override
  void initState() {
    super.initState();

    _shaderFuture =
        ui.FragmentProgram.fromAsset('assets/shaders/${widget.shaderName}.frag')
            .then<ui.FragmentShader?>((program) {
      return program.fragmentShader();
    }, onError: (e, __) {
      debugPrint('Failed frag shader: $e');
      return null;
    }).then((shader) async {
      if (shader != null) {
        final byteData = await rootBundle.load('assets/textures/texture.png');
        final list = Uint8List.view(byteData.buffer);
        final image = await decodeImageFromList(list);
        shader.setImageSampler(0, image);
      }

      return shader;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: _urls
            .map(
              (url) => FutureBuilder<ui.FragmentShader?>(
                initialData: null,
                future: _shaderFuture,
                builder: (context, snapshot) {
                  final shader = snapshot.data;

                  if (shader == null) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return LeavingViewportShaderSliver(
                    shader: shader,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      height: 300,
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

const _urls = <String>[
  'https://www.stockvault.net/data/2018/12/30/258501/preview16.jpg',
  'https://www.stockvault.net/data/2010/10/01/115175/preview16.jpg',
  'https://www.stockvault.net/data/2011/04/18/122242/preview16.jpg',
  'https://www.stockvault.net/data/2014/03/26/155336/preview16.jpg',
  'https://www.stockvault.net/data/2018/12/30/258501/preview16.jpg',
  'https://www.stockvault.net/data/2010/10/01/115175/preview16.jpg',
  'https://www.stockvault.net/data/2011/04/18/122242/preview16.jpg',
  'https://www.stockvault.net/data/2014/03/26/155336/preview16.jpg',
  'https://www.stockvault.net/data/2018/12/30/258501/preview16.jpg',
  'https://www.stockvault.net/data/2010/10/01/115175/preview16.jpg',
  'https://www.stockvault.net/data/2011/04/18/122242/preview16.jpg',
  'https://www.stockvault.net/data/2014/03/26/155336/preview16.jpg',
];

extension _IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
