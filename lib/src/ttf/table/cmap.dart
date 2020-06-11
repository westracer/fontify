import 'dart:typed_data';

import '../../utils/exception.dart';
import '../../utils/ttf.dart' as ttf_utils;

import 'abstract.dart';
import 'table_record_entry.dart';

const _kEncodingRecordSize = 8;
const _kSequentialMapGroupSize = 12;

class EncodingRecord {
  EncodingRecord(
    this.platformID,
    this.encodingID,
    this.offset
  );

  factory EncodingRecord.fromByteData(ByteData byteData, int offset) {
    return EncodingRecord(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      byteData.getUint32(offset + 4),
    );
  }

  final int platformID;
  final int encodingID;
  final int offset;
}

class SequentialMapGroup {
  SequentialMapGroup(
    this.startCharCode,
    this.endCharCode,
    this.startGlyphID
  );

  factory SequentialMapGroup.fromByteData(ByteData byteData, int offset) {
    return SequentialMapGroup(
      byteData.getUint32(offset),
      byteData.getUint32(offset + 4),
      byteData.getUint32(offset + 8),
    );
  }

  final int startCharCode;
  final int endCharCode;
  final int startGlyphID;
}

class CharacterToGlyphTableHeader {
  CharacterToGlyphTableHeader(
    this.version,
    this.numTables,
    this.encodingRecords,
  );

  factory CharacterToGlyphTableHeader.fromByteData(
    ByteData byteData,
    TableRecordEntry entry
  ) {
    final version = byteData.getUint16(entry.offset);
    final numTables = byteData.getUint16(entry.offset + 2);
    final encodingRecords = List.generate(
      numTables, 
      (i) => EncodingRecord.fromByteData(
        byteData, 
        entry.offset + 4 + _kEncodingRecordSize * i
      )
    );

    return CharacterToGlyphTableHeader(version, numTables, encodingRecords);
  }

  final int version;
  final int numTables;
  final List<EncodingRecord> encodingRecords;

  int get size => 4 + _kEncodingRecordSize * encodingRecords.length;
}

abstract class CmapData {
  CmapData(this.format);

  final int format;
}

class CmapByteEncodingTable extends CmapData {
  CmapByteEncodingTable(
    int format,
    this.length,
    this.language,
    this.glyphIdArray
  ) : super(format);

  factory CmapByteEncodingTable.fromByteData(ByteData byteData, int offset) {
    return CmapByteEncodingTable(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      byteData.getUint16(offset + 4),
      List.generate(256, (i) => byteData.getUint8(offset + 6 + i))
    );
  }

  final int length;
  final int language;
  final List<int> glyphIdArray;
}

class CmapSegmentMappingToDeltaValuesTable extends CmapData {
  CmapSegmentMappingToDeltaValuesTable(
    int format,
    this.length,
    this.language,
    this.segCount,
    this.searchRange,
    this.entrySelector,
    this.rangeShift,
    this.endCode,
    this.reservedPad,
    this.startCode,
    this.idDelta,
    this.idRangeOffset,
    this.glyphIdArray
  ) : super(format);

  factory CmapSegmentMappingToDeltaValuesTable.fromByteData(ByteData byteData, int startOffset) {
    final length = byteData.getUint16(startOffset + 2);
    final segCount = byteData.getUint16(startOffset + 6) ~/ 2;

    int offset = startOffset + 14;

    final endCode = List.generate(
      segCount, 
      (i) => byteData.getUint16(offset + 2 * i)
    );
    offset += 2 * segCount;

    final reservedPad = byteData.getUint16(offset);
    offset += 2;

    final startCode = List.generate(
      segCount, 
      (i) => byteData.getUint16(offset + 2 * i)
    );
    offset += 2 * segCount;

    final idDelta = List.generate(
      segCount, 
      (i) => byteData.getInt16(offset + 2 * i)
    );
    offset += 2 * segCount;

    final idRangeOffset = List.generate(
      segCount, 
      (i) => byteData.getUint16(offset + 2 * i)
    );
    offset += 2 * segCount;

    final glyphIdArrayLength = ((startOffset + length) - offset) >> 1;
    final glyphIdArray = List.generate(
      glyphIdArrayLength, 
      (i) => byteData.getUint16(offset + 2 * i)
    );

    return CmapSegmentMappingToDeltaValuesTable(
      byteData.getUint16(startOffset),
      length,
      byteData.getUint16(startOffset + 4),
      segCount,
      byteData.getUint16(startOffset + 8),
      byteData.getUint16(startOffset + 10),
      byteData.getUint16(startOffset + 12),
      endCode,
      reservedPad,
      startCode,
      idDelta,
      idRangeOffset,
      glyphIdArray
    );
  }

  final int length;
  final int language;
  final int segCount;
  final int searchRange;
  final int entrySelector;
  final int rangeShift;
  final List<int> endCode;
  final int reservedPad;
  final List<int> startCode;
  final List<int> idDelta;
  final List<int> idRangeOffset;
  final List<int> glyphIdArray;
}

class CmapSegmentedCoverageTable extends CmapData {
  CmapSegmentedCoverageTable(
    int format,
    this.reversed,
    this.length,
    this.language,
    this.numGroups,
    this.groups,
  ) : super(format);

  factory CmapSegmentedCoverageTable.fromByteData(ByteData byteData, int offset) {
    final numGroups = byteData.getUint32(offset + 12);

    return CmapSegmentedCoverageTable(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      byteData.getUint32(offset + 4),
      byteData.getUint32(offset + 8),
      numGroups,
      List.generate(
        numGroups, 
        (i) => SequentialMapGroup.fromByteData(
          byteData, 
          offset + 16 + _kSequentialMapGroupSize * i
        )
      )
    );
  }

  final int reversed;
  final int length;
  final int language;
  final int numGroups;
  final List<SequentialMapGroup> groups;
}

class CharacterToGlyphTable extends FontTable {
  CharacterToGlyphTable(
    TableRecordEntry entry,
    this.header,
    this.data,
  ) : super.fromTableRecordEntry(entry);

  factory CharacterToGlyphTable.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    final header = CharacterToGlyphTableHeader.fromByteData(byteData, entry);
    final data = List.generate(
      header.numTables, 
      (i) => _parseDataTable(byteData, entry.offset + header.encodingRecords[i].offset)
    );

    return CharacterToGlyphTable(entry, header, data);
  }

  static CmapData _parseDataTable(ByteData byteData, int offset) {
    final format = byteData.getUint16(offset);

    switch (format) {
      case 0:
        return CmapByteEncodingTable.fromByteData(byteData, offset);
      case 4:
        return CmapSegmentMappingToDeltaValuesTable.fromByteData(byteData, offset);
      case 12:
        return CmapSegmentedCoverageTable.fromByteData(byteData, offset);
      default:
        throw TableVersionException(ttf_utils.kCmapTag, format);
    }
  }

  final CharacterToGlyphTableHeader header;
  final List<CmapData> data;
}