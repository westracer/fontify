import 'dart:typed_data';

import 'flag.dart';
import 'header.dart';

class SimpleGlyph {
  SimpleGlyph(
    this.header,
    this.endPtsOfContours,
    this.instructions,
    this.flags
  );

  factory SimpleGlyph.fromByteData(ByteData byteData, GlyphHeader header) {
    int descriptionOffset = header.offset + kGlyphHeaderSize;

    final endPtsOfContours = [
      for (int j = 0; j < header.numberOfContours; j++)
        byteData.getUint16(descriptionOffset + j * 2)
    ];
    descriptionOffset += header.numberOfContours * 2;

    final instructionLength = byteData.getUint16(descriptionOffset);
    descriptionOffset += 2;

    final instructions = [
      for (int j = 0; j < instructionLength; j++)
        byteData.getUint8(descriptionOffset + j)
    ];
    descriptionOffset += instructionLength;

    final numberOfPoints = endPtsOfContours.isNotEmpty ? endPtsOfContours.last + 1 : 0;
    final flags = <SimpleGlyphFlag>[];

    for (int j = 0; j < numberOfPoints; j++) {
      final flag = SimpleGlyphFlag.fromByteData(byteData, descriptionOffset);
      descriptionOffset += flag.size;
      flags.add(flag);

      for (int k = 0; k < flag.repeatTimes; k++) {
        flags.add(flag);
      }

      j += flag.repeatTimes;
    }
    
    return SimpleGlyph(header, endPtsOfContours, instructions, flags);
  }

  final GlyphHeader header;
  final List<int> endPtsOfContours;
  final List<int> instructions;
  final List<SimpleGlyphFlag> flags;
}