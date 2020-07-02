import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/ttf.dart';
import '../cff/dict.dart';
import '../cff/index.dart';
import '../cff/operator.dart';
import '../cff/variations.dart';
import 'abstract.dart';
import 'table_record_entry.dart';

const _kHeaderSize = 5;

class CFF2TableHeader implements BinaryCodable {
  CFF2TableHeader(
    this.majorVersion,
    this.minorVersion,
    this.headerSize,
    this.topDictLength
  );

  factory CFF2TableHeader.fromByteData(ByteData byteData) {
    return CFF2TableHeader(
      byteData.getUint8(0),
      byteData.getUint8(1),
      byteData.getUint8(2),
      byteData.getUint16(3),
    );
  }

  final int majorVersion;
  final int minorVersion;
  final int headerSize;
  final int topDictLength;

  @override
  void encodeToBinary(ByteData byteData) {
    // TODO: implement encodeToBinary
    throw UnimplementedError();
  }

  @override
  int get size => _kHeaderSize;
}

class CFF2Table extends FontTable {
  CFF2Table(
    TableRecordEntry entry,
    this.header,
  ) : super.fromTableRecordEntry(entry);

  factory CFF2Table.fromByteData(
    ByteData byteData,
    TableRecordEntry entry,
  ) {
    /// 3 entries with fixed location
    int fixedOffset = entry.offset;

    final header = CFF2TableHeader.fromByteData(byteData.sublistView(fixedOffset, _kHeaderSize));
    fixedOffset += _kHeaderSize;

    final topDict = CFFDict.fromByteData(byteData.sublistView(fixedOffset, header.topDictLength));
    fixedOffset += header.topDictLength;

    final globalSubrIndex = CFFIndex.fromByteData(byteData.sublistView(fixedOffset));
    fixedOffset += globalSubrIndex.size;

    /// CharStrings INDEX
    final charStringsIndexEntry = topDict.getEntryForOperator(charStrings);
    final charStringsIndexOffset = charStringsIndexEntry.operandList.first.value as int;
    final charStringsIndexByteData = byteData.sublistView(entry.offset + charStringsIndexOffset);
    final charStringsIndex = CFFIndex.fromByteData(charStringsIndexByteData);

    // TODO: charStrings interpretation

    /// VariationStore
    final vstoreEntry = topDict.getEntryForOperator(vstore);
    VariationStoreData vstoreData;

    if (vstoreEntry != null) {
      final vstoreOffset = vstoreEntry.operandList.first.value as int;
      final vstoreByteData = byteData.sublistView(entry.offset + vstoreOffset);
      vstoreData = VariationStoreData.fromByteData(vstoreByteData);
    }

    /// TODO: decode FDSelect later - it's optional and not needed now

    /// Font DICT INDEX
    final fdArrayEntry = topDict.getEntryForOperator(fdArray);
    final fdArrayOffset = fdArrayEntry.operandList.first.value as int;
    
    final fontIndexByteData = byteData.sublistView(entry.offset + fdArrayOffset);
    final fontIndex = CFFIndex.fromByteData(fontIndexByteData);

    /// List of Font DICT	
    final fontDictList = _readIndexWithData(fontIndexByteData, (bd) => CFFDict.fromByteData(bd));

    /// Private DICT list
    final privateDictList = <CFFDict>[];

    /// Local subroutines for each Private DICT
    final localSubrs = <List<List<int>>>[];

    for (int i = 0; i < fontIndex.count; i++) {
      final privateEntry = fontDictList[i].getEntryForOperator(private);
      final dictOffset = entry.offset + (privateEntry.operandList.last.value as int);
      final dictLength = privateEntry.operandList.first.value as int;
      final dictByteData = byteData.sublistView(dictOffset, dictLength);

      final dict = CFFDict.fromByteData(dictByteData);
      privateDictList.add(dict);

      final localSubrEntry = dict.getEntryForOperator(subrs);
      
      /// Offset from the start of the Private DICT
      final localSubrOffset = localSubrEntry.operandList.first.value as int;

      final localSubrByteData = byteData.sublistView(dictOffset + localSubrOffset);
      final localSubrsData = _readIndexWithData(
        localSubrByteData,
        (bd) => bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes).toList()
      );

      localSubrs.add(localSubrsData);
    }

    return CFF2Table(entry, header);
  }

  factory CFF2Table.create() {
    return null;
  }

  final CFF2TableHeader header;

  @override
  void encodeToBinary(ByteData byteData) {
  }

  @override
  int get size => throw UnimplementedError();
}

List<T> _readIndexWithData<T>(ByteData byteData, T Function(ByteData) decoder) {
  final index = CFFIndex.fromByteData(byteData);
  final indexSize = index.size;

  final dataList = <T>[];

  for (int i = 0; i < index.count; i++) {
    final relativeOffset = index.offsetList[i] - 1; // -1 because first offset value is always 1
    final elementLength = index.offsetList[i + 1] - index.offsetList[i];

    final fontDictByteData = byteData.sublistView(
      indexSize + relativeOffset,
      elementLength
    );

    dataList.add(decoder(fontDictByteData));
  }

  return dataList;
}