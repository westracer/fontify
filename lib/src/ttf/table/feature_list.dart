import 'dart:typed_data';

import '../../utils/ttf.dart';

const kFeatureRecordSize = 6;

const _kDefaultFeatureRecordList = [
  FeatureRecord('liga', null),
];

const _kDefaultFeatureTableList = [
  FeatureTable(0, 1, [0]),
];

class FeatureRecord {
  const FeatureRecord(
    this.featureTag,
    this.featureOffset
  );

  factory FeatureRecord.fromByteData(ByteData byteData, int offset) {    
    return FeatureRecord(
      convertTagToString(Uint8List.view(byteData.buffer, offset, 4)),
      byteData.getUint16(offset + 4),
    );
  }

  final String featureTag;
  final int featureOffset;

  int get size => kFeatureRecordSize;
}

class FeatureTable {
  const FeatureTable(
    this.featureParams,
    this.lookupIndexCount,
    this.lookupListIndices
  );

  factory FeatureTable.fromByteData(
    ByteData byteData, 
    int offset,
    FeatureRecord record
  ) {
    offset += record.featureOffset;

    final lookupIndexCount = byteData.getUint16(offset + 2);
    final lookupListIndices = List.generate(
      lookupIndexCount, 
      (i) => byteData.getUint16(offset + 4 + i * 2)
    );
    
    return FeatureTable(
      byteData.getUint16(offset),
      lookupIndexCount,
      lookupListIndices
    );
  }

  final int featureParams;
  final int lookupIndexCount;
  final List<int> lookupListIndices;

  int get size => 4 + 2 * lookupIndexCount;
}

class FeatureListTable {
  FeatureListTable(
    this.featureCount,
    this.featureRecords,
    this.featureTables
  );

  factory FeatureListTable.fromByteData(ByteData byteData, int offset) {
    final featureCount = byteData.getUint16(offset);
    final featureRecords = List.generate(
      featureCount, 
      (i) => FeatureRecord.fromByteData(byteData, offset + 2 + kFeatureRecordSize * i)
    );
    final featureTables = List.generate(
      featureCount,
      (i) => FeatureTable.fromByteData(byteData, offset, featureRecords[i])
    );
    
    return FeatureListTable(featureCount, featureRecords, featureTables);
  }

  factory FeatureListTable.create() {
    return FeatureListTable(
      _kDefaultFeatureRecordList.length,
      _kDefaultFeatureRecordList,
      _kDefaultFeatureTableList
    );
  }

  final int featureCount;
  final List<FeatureRecord> featureRecords;

  final List<FeatureTable> featureTables;

  int get size {
    final recordListSize = featureRecords.fold<int>(0, (p, r) => p + r.size);
    final tableListSize = featureTables.fold<int>(0, (p, t) => p + t.size);

    return 2 + recordListSize + tableListSize;
  }
}