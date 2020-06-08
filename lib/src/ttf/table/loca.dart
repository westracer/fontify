import 'dart:typed_data';

import 'abstract.dart';
import 'table_record_entry.dart';

class IndexToLocationTable extends FontTable {
  IndexToLocationTable(
    TableRecordEntry entry,
    this.offsets,
  ) : super.fromTableRecordEntry(entry);

  factory IndexToLocationTable.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry, 
    int indexToLocFormat,
    int numGlyphs
  ) {
    final isShort = indexToLocFormat == 0;

    final offsets = <int>[
      for (int i = 0; i < numGlyphs + 1; i++)
        isShort 
          ? byteData.getUint16(entry.offset + 2 * i) 
          : byteData.getUint32(entry.offset + 4 * i)
    ];

    return IndexToLocationTable(entry, offsets);
  }

  final List<int> offsets;
}