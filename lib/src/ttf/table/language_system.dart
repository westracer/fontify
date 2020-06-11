import 'dart:typed_data';

import '../../utils/ttf.dart' as ttf_utils;

const kLangSysRecordSize = 6;

class LanguageSystemRecord {
  LanguageSystemRecord(
    this.langSysTag,
    this.langSysOffset
  );

  factory LanguageSystemRecord.fromByteData(ByteData byteData, int offset) {
    return LanguageSystemRecord(
      ttf_utils.convertTagToString(Uint8List.view(byteData.buffer, offset, 4)),
      byteData.getUint16(offset + 4),
    );
  }

  final String langSysTag;
  final int langSysOffset;
}

class LanguageSystemTable {
  LanguageSystemTable(
    this.lookupOrder, 
    this.requiredFeatureIndex, 
    this.featureIndexCount, 
    this.featureIndices,
  );

  factory LanguageSystemTable.fromByteData(
    ByteData byteData,
    int offset
  ) {
    final featureIndexCount = byteData.getUint16(offset + 4);
    final featureIndices = List.generate(
      featureIndexCount, 
      (i) => byteData.getUint16(offset + 6 + 2 * i)
    );

    return LanguageSystemTable(
      byteData.getUint16(offset),
      byteData.getUint16(offset + 2),
      featureIndexCount,
      featureIndices
    );
  }

  final int lookupOrder;
  final int requiredFeatureIndex;
  final int featureIndexCount;
  final List<int> featureIndices;
}