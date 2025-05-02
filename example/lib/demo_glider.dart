import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';
import 'package:sliver_catalog_example/common/image_urls.dart';
import 'package:sliver_catalog_example/common/indexed_iterable.dart';

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
      home: const DemoGliderScreen(),
    );
  }
}

class DemoGliderScreen extends StatelessWidget {
  const DemoGliderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: urls
            .mapIndexed(
              (url, index) => GliderSliver(
                exitSide:
                    index.isOdd ? GliderExitSide.left : GliderExitSide.right,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        height: 300,
                        width: double.infinity,
                      ),
                      Positioned.fill(
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Click Me'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
