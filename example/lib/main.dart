import 'package:flutter/material.dart';
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
      home: const DemoScreen(),
    );
  }
}

/// Screen for demonstration sliver.
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
