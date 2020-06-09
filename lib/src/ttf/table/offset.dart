import 'dart:typed_data';

import 'abstract.dart';

const kOffsetTableLength = 12;
const kOffsetTableOTTOversion = 0x4F54544F;

class OffsetTable extends FontTable {
  OffsetTable(
    this.sfntVersion, 
    this.numTables, 
    this.searchRange, 
    this.entrySelector, 
    this.rangeShift
  ) : super(0, kOffsetTableLength);

  factory OffsetTable.fromByteData(ByteData data) => 
    OffsetTable(
      data.getUint32(0),
      data.getUint16(4), 
      data.getUint16(6), 
      data.getUint16(8), 
      data.getUint16(10)
    );

  final int sfntVersion;
  final int numTables;
  final int searchRange;
  final int entrySelector;
  final int rangeShift;

  bool get isOTTO => sfntVersion == kOffsetTableOTTOversion;
}