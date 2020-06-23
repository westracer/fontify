import 'dart:typed_data';

import '../../common/constant.dart';
import '../../utils/enum_class.dart';
import '../../utils/exception.dart';
import '../../utils/ttf.dart';
import '../debugger.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const _kNameRecordSize = 12;

const _kFormat0 = 0x0;

enum _NameID {
  copyright, fontFamily, fontSubfamily, uniqueID, fullFontName,
  version, postScriptName, manufacturer, description, urlVendor,
}

const _kNameIDmap = EnumClass<_NameID, int>({
  _NameID.copyright: 0,
  _NameID.fontFamily: 1,
  _NameID.fontSubfamily: 2,
  _NameID.uniqueID: 3,
  _NameID.fullFontName: 4,
  _NameID.version: 5,
  _NameID.postScriptName: 6,
  _NameID.manufacturer: 8,
  _NameID.description: 10,
  _NameID.urlVendor: 11,
});

/// List of name record templates, sorted by platform and encoding ID
const _kNameRecordTemplateList = [
  /// Macintosh English with Roman encoding
  NameRecord.template(kPlatformMacintosh, 0, 0),

  /// Windows English (US) with UTF-16BE encoding
  NameRecord.template(kPlatformWindows, 0, 0x0409),
];

class NameRecord {
  const NameRecord(
    this.platformID,
    this.encodingID,
    this.languageID,
    this.nameID,
    this.length,
    this.offset,
  );

  const NameRecord.template(
    this.platformID,
    this.encodingID,
    this.languageID,
  ) : 
    nameID = null, 
    length = null, 
    offset = null;

  factory NameRecord.fromByteData(ByteData byteData, int offset) {
    final length = byteData.getUint16(offset + 8);
    final stringOffset = byteData.getUint16(offset + 10);

    return NameRecord(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      byteData.getUint16(offset + 4),
      byteData.getUint16(offset + 6),
      length,
      stringOffset,
    );
  }

  final int platformID;
  final int encodingID;
  final int languageID;
  final int nameID;
  final int length;
  final int offset;

  NameRecord copyWith({
    int platformID,
    int encodingID,
    int languageID,
    int nameID,
    int length,
    int offset,
  }) {
    return NameRecord(
      this.platformID ?? platformID,
      this.encodingID ?? encodingID,
      this.languageID ?? languageID,
      this.nameID ?? nameID,
      this.length ?? length,
      this.offset ?? offset
    );
  }

  int get size => _kNameRecordSize;
}

class NamingTableFormat0Header {
  NamingTableFormat0Header(
    this.format,
    this.count,
    this.stringOffset,
    this.nameRecordList,
  );

  factory NamingTableFormat0Header.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    final format = byteData.getUint16(entry.offset);

    if (format != _kFormat0) {
      TTFDebugger.debugUnsupportedTableFormat(entry.tag, format);
      return null;
    }

    final count = byteData.getUint16(entry.offset + 2);
    final stringOffset = byteData.getUint16(entry.offset + 4);
    final nameRecord = List.generate(
      count, 
      (i) => NameRecord.fromByteData(byteData, entry.offset + 6 + i * _kNameRecordSize)
    );

    return NamingTableFormat0Header(format, count, stringOffset, nameRecord);
  }

  final int format;
  final int count;
  final int stringOffset;
  final List<NameRecord> nameRecordList;

  int get size => 6 + nameRecordList.length * _kNameRecordSize;
}

abstract class NamingTable extends FontTable {
  NamingTable.fromTableRecordEntry(TableRecordEntry entry) :
    super.fromTableRecordEntry(entry);

  factory NamingTable.fromByteData(ByteData byteData, TableRecordEntry entry) {
    final format = byteData.getUint16(entry.offset);

    switch (format) {
      case _kFormat0:
        return NamingTableFormat0.fromByteData(byteData, entry);
      default:
        TTFDebugger.debugUnsupportedTableFormat(kNameTag, format);
        return null;
    }
  }

  factory NamingTable.create(
    String fontName,
    String description,
    Revision revision, {
      int format = _kFormat0
  }) {
    switch (format) {
      case _kFormat0:
        return NamingTableFormat0.create(fontName, description, revision);
      default:
        TTFDebugger.debugUnsupportedTableFormat(kNameTag, format);
        return null;
    }
  }
}

class NamingTableFormat0 extends NamingTable {
  NamingTableFormat0(
    TableRecordEntry entry,
    this.header,
    this.stringList,
  ) : super.fromTableRecordEntry(entry);

  factory NamingTableFormat0.fromByteData(ByteData byteData, TableRecordEntry entry) {
    final header = NamingTableFormat0Header.fromByteData(byteData, entry);
    final storageAreaOffset = entry.offset + header.size;

    final stringList = [
      for (final record in header.nameRecordList)
        String.fromCharCodes(
          List.generate(
            record.length, 
            (i) => byteData.getUint8(storageAreaOffset + record.offset + i)
          )
        )
    ];
    
    return NamingTableFormat0(entry, header, stringList);
  }

  factory NamingTableFormat0.create(String fontName, String description, Revision revision) {
    if (fontName?.isNotEmpty != true) {
      throw TableDataFormatException('Font name must be not empty');
    }

    final now = DateTime.now();

    final stringForNameMap = {
      _NameID.copyright: '$kVendorName © ${now.year}',
      _NameID.fontFamily: fontName,
      _NameID.fontSubfamily: 'Regular',
      _NameID.uniqueID: fontName,
      _NameID.fullFontName: fontName,
      _NameID.version: 'Version ${revision.major}.${revision.minor}',
      _NameID.manufacturer: kVendorName,
      _NameID.postScriptName: fontName.getAsciiPrintable(),
      _NameID.description: description ?? 'Generated using $kVendorName',
      _NameID.urlVendor: kVendorUrl,
    };

    final stringList = [
      for (int i = 0; i < _kNameRecordTemplateList.length; i++) 
        ...stringForNameMap.values
    ];

    final recordList = [
      for (final record in _kNameRecordTemplateList)
        for (final entry in stringForNameMap.entries)
          record.copyWith(
            nameID: _kNameIDmap.getValueForKey(entry.key),
            length: entry.value.length,
          )
    ];
    
    final header = NamingTableFormat0Header(
      0,
      recordList.length,
      null,
      recordList
    );

    return NamingTableFormat0(null, header, stringList);
  }

  final NamingTableFormat0Header header;
  final List<String> stringList;

  @override
  int get size => 
    header.size + header.nameRecordList.fold<int>(0, (p, r) => p + r.length);

  @override
  ByteData encodeToBinary() {
    // TODO: implement encode
    throw UnimplementedError();
  }
}