import 'dart:math' as math;
import 'dart:typed_data';

import '../../utils/misc.dart';
import '../../utils/ttf.dart';
import '../debugger.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const _kFormat0  = 0;
const _kFormat4  = 4;
const _kFormat12 = 12;

const _kEncodingRecordSize = 8;
const _kSequentialMapGroupSize = 12;
const _kByteEncodingTableSize = 256 + 6;

/// Ordered list of encoding record templates, sorted by platform and encoding ID
const _kDefaultEncodingRecordList = [
  /// Unicode (2.0 or later semantics BMP only), format 4
  EncodingRecord.create(kPlatformUnicode, 3),
  
  /// Unicode (Unicode 2.0 or later semantics non-BMP characters allowed), format 12
  EncodingRecord.create(kPlatformUnicode, 4),
  
  /// Macintosh, format 0
  EncodingRecord.create(kPlatformUnicode, 0),

  /// Windows (Unicode BMP-only UCS-2), format 4
  EncodingRecord.create(kPlatformWindows, 1),

  /// Windows (Unicode UCS-4), format 12
  EncodingRecord.create(kPlatformWindows, 10),
];

/// Ordered list of encoding record format for each template
const _kDefaultEncodingRecordFormatList = [
  _kFormat4, _kFormat12, _kFormat0, _kFormat4, _kFormat12
];

class _Segment {
  _Segment(this.startCode, this.endCode, this.startGlyphID);

  final int startCode;
  final int endCode;
  final int startGlyphID;

  int get idDelta => startGlyphID - startCode;
}

class EncodingRecord {
  const EncodingRecord(
    this.platformID,
    this.encodingID,
    this.offset
  );

  const EncodingRecord.create(
    this.platformID,
    this.encodingID,
  ) : offset = null;

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

  int get size => _kEncodingRecordSize;
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

  int get size => _kSequentialMapGroupSize;
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

  factory CmapData.fromByteData(ByteData byteData, int offset) {
    final format = byteData.getUint16(offset);

    switch (format) {
      case _kFormat0:
        return CmapByteEncodingTable.fromByteData(byteData, offset);
      case _kFormat4:
        return CmapSegmentMappingToDeltaValuesTable.fromByteData(byteData, offset);
      case _kFormat12:
        return CmapSegmentedCoverageTable.fromByteData(byteData, offset);
      default:
        TTFDebugger.debugUnsupportedTableFormat(kCmapTag, format);
        return null;
    }
  }
  
  factory CmapData.create(List<_Segment> segmentList, int format) {
    switch (format) {
      case _kFormat0:
        return CmapByteEncodingTable.create();
      case _kFormat4:
        return CmapSegmentMappingToDeltaValuesTable.create(segmentList);
      case _kFormat12:
        return CmapSegmentedCoverageTable.create(segmentList);
      default:
        TTFDebugger.debugUnsupportedTableFormat(kCmapTag, format);
        return null;
    }
  }

  final int format;

  int get size;
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

  factory CmapByteEncodingTable.create() {
    return CmapByteEncodingTable(
      _kFormat0,
      _kByteEncodingTableSize,
      0,
      List.generate(256, (_) => 0) // Not using standard mac glyphs
    );
  }

  final int length;
  final int language;
  final List<int> glyphIdArray;

  @override
  int get size => _kByteEncodingTableSize;
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

