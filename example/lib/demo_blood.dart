import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';
import 'package:sliver_catalog_example/common/image_urls.dart';
import 'package:sliver_catalog_example/common/content_example.dart';

/// An example of using the BloodSliver widget to create a blood effect
/// on the content.
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
      home: const DemoFreezeScreen(),
    );
  }
}

class DemoFreezeScreen extends StatefulWidget {
  const DemoFreezeScreen({super.key});

  @override
  State<DemoFreezeScreen> createState() => _DemoFreezeScreenState();
}

class _DemoFreezeScreenState extends State<DemoFreezeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: urls
            .map(
              (url) => BloodSliver(
                child: ContentExample(
                  url: url,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
