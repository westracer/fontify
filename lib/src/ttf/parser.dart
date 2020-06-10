import 'dart:io';
import 'dart:typed_data';

import '../utils/ttf.dart' as ttf_utils;

import 'table/all.dart';
import 'ttf.dart';

class TTFParser {
  TTFParser(File file) 
    : _byteData = ByteData.view(file.readAsBytesSync().buffer);

  final ByteData _byteData;

  OffsetTable _offsetTable;

  /// Tables by tags
  final _tableMap = <String, FontTable>{};

  /// Ordered set of table tags
  final _tagsParseOrder = <String>{ttf_utils.kHeadTag, ttf_utils.kMaxpTag, ttf_utils.kLocaTag};
  
  int get _indexToLocFormat => (_tableMap[ttf_utils.kHeadTag] as HeaderTable).indexToLocFormat;
  int get numGlyphs => (_tableMap[ttf_utils.kMaxpTag] as MaximumProfileTable).numGlyphs;

  TrueTypeFont parse() {
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
        return OS2TableV1.fromByteData(_byteData, entry);
      case ttf_utils.kPostTag:
        return PostScriptTable.fromByteData(_byteData, entry);
      default:
        print('Unsupported table: ${entry.tag}');
        return null;
    }
  }
}