  factory CmapSegmentMappingToDeltaValuesTable.create(List<_Segment> segmentList) {
    final startCode = segmentList.map((e) => e.startCode).toList();
    final endCode = segmentList.map((e) => e.endCode).toList();
    final idDelta = segmentList.map((e) => e.idDelta).toList();
    
    final segCount = segmentList.length;

    // Ignoring glyphIdArray
    final glyphIdArray = <int>[];
    final idRangeOffset = List.generate(
      segCount,
      (_) => 0
    );

    final entrySelector = (math.log(segCount) / math.ln2).floor();
    final searchRange = 2 * math.pow(2, entrySelector).toInt();
    final rangeShift = 2 * segCount - searchRange;

    /// Eight 2-byte variable
    /// Four 2-byte arrays of [segCount] length
    /// glyphIdArray is zero length
    final length = 16 + 4 * 2 * segCount;

    return CmapSegmentMappingToDeltaValuesTable(
      _kFormat4,
      length,
      0,    // Roman language
      segCount,
      searchRange,
      entrySelector,
      rangeShift,
      endCode,
      0,  // Reserved
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

  @override
  int get size => length;
}

class CmapSegmentedCoverageTable extends CmapData {
  CmapSegmentedCoverageTable(
    int format,
    this.reserved,
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

  factory CmapSegmentedCoverageTable.create(List<_Segment> segmentList) {
    final groups = segmentList.map(
      (e) => SequentialMapGroup(e.startCode, e.endCode, e.startGlyphID)
    ).toList();

    final numGroups = groups.length;
    final groupsSize = numGroups * _kSequentialMapGroupSize;

    /// Two 2-byte variables
    /// Three 4-byte variables
    /// SequentialMapGroup (12-byte) array of [numGroups] length
    final length = 16 + groupsSize;

    return CmapSegmentedCoverageTable(
      _kFormat12,
      0,
      length,
      0, // Roman language
      numGroups,
      groups
    );
  }

  final int reserved;
  final int length;
  final int language;
  final int numGroups;
  final List<SequentialMapGroup> groups;

  @override
  int get size => length;
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
      (i) => CmapData.fromByteData(byteData, entry.offset + header.encodingRecords[i].offset)
    );

    return CharacterToGlyphTable(entry, header, data);
  }

  factory CharacterToGlyphTable.create(int numOfGlyphs) {
    final charCodeList = _generateCharCodes(numOfGlyphs);
    final segmentList = _generateSegments(charCodeList);
    
    final subtableByFormat = _kDefaultEncodingRecordFormatList
      .toSet()
      .fold<Map<int, CmapData>>(
        {}, 
        (p, format) {
          p[format] = CmapData.create(segmentList, format);
          return p;
        }
      );

    final subtables = [
      for (final format in _kDefaultEncodingRecordFormatList)
        subtableByFormat[format]
    ];

    final header = CharacterToGlyphTableHeader(
      0,
      subtables.length,
      _kDefaultEncodingRecordList
    );

    return CharacterToGlyphTable(
      null,
      header,
      subtables
    );
  }

  final CharacterToGlyphTableHeader header;
  final List<CmapData> data;
  
  static List<int> _generateCharCodes(int numOfGlyphs) =>
    List.generate(numOfGlyphs, (i) => kUnicodePrivateUseAreaStart + i);

  static List<_Segment> _generateSegments(List<int> charCodeList) {
    int startCharCode = -1, prevCharCode = -1, startGlyphId = -1;

    final segmentList = <_Segment>[];

    for (int glyphId = 0; glyphId < charCodeList.length; glyphId++) {
      final charCode = charCodeList[glyphId];

      if (prevCharCode + 1 != charCode && startCharCode != -1) {
        // Save a segment, if there's a gap between previous and current codes
        segmentList.add(_Segment(startCharCode, prevCharCode, startGlyphId));

        // Next segment starts with new code
        startCharCode = charCode;
        startGlyphId = glyphId;
      } else if (startCharCode == -1) {
        // Start a new segment
        startCharCode = charCode;
        startGlyphId = glyphId;
      }

      prevCharCode = charCode;
    }

    // Closing the last segment
    if (startCharCode != -1 && prevCharCode != -1) {
      segmentList.add(_Segment(startCharCode, prevCharCode, startGlyphId));
    }

    return segmentList;
  }

  @override
  ByteData encodeToBinary() {
    // TODO: implement encode
    throw UnimplementedError();
  }

  @override
  // TODO: implement size
  int get size => throw UnimplementedError(); 
}