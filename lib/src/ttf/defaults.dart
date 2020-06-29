import 'dart:math' as math;

import '../utils/ttf.dart';
import 'table/glyph/simple.dart';

const kDefaultAchVendID = '    ';
const kDefaultUnitsPerEm = 1024; // A power of two is recommended
const kDefaultFontRevision = Revision(1, 0);

const kDefaultGlyphIndex = [
  0, // .notdef
  3, // space
];

/// Generates list of default glyphs (.notdef 'rectangle' and empty space)
List<SimpleGlyph> generateDefaultGlyphList(int unitsPerEm) => [
  _generateNotdefGlyph(unitsPerEm),
  SimpleGlyph.empty(),
];

SimpleGlyph _generateNotdefGlyph(int unitsPerEm) {
  const kRelativeWidth = .7;
  const kRelativeThickness = .1;

  final xOuterOffset = (kRelativeWidth * unitsPerEm / 2).round();
  final thickness = (kRelativeThickness * xOuterOffset).round();
  
  final outerRect = math.Rectangle.fromPoints(
    const math.Point(0, 0),
    math.Point(xOuterOffset, unitsPerEm)
  );
  
  final innerRect = math.Rectangle.fromPoints(
    math.Point(thickness, thickness),
    math.Point(xOuterOffset - thickness, unitsPerEm - thickness)
  );

  final points = [
    // Outer rectangle clockwise
    outerRect.bottomLeft, outerRect.bottomRight, outerRect.topRight, outerRect.topLeft,
    
    // Inner rectangle counter-clockwise
    innerRect.bottomLeft, innerRect.topLeft, innerRect.topRight, innerRect.bottomRight,
  ];

  return SimpleGlyph.fromPoints([3, 7], points);
}