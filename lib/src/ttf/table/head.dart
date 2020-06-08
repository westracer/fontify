import 'dart:typed_data';

import '../../utils/ttf.dart' as ttf_utils;

import 'abstract.dart';
import 'table_record_entry.dart';

const _kMagicNumber = 0x5F0F3CF5;

class HeaderTable extends FontTable {
  HeaderTable(
    TableRecordEntry entry,
    this.fontRevision, 
    this.checkSumAdjustment,
    this.flags,
    this.unitsPerEm,
    this.created,
    this.modified,
    this.xMin,
    this.yMin,
    this.xMax,
    this.yMax,
    this.macStyle,
    this.lowestRecPPEM,
    this.indexToLocFormat,
    this.glyphDataFormat
  ) : 
    majorVersion = 1,
    minorVersion = 0,
    fontDirectionHint = 2,
    magicNumber = _kMagicNumber,
    super.fromTableRecordEntry(entry);

  factory HeaderTable.fromByteData(ByteData data, TableRecordEntry entry) => 
    HeaderTable(
      entry,
      data.getInt32(entry.offset + 4),
      data.getUint32(entry.offset + 8),
      data.getUint32(entry.offset + 12),
      data.getUint16(entry.offset + 18),
      ttf_utils.getDateTime(data.getInt64(entry.offset + 20)),
      ttf_utils.getDateTime(data.getInt64(entry.offset + 28)),
      data.getInt16(entry.offset + 36),
      data.getInt16(entry.offset + 38),
      data.getInt16(entry.offset + 40),
      data.getInt16(entry.offset + 42),
      data.getUint16(entry.offset + 44),
      data.getUint16(entry.offset + 46),
      data.getInt16(entry.offset + 50),
      data.getInt16(entry.offset + 52),
    );

  final int majorVersion;
  final int minorVersion;
  final int fontRevision;
  final int checkSumAdjustment;
  final int magicNumber;
  final int flags;
  final int unitsPerEm;
  final DateTime created;
  final DateTime modified;
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;
  final int macStyle;
  final int lowestRecPPEM;
  final int fontDirectionHint;
  final int indexToLocFormat;
  final int glyphDataFormat;
}