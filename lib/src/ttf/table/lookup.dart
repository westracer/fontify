import 'dart:typed_data';

import '../../utils/ttf.dart';
import '../debugger.dart';
import 'coverage.dart';

const kLookupListTableSize = 4;

const _kDefaultSubtableList = [
  LigatureSubstitutionSubtable(1, 6, 0, [], kDefaultCoverageTable)
];

const _kDefaultLookupTableList = [
  LookupTable(4, 0, 1, [8], 1, _kDefaultSubtableList)
];

abstract class SubstitutionSubtable {
  const SubstitutionSubtable();

  factory SubstitutionSubtable.fromByteData(
    ByteData byteData, int offset, int lookupType
  ) {
    switch (lookupType) {
      case 4:
        return LigatureSubstitutionSubtable.fromByteData(byteData, offset);
      default:
        TTFDebugger.debugUnsupportedTableFormat('Lookup', lookupType);
        return null;
    }
  }

  int get size;
}

class LigatureSubstitutionSubtable extends SubstitutionSubtable {
  const LigatureSubstitutionSubtable(
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

    final coverageTable = CoverageTable.fromByteData(byteData, offset + coverageOffset);
    
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

  @override
  int get size => 6 + 2 * ligatureSetCount + coverageTable.size;
}

class LookupTable {
  const LookupTable(
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
    final lookupFlag = byteData.getUint16(offset + 2);
    final subTableCount = byteData.getUint16(offset + 4);
    final subtableOffsets = List.generate(
      subTableCount,
      (i) => byteData.getUint16(offset + 6 + 2 * i)
    );
    final useMarkFilteringSet = checkBitMask(lookupFlag, 0x0010);
    final markFilteringSetOffset = offset + 6 + 2 * subTableCount;

    final subtables = List.generate(
      subTableCount,
      (i) => SubstitutionSubtable.fromByteData(
        byteData,
        offset + subtableOffsets[i],
        lookupType
      )
    );
    
    return LookupTable(
      lookupType,
      lookupFlag,
      subTableCount,
      subtableOffsets,
      useMarkFilteringSet ? byteData.getUint16(markFilteringSetOffset) : null,
      subtables,
    );
  }

  final int lookupType;
  final int lookupFlag;
  final int subTableCount;
  final List<int> subtableOffsets;
  final int markFilteringSet;

  final List<SubstitutionSubtable> subtables;

  int get size {
    final subtableListSize = subtables.fold<int>(0, (p, t) => p + t.size);

    return 6 + 2 * subTableCount + subtableListSize;
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

  factory LookupListTable.create() => LookupListTable(1, [4], _kDefaultLookupTableList);

  final int lookupCount;
  final List<int> lookups;

  final List<LookupTable> lookupTables;

  int get size {
    final lookupListTableSize = lookupTables.fold<int>(0, (p, t) => p + t.size);

    return 2 + 2 * lookupCount + lookupListTableSize;
  }
}