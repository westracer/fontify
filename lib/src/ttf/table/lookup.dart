import 'dart:typed_data';

import '../debugger.dart';

import 'coverage.dart';

const kLookupListTableSize = 4;

abstract class SubstitutionSubtable {}

class LigatureSubstitutionSubtable extends SubstitutionSubtable {
  LigatureSubstitutionSubtable(
    this.substFormat,
    this.coverageOffset,
    this.ligatureSetCount,
    this.ligatureSetOffsets,
    this.coverageTable,
  );

  factory LigatureSubstitutionSubtable.fromByteData(
    ByteData byteData, 
    int offset
  ) {
    final coverageOffset = byteData.getUint16(offset + 2);
    final ligatureSetCount = byteData.getUint16(offset + 4);
    final subtableOffsets = List.generate(
      ligatureSetCount,
      (i) => byteData.getUint16(offset + 6 + 2 * i)
    );

    final coverageTable = _parseCoverageTable(byteData, offset + coverageOffset);
    
    return LigatureSubstitutionSubtable(
      byteData.getUint16(offset),
      coverageOffset,
      ligatureSetCount,
      subtableOffsets,
      coverageTable,
    );
  }

  final int substFormat;
  final int coverageOffset;
  final int ligatureSetCount;
  final List<int> ligatureSetOffsets;

  final CoverageTable coverageTable;

  static CoverageTable _parseCoverageTable(ByteData byteData, int offset) {
    final format = byteData.getUint16(offset);

    switch (format) {
      case 1:
        return CoverageTableFormat1.fromByteData(byteData, offset);
      default:
        TTFDebugger.debugUnsupportedTableFormat('Coverage', format);
        return null;
    }
  }
}

class LookupTable {
  LookupTable(
    this.lookupType,
    this.lookupFlag,
    this.subTableCount,
    this.subtableOffsets,
    this.markFilteringSet,
    this.subtables,
  );

  factory LookupTable.fromByteData(
    ByteData byteData, 
    int offset
  ) {
    final lookupType = byteData.getUint16(offset);
    final subTableCount = byteData.getUint16(offset + 4);
    final subtableOffsets = List.generate(
      subTableCount,
      (i) => byteData.getUint16(offset + 6 + 2 * i)
    );
    final markFilteringSetOffset = offset + 6 + 2 * subTableCount;

    final subtables = List.generate(
      subTableCount,
      (i) => _parseSubtable(byteData, offset + subtableOffsets[i], lookupType)
    );
    
    return LookupTable(
      lookupType,
      byteData.getUint16(offset + 2),
      subTableCount,
      subtableOffsets,
      byteData.getUint16(markFilteringSetOffset),
      subtables,
    );
  }

  final int lookupType;
  final int lookupFlag;
  final int subTableCount;
  final List<int> subtableOffsets;
  final int markFilteringSet;

  final List<SubstitutionSubtable> subtables;

  static SubstitutionSubtable _parseSubtable(ByteData byteData, int offset, int lookupType) {
    switch (lookupType) {
      case 4:
        return LigatureSubstitutionSubtable.fromByteData(byteData, offset);
      default:
        TTFDebugger.debugUnsupportedTableFormat('Lookup', lookupType);
        return null;
    }
  }
}

class LookupListTable {
  LookupListTable(
    this.lookupCount,
    this.lookups,
    this.lookupTables
  );

  factory LookupListTable.fromByteData(ByteData byteData, int offset) {
    final lookupCount = byteData.getUint16(offset);
    final lookups = List.generate(
      lookupCount, 
      (i) => byteData.getUint16(offset + 2 + kLookupListTableSize * i)
    );
    final lookupTables = List.generate(
      lookupCount,
      (i) => LookupTable.fromByteData(byteData, offset + lookups[i])
    );
    
    return LookupListTable(lookupCount, lookups, lookupTables);
  }

  final int lookupCount;
  final List<int> lookups;

  final List<LookupTable> lookupTables;
}