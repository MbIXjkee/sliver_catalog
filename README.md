<p align="center">
    <img src="https://i.ibb.co/rhz9j85/Sliver-Catalog.png" alt="Sliver Catalog Logo" height="180">
</p>

<p align="center">
    <a href="https://github.com/MbIXjkee"><img src="https://img.shields.io/badge/Owner-mbixjkee-blueviolet.svg" alt="Owner"></a>
    <a href="https://pub.dev/packages/sliver_catalog"><img src="https://img.shields.io/pub/v/sliver_catalog?logo=dart&logoColor=white" alt="Pub Version"></a>
    <a href="https://pub.dev/packages/sliver_catalog"><img src="https://badgen.net/pub/points/sliver_catalog" alt="Pub points"></a>
    <a href="https://pub.dev/packages/sliver_catalog"><img src="https://badgen.net/pub/likes/sliver_catalog" alt="Pub Likes"></a>
    <a href="https://pub.dev/packages/sliver_catalog"><img src="https://img.shields.io/pub/dm/sliver_catalog" alt="Downloads"></a>
    <a href="https://codecov.io/gh/MbIXjkee/sliver_catalog"><img src="https://codecov.io/gh/MbIXjkee/sliver_catalog/graph/badge.svg?token=H59EM63BS8" alt="Coverage Status"/></a>
    <a href="https://github.com/MbIXjkee/sliver_catalog/graphs/contributors"><img src="https://badgen.net/github/contributors/MbIXjkee/sliver_catalog" alt="Contributors"></a>
    <a href="https://github.com/MbIXjkee/sliver_catalog/blob/main/LICENSE"><img src="https://badgen.net/github/license/MbIXjkee/sliver_catalog" alt="License"></a>
</p>

---

# What this library is

A collection of experimental and creative slivers for Flutter. Extend your scrolling experience beyond the basics.

### Gallery

<p align="center" style="max-width:550px; margin:auto;">
  <img src="https://raw.githubusercontent.com/MbIXjkee/sliver_catalog/refs/heads/image_storage/images/hijack.gif" alt="ScrollHijackSliver demo" width="180">
  <img src="https://raw.githubusercontent.com/MbIXjkee/sliver_catalog/refs/heads/image_storage/images/spinner.gif" alt="SpinnerSliver demo" width="180">
  <img src="https://raw.githubusercontent.com/MbIXjkee/sliver_catalog/refs/heads/image_storage/images/glider.gif" alt="GliderSliver demo" width="180">
  <img src="https://raw.githubusercontent.com/MbIXjkee/sliver_catalog/refs/heads/image_storage/images/freeze.gif" alt="FreezeSliver demo" width="180">
  <img src="https://raw.githubusercontent.com/MbIXjkee/sliver_catalog/refs/heads/image_storage/images/blood.gif" alt="BloodSliver demo" width="180">
</p>

### Demo

<p>
  <a href="https://mbixjkee.github.io/sliver_catalog/release_0.1.3/" target="_blank" rel="noopener">
    <img src="https://img.shields.io/badge/current_release-Demo-blue?style=for-the-badge" alt="Current release" />
  </a>
    <a href="https://mbixjkee.github.io/sliver_catalog/latest/" target="_blank" rel="noopener">
    <img src="https://img.shields.io/badge/Latest-Demo-blue?style=for-the-badge" alt="Latest Demo" />
  </a>
</p>

# Overview

Sliver Catalog provides a set of advanced and experimental slivers for Flutter, enabling developers to create unique, visually engaging scroll effects. The package includes basic slivers as a platform for creating effects and specific implementations that provide ready-to-use effects.

### Basics
- **ScrollHijackSliver**: A sliver that consumes a specified amount of scrollable space before allowing its child to start scrolling.
- **LeavingViewportShaderSliver**: Applies a shader on top of the child while it leaves the viewport.
- **LeavingViewportTransformedRenderSliver**: A render object that applies a transformation to the child while it leaves the viewport.

### Ready-to-use effects
- **SpinnerSliver**: Rotates its child as it leaves the viewport, with configurable anchor and angle.
- **GliderSliver**: Smoothly shifts the child in and out of the viewport.
- **FreezeSliver**: Applies a freezing effect to the child while it leaves the viewport.
- **BloodSliver**: Applies a blood covering effect to the child while it leaves the viewport.

# Explore the library

## ScrollHijackSliver

A sliver that consumes a specified amount of scrollable space before allowing its child to start scrolling. This is useful for creating custom scroll-driven animations and effects.

**Key features:**
- Exposes a `ValueListenable<double>` progress (0.0–1.0) to the builder, so you can animate your child based on the progress.
- Supports different progress calculation behaviors via `ScrollHijackProgressBehavior`.

**Example:**
```dart
CustomScrollView(
  slivers: [
    ScrollHijackSliver(
      consumingSpaceSize: 800,
      builder: (context, consumingProgress) {
        return Container(
          color: Colors.grey,
          height: 300,
          child: ValueListenableBuilder(
            valueListenable: consumingProgress,
            builder: (context, value, child) {
              return CustomPaint(
                painter: MyCustomPainter(progress: value),
              );
            },
          ),
        );
      },
    ),
    // ... other slivers ...
  ],
)
```

