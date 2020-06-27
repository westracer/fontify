import 'dart:typed_data';

import '../../../common/codable/binary.dart';
import '../../../utils/ttf.dart';
import 'flag.dart';
import 'header.dart';

class SimpleGlyph implements BinaryCodable {
  SimpleGlyph(
    this.header,
    this.endPtsOfContours,
    this.instructions,
    this.flags,
    this.xCoordinates,
    this.yCoordinates,
  );

  factory SimpleGlyph.empty() {
    return SimpleGlyph(GlyphHeader(0, 0, 0, 0, 0), [], [], [], [], []);
  }

  factory SimpleGlyph.fromByteData(ByteData byteData, GlyphHeader header, int glyphOffset) {
    int offset = glyphOffset + header.size;

    final endPtsOfContours = [
      for (int i = 0; i < header.numberOfContours; i++)
        byteData.getUint16(offset + i * 2)
    ];
    offset += header.numberOfContours * 2;

    final instructionLength = byteData.getUint16(offset);
    offset += 2;

    final instructions = [
      for (int i = 0; i < instructionLength; i++)
        byteData.getUint8(offset + i)
    ];
    offset += instructionLength;

    final numberOfPoints = _getNumberOfPoints(endPtsOfContours);
    final flags = <SimpleGlyphFlag>[];

    for (int i = 0; i < numberOfPoints; i++) {
      final flag = SimpleGlyphFlag.fromByteData(byteData, offset);
      offset += flag.size;
      flags.add(flag);

      for (int j = 0; j < flag.repeatTimes; j++) {
        flags.add(flag);
      }

      i += flag.repeatTimes;
    }

    final xCoordinates = <int>[];

    for (int i = 0; i < numberOfPoints; i++) {
      final short = flags[i].xShortVector;
      final same = flags[i].xIsSameOrPositive;
      
      if (short) {
        xCoordinates.add((same ? 1 : -1) * byteData.getUint8(offset++));
      } else {
        if (same) {
          xCoordinates.add(0);
        } else {
          xCoordinates.add(byteData.getInt16(offset));
          offset += 2;
        }
      }
    }
    
    final yCoordinates = <int>[];

    for (int i = 0; i < numberOfPoints; i++) {
      final short = flags[i].yShortVector;
      final same = flags[i].yIsSameOrPositive;
      
      if (short) {
        yCoordinates.add((same ? 1 : -1) * byteData.getUint8(offset++));
      } else {
        if (same) {
          yCoordinates.add(0);
        } else {
          yCoordinates.add(byteData.getInt16(offset));
          offset += 2;
        }
      }
    }
    
    return SimpleGlyph(
      header,
      endPtsOfContours,
      instructions,
      flags,
      _relToAbsCoordinates(xCoordinates),
      _relToAbsCoordinates(yCoordinates),
    );
  }

  final GlyphHeader header;
  final List<int> endPtsOfContours;
  final List<int> instructions;
  final List<SimpleGlyphFlag> flags;
  final List<int> xCoordinates;
  final List<int> yCoordinates;

  int get _coordinatesSize {
    int coordinatesSize = 0;

    for (int i = 0; i < flags.length; i++) {
      final xShort = flags[i].xShortVector;
      final yShort = flags[i].yShortVector;
      final xSame = flags[i].xIsSameOrPositive;
      final ySame = flags[i].yIsSameOrPositive;

      coordinatesSize += xShort ? 1 : (xSame ? 0 : 2);
      coordinatesSize += yShort ? 1 : (ySame ? 0 : 2);
    }

    return coordinatesSize;
  }

  int get _flagsSize {
    int flagsSize = 0;

    for (int i = 0; i < flags.length; i++) {
      final flag = flags[i];

      flagsSize += flag.size;

      if (flag.repeatTimes > 0) {
        i += flag.repeatTimes;
      }
    }

    return flagsSize;
  }

  int get _descriptionSize {
    final endPointsSize = endPtsOfContours.length * 2;
    final instructionsSize = 2 + instructions.length;

    return endPointsSize + instructionsSize + _flagsSize + _coordinatesSize;
  }

  @override
  int get size => header.size + _descriptionSize;

  @override
  void encodeToBinary(ByteData byteData) {
    header.encodeToBinary(byteData);
    int offset = header.size;

    for (int i = 0; i < header.numberOfContours; i++) {
      byteData.setUint16(offset + i * 2, endPtsOfContours[i]);
    }
    offset += header.numberOfContours * 2;

    byteData.setUint16(offset, instructions.length);
    offset += 2;

    for (int i = 0; i < instructions.length; i++) {
      byteData.setUint8(offset + i, instructions[i]);
    }
    offset += instructions.length;

    final numberOfPoints = _getNumberOfPoints(endPtsOfContours);

    for (int i = 0; i < numberOfPoints; i++) {
      final flag = flags[i];
      flag.encodeToBinary(byteData.sublistView(offset, flag.size));

      offset += flag.size;
      i += flag.repeatTimes;
    }

    final xRelCoordinates = _absToRelCoordinates(xCoordinates);
    final yRelCoordinates = _absToRelCoordinates(yCoordinates);
    
    for (int i = 0; i < numberOfPoints; i++) {
      final short = flags[i].xShortVector;
      final same = flags[i].xIsSameOrPositive;
      
      if (short) {
        byteData.setUint8(offset++, xRelCoordinates[i].abs());
      } else {
        if (!same) {
          byteData.setInt16(offset, xRelCoordinates[i]);
          offset += 2;
        }
      }
    }
    
    for (int i = 0; i < numberOfPoints; i++) {
      final short = flags[i].yShortVector;
      final same = flags[i].yIsSameOrPositive;
      
      if (short) {
        byteData.setUint8(offset++, yRelCoordinates[i].abs());
      } else {
        if (!same) {
          byteData.setInt16(offset, yRelCoordinates[i]);
          offset += 2;
        }
      }
    }
  }

  static List<int> _relToAbsCoordinates(List<int> relCoordinates) {
    if (relCoordinates.isEmpty) {
      return [];
    }

    final absCoordinates = List.filled(relCoordinates.length, 0);
    int currentValue = 0;

    for (int i = 0; i < relCoordinates.length; i++) {
      currentValue += relCoordinates[i];
      absCoordinates[i] = currentValue;
    }

    return absCoordinates;
  }

  static List<int> _absToRelCoordinates(List<int> absCoordinates) {
    if (absCoordinates.isEmpty) {
      return [];
    }

    final relCoordinates = List.filled(absCoordinates.length, 0);
    int prevValue = 0;

    for (int i = 0; i < absCoordinates.length; i++) {
      relCoordinates[i] = absCoordinates[i] - prevValue;
      prevValue = absCoordinates[i];
    }

    return relCoordinates;
  }

  static int _getNumberOfPoints(List<int> endPtsOfContours) => 
    endPtsOfContours.isNotEmpty ? endPtsOfContours.last + 1 : 0;
}