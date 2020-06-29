import 'dart:math' as math;

import '../utils/misc.dart';
import '../utils/ttf.dart';
import 'table/glyph/simple.dart';

const kDefaultAchVendID = '    ';
const kDefaultUnitsPerEm = 1024; // A power of two is recommended
const kDefaultBaselineExtension = 150;
const kDefaultFontRevision = Revision(1, 0);

const kDefaultGlyphCharCode = <int>[
  // .notdef doesn't have charcode
  kUnicodeSpaceCharCode
];

const kDefaultGlyphIndex = <int>[
  0, // .notdef
  3, // space
];

/// Generates list of default glyphs (.notdef 'rectangle' and empty space)
List<SimpleGlyph> generateDefaultGlyphList(int ascender) => [
  _generateNotdefGlyph(ascender),
  SimpleGlyph.empty(),
];

SimpleGlyph _generateNotdefGlyph(int ascender) {
  const kRelativeWidth = .7;
  const kRelativeThickness = .1;

  final xOuterOffset = (kRelativeWidth * ascender / 2).round();
  final thickness = (kRelativeThickness * xOuterOffset).round();
  
  final outerRect = math.Rectangle.fromPoints(
    const math.Point(0, 0),
    math.Point(xOuterOffset, ascender)
  );
  
  final innerRect = math.Rectangle.fromPoints(
    math.Point(thickness, thickness),
    math.Point(xOuterOffset - thickness, ascender - thickness)
  );

  final points = [
    // Outer rectangle clockwise
    outerRect.bottomLeft, outerRect.bottomRight, outerRect.topRight, outerRect.topLeft,
    
    // Inner rectangle counter-clockwise
    innerRect.bottomLeft, innerRect.topLeft, innerRect.topRight, innerRect.bottomRight,
  ];

  return SimpleGlyph.fromPoints([3, 7], points);
}