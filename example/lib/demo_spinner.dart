import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';
import 'package:sliver_catalog_example/common/content_example.dart';
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
      home: const DemoSpinnerScreen(),
    );
  }
}

class DemoSpinnerScreen extends StatelessWidget {
  const DemoSpinnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        reverse: true,
        slivers: urls
            .mapIndexed(
              (url, index) => SpinnerSliver(
                anchorSide: index.isOdd
                    ? SpinnerAnchorSide.left
                    : SpinnerAnchorSide.right,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ContentExample(url: url),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
