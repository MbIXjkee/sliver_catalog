## Unreleased
* Corrected scroll offset is used for `hasVisualOverflow` calculation, to avoid clipping when it is not necessary.
* Simplify child paintOffset calculation of ScrollHijackSliver for case of reverse scrolling.

## 0.1.3
### Added
* Links to interactive demo in documentation.
### Changed
* Internal implementations that should not have been exported are removed from the export.

## 0.1.2
### Added
* Detailed Readme documentation for the package.

## 0.1.1
### Added
* A basic Readme for the package. 

## 0.1.0
### Info
* Initial release

### Added
* Basic sliver that performs a transformation during the leaving of the visual part of the viewport.
* Basic sliver that overlays a fragment shader effect as the child scrolls out of the viewport.
* Basic sliver that consumes a specified amount of scrollable space before allowing its child to start scrolling.
* Sliver that applies a shader blood covering effect to the content.
* Sliver that applies a shader freezing effect to the content.
* Sliver that applies a rotation transformation to the content.
* Sliver that applies a shifting transformation to the content.