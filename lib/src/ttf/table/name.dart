import 'dart:typed_data';

import '../../utils/exception.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const kNameRecordSize = 12;

const _kFormat0 = 0x0;

const _kPlatformMacintosh = 1;
const _kPlatformWindows = 3;

const _kEncodingUnicode10 = 0;
const _kEncodingUnicode11 = 1;

const _kMacintoshLanguageID = 0;

class NameRecord {
  NameRecord(
    this.platformID,
    this.encodingID,
    this.languageID,
    this.nameID,
    this.length,
    this.offset,
  );

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
}

class NamingTableHeader {
  NamingTableHeader(
    this.format,
    this.count,
    this.stringOffset,
    this.nameRecordList,
  );

  factory NamingTableHeader.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    final format = byteData.getUint16(entry.offset);

    if (format != _kFormat0) {
      throw UnsupportedTableVersionException(entry.tag, format);
    }

    final count = byteData.getUint16(entry.offset + 2);
    final stringOffset = byteData.getUint16(entry.offset + 4);
    final nameRecord = List.generate(
      count, 
      (i) => NameRecord.fromByteData(byteData, entry.offset + 6 + i * kNameRecordSize)
    );

    return NamingTableHeader(format, count, stringOffset, nameRecord);
  }

  // Format 0
  final int format;
  final int count;
  final int stringOffset;
  final List<NameRecord> nameRecordList;

  int get size => 6 + nameRecordList.length * kNameRecordSize;
}

class NamingTable extends FontTable {
  NamingTable(
    TableRecordEntry entry,
    this.header,
    this.stringList,
  ) : super.fromTableRecordEntry(entry);

  factory NamingTable.fromByteData(ByteData byteData, TableRecordEntry entry) {
    final header = NamingTableHeader.fromByteData(byteData, entry);
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
    
    return NamingTable(entry, header, stringList);
  }

  final NamingTableHeader header;
  final List<String> stringList;
}