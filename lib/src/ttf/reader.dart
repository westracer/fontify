import 'dart:io';
import 'dart:typed_data';

import '../utils/ttf.dart' as ttf_utils;

import 'debugger.dart';
import 'table/all.dart';
import 'ttf.dart';

class TTFReader {
  TTFReader(File file) 
    : _byteData = ByteData.view(file.readAsBytesSync().buffer);

  final ByteData _byteData;

  OffsetTable _offsetTable;

  /// Tables by tags
  final _tableMap = <String, FontTable>{};

  /// Ordered set of table tags to parse first
  final _tagsParseOrder = <String>{
    ttf_utils.kHeadTag, ttf_utils.kMaxpTag, ttf_utils.kLocaTag, ttf_utils.kHheaTag
  };
  
  int get _indexToLocFormat => (_tableMap[ttf_utils.kHeadTag] as HeaderTable).indexToLocFormat;
  int get numGlyphs => (_tableMap[ttf_utils.kMaxpTag] as MaximumProfileTable).numGlyphs;

  /// Reads an OpenType font file and returns [TrueTypeFont] instance
  TrueTypeFont read() {
    final entryMap = <String, TableRecordEntry>{};

    _offsetTable = OffsetTable.fromByteData(_byteData);
    _readTableRecordEntries(entryMap);
    _readTables(entryMap);

    return TrueTypeFont(_offsetTable, _tableMap);
  }

  int _readTableRecordEntries(Map<String, TableRecordEntry> outputMap) {
    int offset = kOffsetTableLength;

    for (int i = 0; i < _offsetTable.numTables; i++) {
      final entry = TableRecordEntry.fromByteData(_byteData, offset);
      outputMap[entry.tag] = entry;
      _tagsParseOrder.add(entry.tag);

      offset += kTableRecordEntryLength;
    }

    return offset;
  }

  void _readTables(Map<String, TableRecordEntry> entryMap) {
    for (final tag in _tagsParseOrder) {
      _tableMap[tag] = _createTableFromEntry(entryMap[tag]);
    }
  }
  
  FontTable _createTableFromEntry(TableRecordEntry entry) {
    switch (entry.tag) {
      case ttf_utils.kHeadTag:
        return HeaderTable.fromByteData(_byteData, entry);
      case ttf_utils.kMaxpTag:
        return MaximumProfileTable.fromByteData(_byteData, entry);
      case ttf_utils.kLocaTag:
        return IndexToLocationTable.fromByteData(_byteData, entry, _indexToLocFormat, numGlyphs);
      case ttf_utils.kGlyfTag:
        final loca = _tableMap[ttf_utils.kLocaTag] as IndexToLocationTable;
        return GlyphDataTable.fromByteData(_byteData, entry, loca, numGlyphs);
      case ttf_utils.kGSUBTag:
        return GlyphSubstitutionTable.fromByteData(_byteData, entry);
      case ttf_utils.kOS2Tag:
        return OS2Table.fromByteData(_byteData, entry);
      case ttf_utils.kPostTag:
        return PostScriptTable.fromByteData(_byteData, entry);
      case ttf_utils.kNameTag:
        return NamingTable.fromByteData(_byteData, entry);
      case ttf_utils.kCmapTag:
        return CharacterToGlyphTable.fromByteData(_byteData, entry);
      case ttf_utils.kHheaTag:
        return HorizontalHeaderTable.fromByteData(_byteData, entry);
      case ttf_utils.kHmtxTag:
        final hhea = _tableMap[ttf_utils.kHheaTag] as HorizontalHeaderTable;
        return HorizontalMetricsTable.fromByteData(_byteData, entry, hhea, numGlyphs);
      default:
        TTFDebugger.debugUnsupportedTable(entry.tag);
        return null;
    }
  }
}