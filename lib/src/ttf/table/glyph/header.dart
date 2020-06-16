import 'dart:typed_data';

const _kGlyphHeaderSize = 10;

class GlyphHeader {
  GlyphHeader(
    this.offset,
    this.numberOfContours, 
    this.xMin, 
    this.yMin, 
    this.xMax, 
    this.yMax
  );

  factory GlyphHeader.fromByteData(ByteData byteData, int offset) {
    return GlyphHeader(
      offset,
      byteData.getInt16(offset),
      byteData.getInt16(offset + 2),
      byteData.getInt16(offset + 4),
      byteData.getInt16(offset + 6),
      byteData.getInt16(offset + 8),
    );
  }

  final int offset;

  final int numberOfContours;
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  bool get isComposite => numberOfContours.isNegative;

  int get size => _kGlyphHeaderSize;
}