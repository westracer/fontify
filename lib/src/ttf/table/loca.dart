import 'dart:typed_data';

import 'abstract.dart';
import 'table_record_entry.dart';

class IndexToLocationTable extends FontTable {
  IndexToLocationTable(
    TableRecordEntry entry,
    this.glyphOffsets,
    this._isShort,
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
          ? byteData.getUint16(entry.offset + 2 * i) * 2
          : byteData.getUint32(entry.offset + 4 * i)
    ];

    return IndexToLocationTable(entry, offsets, isShort);
  }

  factory IndexToLocationTable.create(
    int indexToLocFormat,
    int numGlyphs
  ) {
    final isShort = indexToLocFormat == 0;
    final List<int> offsets = List.generate(numGlyphs + 1, (index) => null);

    return IndexToLocationTable(null, offsets, isShort);
  }

  final List<int> glyphOffsets;
  final bool _isShort;

  @override
  ByteData encodeToBinary() {
    // TODO: implement encode
    throw UnimplementedError();
  }

  @override
  int get size => glyphOffsets.length * (_isShort ? 2 : 4);
}