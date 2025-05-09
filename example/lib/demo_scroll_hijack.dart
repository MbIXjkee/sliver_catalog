import 'package:flutter/material.dart';
import 'package:sliver_catalog/sliver_catalog.dart';

/// An example of using ScrollHijackSliver to concsume more space than it
/// actually takes up.
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
        slivers: [
          ScrollHijackSliver(
            consumingSpaceSize: 800,
            builder: (context, consumingProgress) {
              return Container(
                color: Colors.blue,
                height: 200,
                child: Center(
                  child: ValueListenableBuilder(
                    valueListenable: consumingProgress,
                    builder: (context, value, child) {
                      return Text(
                        'Consuming progress: ${value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
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
    );
  }
}
