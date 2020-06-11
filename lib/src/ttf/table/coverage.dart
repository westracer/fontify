import 'dart:typed_data';

abstract class CoverageTable {}

class CoverageTableFormat1 extends CoverageTable {
  CoverageTableFormat1(
    this.coverageFormat,
    this.glyphCount,
    this.glyphArray
  );

  factory CoverageTableFormat1.fromByteData(
    ByteData byteData,
    int offset
  ) {
    final coverageFormat = byteData.getUint16(offset);
    final glyphCount = byteData.getUint16(offset + 2);
    final glyphArray = List.generate(
      glyphCount,
      (i) => byteData.getUint16(offset + 4 + 2 * i)
    );

    return CoverageTableFormat1(
      coverageFormat,
      glyphCount,
      glyphArray
    );
  }

  final int coverageFormat;
  final int glyphCount;
  final List<int> glyphArray;
}