import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollHijackSliver extends StatefulWidget {
  final double consumingSpaceSize;
  final Widget Function(
    BuildContext context,
    ValueListenable<double> consumingProgress,
  ) builder;

  const ScrollHijackSliver({
    super.key,
    required this.consumingSpaceSize,
    required this.builder,
  });

  @override
  State<ScrollHijackSliver> createState() => _ScrollHijackSliverState();
}

class _ScrollHijackSliverState extends State<ScrollHijackSliver> {
  final ValueNotifier<double> _consumingProgress = ValueNotifier(0.0);

  @override
  void dispose() {
    _consumingProgress.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HijackSliver(
      consumingSpaceSize: widget.consumingSpaceSize,
      child: widget.builder(
        context,
        _consumingProgress,
      ),
    );
  }
}

class _HijackSliver extends SingleChildRenderObjectWidget {
  final double consumingSpaceSize;

  const _HijackSliver({
    required this.consumingSpaceSize,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _HijackRenderSliver();
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _HijackRenderSliver renderObject,
  ) {}
}

class _HijackRenderSliver extends RenderSliverSingleBoxAdapter {
  @override
  void performLayout() {
    
  }
}
