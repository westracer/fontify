import 'dart:io';
import 'dart:typed_data';

import '../utils/ttf.dart' as ttf_utils;

import 'table/abstract.dart';
import 'table/head.dart';
import 'table/maxp.dart';
import 'table/offset.dart';
import 'table/table_record_entry.dart';

class TrueTypeFont {
  TrueTypeFont._(this.offsetTable, this.tableMap);

  factory TrueTypeFont.fromFile(File file) {
    // TODO: handle exceptions
    final byteData = ByteData.view(file.readAsBytesSync().buffer);

    final offsetTable = OffsetTable.fromByteData(byteData);

    final entryMap = <String, TableRecordEntry>{};
    int offset = _readTableRecordEntries(byteData, offsetTable.numTables, entryMap);

    final tableMap = _readTables(byteData, entryMap);

    return TrueTypeFont._(offsetTable, tableMap);
  }

  static int _readTableRecordEntries(
    ByteData byteData, 
    int numTables, 
    Map<String, TableRecordEntry> outputMap
  ) {
    int offset = kOffsetTableLength;

    for (int i = 0; i < numTables; i++) {
      final entry = TableRecordEntry.fromByteData(byteData, offset);
      outputMap[entry.tag] = entry;

      offset += kTableRecordEntryLength;
    }

    return offset;
  }

  static Map<String, FontTable> _readTables(
    ByteData byteData,
    Map<String, TableRecordEntry> entryMap
  ) {
    return {
      for (final tag in entryMap.keys)
        tag: _createTableFromEntry(byteData, entryMap[tag])
    };
  }
  
  static FontTable _createTableFromEntry(ByteData data, TableRecordEntry entry) {
    switch (entry.tag) {
      case ttf_utils.kHeadTag:
        return HeaderTable.fromByteData(data, entry);
      case ttf_utils.kMaxpTag:
        return MaximumProfileTable.fromByteData(data, entry);
      default:
        print('Unsupported table: ${entry.tag}');
        return null;
    }
  }
  
  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;
}