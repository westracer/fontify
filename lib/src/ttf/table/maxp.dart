import 'dart:typed_data';

import '../debugger.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const _kVersion0 = 0x00005000;
const _kVersion1 = 0x00010000;

class MaximumProfileTable extends FontTable {
  MaximumProfileTable.v0(
    TableRecordEntry entry,
    this.numGlyphs
  ) : 
    version = _kVersion0,
    maxPoints = null, 
    maxContours = null,
    maxCompositePoints = null,
    maxCompositeContours = null,
    maxZones = null,
    maxTwilightPoints = null,
    maxStorage = null,
    maxFunctionDefs = null,
    maxInstructionDefs = null,
    maxStackElements = null,
    maxSizeOfInstructions = null,
    maxComponentElements = null,
    maxComponentDepth = null,
    super.fromTableRecordEntry(entry);

  MaximumProfileTable.v1(
    TableRecordEntry entry, 
    this.numGlyphs,
    this.maxPoints, 
    this.maxContours, 
    this.maxCompositePoints, 
    this.maxCompositeContours, 
    this.maxZones, 
    this.maxTwilightPoints, 
    this.maxStorage, 
    this.maxFunctionDefs, 
    this.maxInstructionDefs, 
    this.maxStackElements, 
    this.maxSizeOfInstructions, 
    this.maxComponentElements, 
    this.maxComponentDepth
  ) :
    version = _kVersion1,
    super.fromTableRecordEntry(entry);

  factory MaximumProfileTable.fromByteData(ByteData data, TableRecordEntry entry) {
    final version = data.getInt32(entry.offset);

    if (version == _kVersion0) {
      return MaximumProfileTable.v0(
        entry,
        data.getUint16(entry.offset + 4)
      );
    } if (version == _kVersion1) {
      return MaximumProfileTable.v1(
        entry,
        data.getUint16(entry.offset + 4),
        data.getUint16(entry.offset + 6),
        data.getUint16(entry.offset + 8),
        data.getUint16(entry.offset + 10),
        data.getUint16(entry.offset + 12),
        data.getUint16(entry.offset + 14),
        data.getUint16(entry.offset + 16),
        data.getUint16(entry.offset + 18),
        data.getUint16(entry.offset + 20),
        data.getUint16(entry.offset + 22),
        data.getUint16(entry.offset + 24),
        data.getUint16(entry.offset + 26),
        data.getUint16(entry.offset + 28),
        data.getUint16(entry.offset + 30),
      );
    } else {
      TTFDebugger.debugUnsupportedTableVersion(entry.tag, version);
      return null;
    }
  }

  // Version 0.5
  final int version;
  final int numGlyphs;

  // Version 1.0
  final int maxPoints;
  final int maxContours;
  final int maxCompositePoints;
  final int maxCompositeContours;
  final int maxZones;
  final int maxTwilightPoints;
  final int maxStorage;
  final int maxFunctionDefs;
  final int maxInstructionDefs;
  final int maxStackElements;
  final int maxSizeOfInstructions;
  final int maxComponentElements;
  final int maxComponentDepth;
}