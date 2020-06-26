import 'dart:math' as math;
import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../debugger.dart';

const kOffsetTableLength = 12;

const _kOffsetTableNonOTTOversion = 0x00010000;
const _kOffsetTableOTTOversion    = 0x4F54544F;

class OffsetTable implements BinaryCodable {
  OffsetTable(
    this.sfntVersion, 
    this.numTables, 
    this.searchRange, 
    this.entrySelector, 
    this.rangeShift
  );

  factory OffsetTable.fromByteData(ByteData data) {
    final version = data.getUint32(0);

    if (version != _kOffsetTableNonOTTOversion) {
      TTFDebugger.debugUnsupportedTableVersion('Offset', version);
    }

    return OffsetTable(
      version,
      data.getUint16(4), 
      data.getUint16(6), 
      data.getUint16(8), 
      data.getUint16(10)
    );
  }

  factory OffsetTable.create(int numTables) {
    final entrySelector = (math.log(numTables) / math.ln2).floor();
    final searchRange = 16 * math.pow(2, entrySelector).toInt();
    final rangeShift = numTables * 16 - searchRange;
    
    return OffsetTable(
      _kOffsetTableNonOTTOversion,
      numTables,
      searchRange,
      entrySelector,
      rangeShift
    );
  }

  final int sfntVersion;
  final int numTables;
  final int searchRange;
  final int entrySelector;
  final int rangeShift;

  bool get isOTTO => sfntVersion == _kOffsetTableOTTOversion;

  @override
  int get size => kOffsetTableLength;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint32(0, sfntVersion)
      ..setUint16(4, numTables)
      ..setUint16(6, searchRange)
      ..setUint16(8, entrySelector)
      ..setUint16(10, rangeShift);
  }
}