import 'dart:io';
import 'dart:typed_data';

import '../utils/ttf.dart' as ttf_utils;

import 'table/abstract.dart';
import 'table/head.dart';
import 'table/loca.dart';
import 'table/maxp.dart';
import 'table/offset.dart';
import 'table/table_record_entry.dart';
import 'ttf.dart';

class TTFParser {
  TTFParser(File file) 
    : _byteData = ByteData.view(file.readAsBytesSync().buffer);

  final ByteData _byteData;

  OffsetTable _offsetTable;

  /// Tables by tags
  final _tableMap = <String, FontTable>{};

  /// Ordered set of table tags
  final _tags = <String>{ttf_utils.kHeadTag, ttf_utils.kMaxpTag};
  
  int get _indexToLocFormat => (_tableMap[ttf_utils.kHeadTag] as HeaderTable).indexToLocFormat;
  int get _numGlyphs => (_tableMap[ttf_utils.kMaxpTag] as MaximumProfileTable).numGlyphs;

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
      _tags.add(entry.tag);

      offset += kTableRecordEntryLength;
    }

    return offset;
  }

  void _readTables(Map<String, TableRecordEntry> entryMap) {
    for (final tag in _tags) {
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
        return IndexToLocationTable.fromByteData(_byteData, entry, _indexToLocFormat, _numGlyphs);
      default:
        print('Unsupported table: ${entry.tag}');
        return null;
    }
  }
}