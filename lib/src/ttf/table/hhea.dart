import 'dart:typed_data';

import '../../utils/ttf.dart';

import 'abstract.dart';
import 'glyf.dart';
import 'head.dart';
import 'hmtx.dart';
import 'table_record_entry.dart';

const _kHheaTableSize = 36;

class HorizontalHeaderTable extends FontTable {
  HorizontalHeaderTable(
    TableRecordEntry entry,
    this.majorVersion,
    this.minorVersion,
    this.ascender,
    this.descender,
    this.lineGap,
    this.advanceWidthMax,
    this.minLeftSideBearing,
    this.minRightSideBearing,
    this.xMaxExtent,
    this.caretSlopeRise,
    this.caretSlopeRun,
    this.caretOffset,
    this.metricDataFormat,
    this.numberOfHMetrics,
  ) : super.fromTableRecordEntry(entry);

  factory HorizontalHeaderTable.fromByteData(ByteData byteData, TableRecordEntry entry) {
    return HorizontalHeaderTable(
      entry,
      byteData.getUint16(entry.offset),
      byteData.getUint16(entry.offset + 2),
      byteData.getFWord(entry.offset + 4),
      byteData.getFWord(entry.offset + 6),
      byteData.getFWord(entry.offset + 8),
      byteData.getUFWord(entry.offset + 10),
      byteData.getFWord(entry.offset + 12),
      byteData.getFWord(entry.offset + 14),
      byteData.getFWord(entry.offset + 16),
      byteData.getInt16(entry.offset + 18),
      byteData.getInt16(entry.offset + 20),
      byteData.getInt16(entry.offset + 22),
      byteData.getInt16(entry.offset + 32),
      byteData.getUint16(entry.offset + 34),
    );
  }

  factory HorizontalHeaderTable.create(
    GlyphDataTable glyf, 
    HorizontalMetricsTable hmtx,
    HeaderTable head
  ) {
    return HorizontalHeaderTable(
      null,
      1, // major version 1
      0, // minor version 0
      head.unitsPerEm,
      0,
      0, // 0 line gap
      hmtx.advanceWidthMax,
      hmtx.minLeftSideBearing,
      hmtx.getMinRightSideBearing(glyf),
      hmtx.getMaxExtent(glyf),
      1, // caretSlopeRise - vertical
      0, // caretSlopeRun - vertical
      0, // non-slanted font - no offset
      0, // 0 for current metric format
      glyf.glyphList.length
    );
  }

  final int majorVersion;
  final int minorVersion;
  final int	ascender;
  final int	descender;
  final int	lineGap;
  final int	advanceWidthMax;
  final int	minLeftSideBearing;
  final int	minRightSideBearing;
  final int	xMaxExtent;
  final int	caretSlopeRise;
  final int	caretSlopeRun;
  final int	caretOffset;
  
  final int	metricDataFormat;
  final int	numberOfHMetrics;

  int get size => _kHheaTableSize;
}