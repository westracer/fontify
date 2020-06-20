import 'dart:io';
import 'dart:typed_data';

import '../utils/ttf.dart';

import 'debugger.dart';
import 'table/all.dart';
import 'ttf.dart';

class TTFReader {
  TTFReader(File file) 
    : _byteData = ByteData.view(file.readAsBytesSync().buffer);

  final ByteData _byteData;

  OffsetTable _offsetTable;
  TrueTypeFont _font;

  /// Tables by tags
  final _tableMap = <String, FontTable>{};

  /// Ordered set of table tags to parse first
  final _tagsParseOrder = <String>{
    kHeadTag, kMaxpTag, kLocaTag, kHheaTag
  };
  
  int get _indexToLocFormat => _font.head.indexToLocFormat;
  int get numGlyphs => _font.maxp.numGlyphs;

  /// Reads an OpenType font file and returns [TrueTypeFont] instance
  TrueTypeFont read() {
    _tableMap.clear();

    final entryMap = <String, TableRecordEntry>{};

    _offsetTable = OffsetTable.fromByteData(_byteData);
    _font = TrueTypeFont(_offsetTable, _tableMap);

    _readTableRecordEntries(entryMap);
    _readTables(entryMap);

    return _font;
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
      case kHeadTag:
        return HeaderTable.fromByteData(_byteData, entry);
      case kMaxpTag:
        return MaximumProfileTable.fromByteData(_byteData, entry);
      case kLocaTag:
        return IndexToLocationTable.fromByteData(_byteData, entry, _indexToLocFormat, numGlyphs);
      case kGlyfTag:
        return GlyphDataTable.fromByteData(_byteData, entry, _font.loca, numGlyphs);
      case kGSUBTag:
        return GlyphSubstitutionTable.fromByteData(_byteData, entry);
      case kOS2Tag:
        return OS2Table.fromByteData(_byteData, entry);
      case kPostTag:
        return PostScriptTable.fromByteData(_byteData, entry);
      case kNameTag:
        return NamingTable.fromByteData(_byteData, entry);
      case kCmapTag:
        return CharacterToGlyphTable.fromByteData(_byteData, entry);
      case kHheaTag:
        return HorizontalHeaderTable.fromByteData(_byteData, entry);
      case kHmtxTag:
        return HorizontalMetricsTable.fromByteData(_byteData, entry, _font.hhea, numGlyphs);
      default:
        TTFDebugger.debugUnsupportedTable(entry.tag);
        return null;
    }
  }
}