## LeavingViewportShaderSliver

A sliver that applies a fragment shader effect to its child as it leaves the viewport. This enables advanced visual effects as the user scrolls.

**Key features:**
- Can operate with a raw `FragmentShader` that uses a specific order of arguments (size, offset, progress), or with a custom shader wrapper for any uniform order via the `LeavingViewportShader` interface.
- The shader receives the child's size, paint offset, and a progress value (0.0–1.0) indicating how much the child has left the viewport.

**Example:**
```dart
CustomScrollView(
  slivers: [
    // Using a raw FragmentShader (default uniform order)
    LeavingViewportShaderSliver.fromFragmentShader(
      shader: myFragmentShader,
      child: Image.network('https://...'),
    ),
    // Using a custom wrapper for arbitrary uniform order
    LeavingViewportShaderSliver(
      shader: MyCustomLeavingViewportShader(),
      child: Image.network('https://...'),
    ),
    // ... other slivers ...
  ],
)
```

There are also two built-in inheritances of `LeavingViewportShaderSliver`:

### FreezeSliver

A sliver that applies a "freezing" shader effect to its child as it leaves the viewport. This effect is built-in and requires no manual shader setup.

**Key features:**
- Uses a predefined freezing shader bundled with the package.
- No shader code required—just wrap a content with the sliver.

**Example:**
```dart
CustomScrollView(
  slivers: [
    FreezeSliver(
      child: Image.network('https://...'),
    ),
    // ... other slivers ...
  ],
)
```

### BloodSliver

A sliver that applies a "blood covering" shader effect to its child as it leaves the viewport. This effect is built-in and requires no manual shader setup.

**Key features:**
- Uses a predefined blood shader bundled with the package.
- No shader code required—just wrap a content with the sliver.

**Example:**
```dart
CustomScrollView(
  slivers: [
    BloodSliver(
      child: Image.network('https://...'),
    ),
    // ... other slivers ...
  ],
)
```

## LeavingViewportTransformedRenderSliver

A base render sliver for creating scroll-driven 3D or 2D transformations as a child leaves the viewport. This class is intended for advanced use, enabling you to define custom transformation effects (such as rotation, scaling, skewing, etc.) based on scroll progress.

**Key features:**
- Exposes a `performTransform` method to define any transformation matrix based on child size and leaving progress.
- Handles all the layout, painting, and hit testing logic for you.
- Allows to define a custom hit testing logic if it is necessary.

**Usage:**
To create a custom effect, extend `LeavingViewportTransformedRenderSliver` and implement `performTransform`.

**Example:**
```dart
class MyCustomTransformedSliver extends SingleChildRenderObjectWidget {
  const MyCustomTransformedSliver({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MyCustomTransformedRenderSliver();
}

class _MyCustomTransformedRenderSliver extends LeavingViewportTransformedRenderSliver {
  @override
  Matrix4? performTransform(Size childSize, double progress) {
    // Scale pulsation: scale oscillates as the child leaves the viewport
    final double scale = 1.0 - 0.2 * (math.sin(progress * math.pi * 4)).abs();
    final Matrix4 matrix = Matrix4.identity();
    matrix.translate(childSize.width / 2, childSize.height / 2);
    matrix.scale(scale, scale);
    matrix.translate(-childSize.width / 2, -childSize.height / 2);
    return matrix;
  }
}
```

There are also two built-in inheritances of `LeavingViewportTransformedRenderSliver`:

### SpinnerSliver

A sliver that rotates its child as it leaves the viewport. The rotation is anchored to a configurable side and the maximum angle can be customized.

**Key features:**
- Rotates the child around a specified anchor (left or right).
- Configurable maximum rotation angle.

**Example:**
```dart
CustomScrollView(
  slivers: [
    SpinnerSliver(
      anchorSide: SpinnerAnchorSide.left, // or SpinnerAnchorSide.right
      maxAngle: math.pi / 2, // 90 degrees
      child: Image.network('https://...'),
    ),
    // ... other slivers ...
  ],
)
```

### GliderSliver

A sliver that smoothly slides its child left or right as it leaves the viewport, creating a gliding effect.

**Key features:**
- Shifts the child along the cross axis based on scroll progress.
- Configurable exit side (left or right).

**Example:**
```dart
CustomScrollView(
  slivers: [
    GliderSliver(
      exitSide: GliderExitSide.left, // or GliderExitSide.right
      child: Image.network('https://...'),
    ),
    // ... other slivers ...
  ],
)
```

# Maintainer
<a href="https://github.com/MbIXjkee">
    <div style="display: inline-block;">
        <img src="https://i.ibb.co/6Hhpg5L/circle-ava-jedi.png" height="64" width="64" alt="Maintainer avatar">
        <p style="float:right; margin-left: 8px;">Mikhail Zotyev</p>
    </div>
</a>

# License

This project is licensed under the MIT License. See [LICENSE](https://github.com/MbIXjkee/sliver_catalog/blob/main/LICENSE) for details.
