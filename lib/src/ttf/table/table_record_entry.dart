import 'dart:typed_data';

import '../../utils/ttf.dart' as ttf_utils;

const kTableRecordEntryLength = 16;

class TableRecordEntry {
  TableRecordEntry(this.tag, this.checkSum, this.offset, this.length);

  factory TableRecordEntry.fromByteData(ByteData data, int entryOffset) =>
    TableRecordEntry(
      ttf_utils.convertTagToString(Uint8List.view(data.buffer, entryOffset, 4)), 
      data.getUint32(entryOffset + 4), 
      data.getUint32(entryOffset + 4 + 4), 
      data.getUint32(entryOffset + 4 + 8)
    );

  final String tag;
  final int offset;
  final int checkSum;
  final int length;
}