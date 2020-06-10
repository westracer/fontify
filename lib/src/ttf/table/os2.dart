import 'dart:typed_data';

import '../../utils/exception.dart';
import '../../utils/ttf.dart' as ttf_utils;

import 'abstract.dart';
import 'table_record_entry.dart';

const _kOS2V1 = 0x1;

class OS2TableV1 extends FontTable {
  OS2TableV1(
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
  ) : super.fromTableRecordEntry(entry);

  factory OS2TableV1.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry
  ) {
    final version = byteData.getUint16(entry.offset);

    if (version != _kOS2V1) {
      throw TableVersionException(entry.tag, version);
    }

    return OS2TableV1(
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
      ttf_utils.convertTag(Uint8List.view(byteData.buffer, entry.offset + 58, 4)),
      byteData.getUint16(entry.offset + 62),
      byteData.getUint16(entry.offset + 64),
      byteData.getUint16(entry.offset + 66),
      byteData.getInt16(entry.offset + 68),
      byteData.getInt16(entry.offset + 70),
      byteData.getInt16(entry.offset + 72),
      byteData.getUint16(entry.offset + 74),
      byteData.getUint16(entry.offset + 76),
      byteData.getUint32(entry.offset + 78),
      byteData.getUint32(entry.offset + 82),
    );
  }

  final int version;
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
  final int ulCodePageRange1;
  final int ulCodePageRange2;
}