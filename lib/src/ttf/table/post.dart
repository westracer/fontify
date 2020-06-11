import 'dart:typed_data';

import '../../utils/pascal_string.dart';
import '../../utils/ttf.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const _kFormat2 = 0x2;
const _kHeaderSize = 32;

class PostScriptTableHeader {
  PostScriptTableHeader(
    this.version,
    this.italicAngle,
    this.underlinePosition,
    this.underlineThickness,
    this.isFixedPitch,
    this.minMemType42,
    this.maxMemType42,
    this.minMemType1,
    this.maxMemType1,
  );

  factory PostScriptTableHeader.fromByteData(
    ByteData byteData,
    TableRecordEntry entry
  ) {
    final version = byteData.getFixed(entry.offset);

    return PostScriptTableHeader(
      version,
      byteData.getFixed(entry.offset + 4),
      byteData.getFWord(entry.offset + 8),
      byteData.getFWord(entry.offset + 10),
      byteData.getUint32(entry.offset + 12),
      byteData.getUint32(entry.offset + 16),
      byteData.getUint32(entry.offset + 20),
      byteData.getUint32(entry.offset + 24),
      byteData.getUint32(entry.offset + 28),
    );
  }

  final int version;
  final int italicAngle;
  final int underlinePosition;
  final int underlineThickness;
  final int isFixedPitch;
  final int minMemType42;
  final int maxMemType42;
  final int minMemType1;
  final int maxMemType1;

  bool get isV2 => version == _kFormat2;
}

abstract class PostScriptFormatData {}

class PostScriptFormat20 extends PostScriptFormatData {
  PostScriptFormat20(
    this.numberOfGlyphs, 
    this.glyphNameIndex, 
    this.glyphNames
  );

  factory PostScriptFormat20.fromByteData(
    ByteData byteData,
    int offset
  ) {
    final numberOfGlyphs = byteData.getUint16(offset);
    offset += 2;

    final glyphNameIndex = List.generate(
      numberOfGlyphs,
      (i) => byteData.getUint16(offset + i * 2)
    );
    offset += numberOfGlyphs * 2;

    final glyphNames = List.generate(
      numberOfGlyphs,
      (i) {
        final string = PascalString.fromByteData(byteData, offset);
        offset += string.size;
        return string;
      }
    );

    return PostScriptFormat20(
      numberOfGlyphs,
      glyphNameIndex,
      glyphNames
    );
  }

  final int numberOfGlyphs;
  final List<int> glyphNameIndex;
  final List<PascalString> glyphNames;
}

class PostScriptTable extends FontTable {
  PostScriptTable(
    TableRecordEntry entry,
    this.header,
    this.data
  ) : super.fromTableRecordEntry(entry);

  factory PostScriptTable.fromByteData(
    ByteData byteData,
    TableRecordEntry entry
  ) {
    final header = PostScriptTableHeader.fromByteData(byteData, entry);

    return PostScriptTable(
      entry, 
      header,
      header.isV2 
        ? PostScriptFormat20.fromByteData(byteData, entry.offset + _kHeaderSize) 
        : null
    );
  }

  final PostScriptTableHeader header;
  final PostScriptFormatData data;
}