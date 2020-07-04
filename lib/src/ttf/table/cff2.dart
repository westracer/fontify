import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/ttf.dart';
import '../cff/dict.dart';
import '../cff/index.dart';
import '../cff/operator.dart' as op;
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
  int topDictLength;

  @override
  void encodeToBinary(ByteData byteData) {
    byteData
      ..setUint8(0, majorVersion)
      ..setUint8(1, minorVersion)
      ..setUint8(2, headerSize)
      ..setUint16(3, topDictLength);
  }

  @override
  int get size => _kHeaderSize;
}

class CFF2Table extends FontTable {
  CFF2Table(
    TableRecordEntry entry,
    this.header,
    this.topDict,
    this.globalSubrsData,
    this.charStringsData,
    this.vstoreData,
    this.fontDictList,
    this.privateDictList,
    this.localSubrsDataList,
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

    final globalSubrsData = CFFIndexWithData<Uint8List>.fromByteData(byteData.sublistView(fixedOffset));
    fixedOffset += globalSubrsData.index.size;

    /// CharStrings INDEX
    final charStringsIndexEntry = topDict.getEntryForOperator(op.charStrings);
    final charStringsIndexOffset = charStringsIndexEntry.operandList.first.value as int;
    final charStringsIndexByteData = byteData.sublistView(entry.offset + charStringsIndexOffset);

    final charStringsData = CFFIndexWithData<Uint8List>.fromByteData(charStringsIndexByteData);
    // TODO: charStrings interpretation

    /// VariationStore
    final vstoreEntry = topDict.getEntryForOperator(op.vstore);
    VariationStoreData vstoreData;

    if (vstoreEntry != null) {
      final vstoreOffset = vstoreEntry.operandList.first.value as int;
      final vstoreByteData = byteData.sublistView(entry.offset + vstoreOffset);
      vstoreData = VariationStoreData.fromByteData(vstoreByteData);
    }

    /// TODO: decode FDSelect later - it's optional and not needed now

    /// Font DICT INDEX
    final fdArrayEntry = topDict.getEntryForOperator(op.fdArray);
    final fdArrayOffset = fdArrayEntry.operandList.first.value as int;
    
    final fontIndexByteData = byteData.sublistView(entry.offset + fdArrayOffset);

    /// List of Font DICT	
    final fontDictList = CFFIndexWithData<CFFDict>.fromByteData(fontIndexByteData);

    /// Private DICT list
    final privateDictList = <CFFDict>[];

    /// Local subroutines for each Private DICT
    final localSubrsDataList = <CFFIndexWithData<Uint8List>>[];

    for (int i = 0; i < fontDictList.index.count; i++) {
      final privateEntry = fontDictList.data[i].getEntryForOperator(op.private);
      final dictOffset = entry.offset + (privateEntry.operandList.last.value as int);
      final dictLength = privateEntry.operandList.first.value as int;
      final dictByteData = byteData.sublistView(dictOffset, dictLength);

      final dict = CFFDict.fromByteData(dictByteData);
      privateDictList.add(dict);

      final localSubrEntry = dict.getEntryForOperator(op.subrs);
      
      /// Offset from the start of the Private DICT
      final localSubrOffset = localSubrEntry.operandList.first.value as int;

      final localSubrByteData = byteData.sublistView(dictOffset + localSubrOffset);
      final localSubrsData = CFFIndexWithData<Uint8List>.fromByteData(localSubrByteData);

      localSubrsDataList.add(localSubrsData);
    }

    return CFF2Table(
      entry,
      header,
      topDict,
      globalSubrsData,
      charStringsData,
      vstoreData,
      fontDictList,
      privateDictList,
      localSubrsDataList
    );
  }

  factory CFF2Table.create() {
    return null;
  }

  final CFF2TableHeader header;
  final CFFDict topDict;
  final CFFIndexWithData<Uint8List> globalSubrsData;
  final CFFIndexWithData<Uint8List> charStringsData;
  final VariationStoreData vstoreData;
  final CFFIndexWithData<CFFDict> fontDictList;
  final List<CFFDict> privateDictList;
  final List<CFFIndexWithData<Uint8List>> localSubrsDataList;

  void _generateTopDictEntries() {
    final entryList = <CFFDictEntry>[
      CFFDictEntry([], op.charStrings),
      if (vstoreData != null)
        CFFDictEntry([], op.vstore),
      CFFDictEntry([], op.fdArray),
      /// TODO: encode FDSelect later - it's optional and not needed now
    ];

    topDict.entryList.replaceRange(0, entryList.length, entryList);
  }

  @override
  void encodeToBinary(ByteData byteData) {
    _generateTopDictEntries();

    int offset = 0;

    header
      ..topDictLength = topDict.size
      ..encodeToBinary(byteData.sublistView(offset, header.size));
    offset += header.size;

    topDict.encodeToBinary(byteData.sublistView(offset, topDict.size));
    offset += topDict.size;

    globalSubrsData.encodeToBinary(byteData);
    offset += globalSubrsData.size;

    // TODO: implement
  }

  @override
  int get size => header.size + topDict.size + globalSubrsData.size;
}