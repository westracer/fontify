import 'dart:typed_data';

import '../../utils/ttf.dart';
import '../debugger.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const _kVersion0 = 0x0000;
const _kVersion1 = 0x0001;
const _kVersion4 = 0x0004;
const _kVersion5 = 0x0005;

/// Byte size for fields added with specific version
const _kVersionDataSize = {
  _kVersion0: 78,
  _kVersion1: 8,
  _kVersion4: 10,
  _kVersion5: 4,
};

class OS2Table extends FontTable {
  OS2Table._(
    TableRecordEntry entry,
    this.version,
    this.xAvgCharWidth,
    this.usWeightClass,
    this.usWidthClass,
    this.fsType,
    this.ySubscriptXSize,
    this.ySubscriptYSize,
    this.ySubscriptXOffset,
    this.ySubscriptYOffset,
    this.ySuperscriptXSize,
    this.ySuperscriptYSize,
    this.ySuperscriptXOffset,
    this.ySuperscriptYOffset,
    this.yStrikeoutSize,
    this.yStrikeoutPosition,
    this.sFamilyClass,
    this.panose,
    this.ulUnicodeRange1,
    this.ulUnicodeRange2,
    this.ulUnicodeRange3,
    this.ulUnicodeRange4,
    this.achVendID,
    this.fsSelection,
    this.usFirstCharIndex,
    this.usLastCharIndex,
    this.sTypoAscender,
    this.sTypoDescender,
    this.sTypoLineGap,
    this.usWinAscent,
    this.usWinDescent,
    this.ulCodePageRange1,
    this.ulCodePageRange2,
    this.sxHeight,
    this.sCapHeight,
    this.usDefaultChar,
    this.usBreakChar,
    this.usMaxContext,
    this.usLowerOpticalPointSize,
    this.usUpperOpticalPointSize,
  ) : super.fromTableRecordEntry(entry);

  factory OS2Table.fromByteData(ByteData byteData, TableRecordEntry entry) {
    final version = byteData.getInt16(entry.offset);

    final isV1 = version >= _kVersion1;
    final isV4 = version >= _kVersion4;
    final isV5 = version >= _kVersion5;

    if (version > _kVersion5) {
      TTFDebugger.debugUnsupportedTableVersion(kOS2Tag, version);
    }

    return OS2Table._(
      entry,
      version,
      byteData.getInt16(entry.offset + 2),
      byteData.getUint16(entry.offset + 4),
      byteData.getUint16(entry.offset + 6),
      byteData.getUint16(entry.offset + 8),
      byteData.getInt16(entry.offset + 10),
      byteData.getInt16(entry.offset + 12),
      byteData.getInt16(entry.offset + 14),
      byteData.getInt16(entry.offset + 16),
      byteData.getInt16(entry.offset + 18),
      byteData.getInt16(entry.offset + 20),
      byteData.getInt16(entry.offset + 22),
      byteData.getInt16(entry.offset + 24),
      byteData.getInt16(entry.offset + 26),
      byteData.getInt16(entry.offset + 28),
      byteData.getInt16(entry.offset + 30),
      List.generate(10, (i) => byteData.getUint8(entry.offset + 32 + i)),
      byteData.getUint32(entry.offset + 42),
      byteData.getUint32(entry.offset + 46),
      byteData.getUint32(entry.offset + 50),
      byteData.getUint32(entry.offset + 54),
      convertTagToString(Uint8List.view(byteData.buffer, entry.offset + 58, 4)),
      byteData.getUint16(entry.offset + 62),
      byteData.getUint16(entry.offset + 64),
      byteData.getUint16(entry.offset + 66),
      byteData.getInt16(entry.offset + 68),
      byteData.getInt16(entry.offset + 70),
      byteData.getInt16(entry.offset + 72),
      byteData.getUint16(entry.offset + 74),
      byteData.getUint16(entry.offset + 76),

      !isV1 ? null : byteData.getUint32(entry.offset + 78),
      !isV1 ? null : byteData.getUint32(entry.offset + 82),

      !isV4 ? null : byteData.getInt16(entry.offset + 86),
      !isV4 ? null : byteData.getInt16(entry.offset + 88),
      !isV4 ? null : byteData.getUint16(entry.offset + 90),
      !isV4 ? null : byteData.getUint16(entry.offset + 92),
      !isV4 ? null : byteData.getUint16(entry.offset + 94),

      !isV5 ? null : byteData.getUint16(entry.offset + 96),
      !isV5 ? null : byteData.getUint16(entry.offset + 98),
    );
  }

  final int version;

  // Version 0
  final int xAvgCharWidth;
  final int usWeightClass;
  final int usWidthClass;
  final int fsType;
  final int ySubscriptXSize;
  final int ySubscriptYSize;
  final int ySubscriptXOffset;
  final int ySubscriptYOffset;
  final int ySuperscriptXSize;
  final int ySuperscriptYSize;
  final int ySuperscriptXOffset;
  final int ySuperscriptYOffset;
  final int yStrikeoutSize;
  final int yStrikeoutPosition;
  final int sFamilyClass;
  final List<int> panose;
  final int ulUnicodeRange1;
  final int ulUnicodeRange2;
  final int ulUnicodeRange3;
  final int ulUnicodeRange4;
  final String achVendID;
  final int fsSelection;
  final int usFirstCharIndex;
  final int usLastCharIndex;
  final int sTypoAscender;
  final int sTypoDescender;
  final int sTypoLineGap;
  final int usWinAscent;
  final int usWinDescent;

  // Version 1
  final int ulCodePageRange1;
  final int ulCodePageRange2;

  // Version 4
  final int sxHeight;
  final int sCapHeight;
  final int usDefaultChar;
  final int usBreakChar;
  final int usMaxContext;

  // Version 5
  final int usLowerOpticalPointSize;
  final int usUpperOpticalPointSize;

  int get size {
    int size = 0;
    
    for (final e in _kVersionDataSize.entries) {
      if (e.key > version) {
        break;
      }

      size += e.value;
    }

    return size;
  }
}