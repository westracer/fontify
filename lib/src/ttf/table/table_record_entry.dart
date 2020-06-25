import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/ttf.dart';

const kTableRecordEntryLength = 16;

class TableRecordEntry implements BinaryCodable {
  TableRecordEntry(this.tag, this.checkSum, this.offset, this.length);

  factory TableRecordEntry.fromByteData(ByteData data, int entryOffset) =>
    TableRecordEntry(
      convertTagToString(Uint8List.view(data.buffer, entryOffset, 4)), 
      data.getUint32(entryOffset + 4), 
      data.getUint32(entryOffset + 4 + 4), 
      data.getUint32(entryOffset + 4 + 8)
    );

  final String tag;
  final int offset;
  final int checkSum;
  final int length;

  @override
  int get size => kTableRecordEntryLength;

  @override
  void encodeToBinary(ByteData byteData, int offset) {
    byteData
      ..setTag(offset, tag)
      ..setUint32(offset + 4, this.offset)
      ..setUint32(offset + 8, checkSum)
      ..setUint32(offset + 12, length);
  }
}