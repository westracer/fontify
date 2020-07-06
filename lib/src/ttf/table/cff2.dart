import 'dart:typed_data';

import '../../common/calculatable_offsets.dart';
import '../../common/codable/binary.dart';
import '../../utils/ttf.dart';
import '../cff/dict.dart';
import '../cff/index.dart';
import '../cff/operand.dart';
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

class CFF2Table extends FontTable implements CalculatableOffsets {
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

    // TODO: decode FDSelect later - it's optional and not needed now

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
      CFFDictEntry([CFFOperand.fromValue(0)], op.charStrings),
      if (vstoreData != null)
        CFFDictEntry([CFFOperand.fromValue(0)], op.vstore),
      CFFDictEntry([CFFOperand.fromValue(0)], op.fdArray),
      /// TODO: encode FDSelect later - it's optional and not needed now
    ];

    topDict.entryList = entryList;
  }

  void _recalculateTopDictOffsets() {
    // Generating entries with zero-values
    _generateTopDictEntries();

    int offset = header.size + globalSubrsData.size + topDict.size;

    int vstoreOffset;
    if (vstoreData != null) {
      vstoreOffset = offset;
      offset += vstoreData.size;
    }

    final charStringsOffset = offset;
    offset += charStringsData.size;

    final fdArrayOffset = offset;
    offset += fontDictList.size;

    final vstoreEntry = topDict.getEntryForOperator(op.vstore);
    final charStringsEntry = topDict.getEntryForOperator(op.charStrings);
    final fdArrayEntry = topDict.getEntryForOperator(op.fdArray);

    final offsetList = [
      if (vstoreData != null)
        vstoreOffset,
      charStringsOffset,
      fdArrayOffset,
    ];

    final entryList = [
      if (vstoreEntry != null)
        vstoreEntry,
      charStringsEntry,
      fdArrayEntry,
    ];

    _calculateEntryOffsets(entryList, offsetList, 0);
  }

  @override
  void recalculateOffsets() {
    _recalculateTopDictOffsets();
    
    header.topDictLength = topDict.size;
    
    globalSubrsData.recalculateOffsets();

    // Recalculating font DICTs private offsets and SUBRS entries offsets
    final fdArrayEntry = topDict.getEntryForOperator(op.fdArray);
    final fdArrayOffset = fdArrayEntry.operandList.first.value as int;
    
    int fontDictOffset = fdArrayOffset + fontDictList.index.size;

    for (int i = 0; i < fontDictList.data.length; i++) {
      final fontDict = fontDictList.data[i];
      final privateDict = privateDictList[i];
      final privateEntry = fontDict.getEntryForOperator(op.private);

      final newOperands = [CFFOperand.fromValue(privateDict.size), CFFOperand.fromValue(0)];
      privateEntry.operandList.replaceRange(0, 2, newOperands);
      fontDictOffset += fontDict.size;

      final subrsEntry = privateDict.getEntryForOperator(op.subrs);
      subrsEntry.operandList.replaceRange(0, 1, [CFFOperand.fromValue(0)]);

      _calculateEntryOffsets([privateEntry], [fontDictOffset], 1);
      subrsEntry.recalculatePointers(0, () => privateDict.size);
    }

    // Recalculating local subrs
    for (final localSubrs in localSubrsDataList) {
      localSubrs.recalculateOffsets();
    }
  }

  @override
  void encodeToBinary(ByteData byteData) {
    int offset = 0;

    header.encodeToBinary(byteData.sublistView(offset, header.size));
    offset += header.size;

    final topDictSize = topDict.size;
    topDict.encodeToBinary(byteData.sublistView(offset, topDictSize));
    offset += topDictSize;

    final globalSubrsSize = globalSubrsData.size;
    globalSubrsData.encodeToBinary(byteData.sublistView(offset, globalSubrsSize));
    offset += globalSubrsSize;
    
    if (vstoreData != null) {
      final vstoreSize = vstoreData.size;
      vstoreData.encodeToBinary(byteData.sublistView(offset, vstoreSize));
      offset += vstoreSize;
    }

    final charStringsSize = charStringsData.size;
    charStringsData.encodeToBinary(byteData.sublistView(offset, charStringsSize));
    offset += charStringsSize;

    final fontDictListSize = fontDictList.size;
    fontDictList.encodeToBinary(byteData.sublistView(offset, fontDictListSize));
    offset += fontDictListSize;

    for (int i = 0; i < fontDictList.data.length; i++) {
      final privateDict = privateDictList[i];
      final privateDictSize = privateDict.size;

      privateDict.encodeToBinary(byteData.sublistView(offset, privateDictSize));
      offset += privateDictSize;
    }

    for (final localSubrs in localSubrsDataList) {
      final localSubrsSize = localSubrs.size;
      localSubrs.encodeToBinary(byteData.sublistView(offset, localSubrsSize));
      offset += localSubrsSize;
    }
  }

  int get _privateDictListSize => privateDictList.fold(0, (p, d) => p + d.size);

  int get _localSubrsListSize => localSubrsDataList.fold(0, (p, d) => p + d.size);

  @override
  int get size =>
    header.size + 
    topDict.size + 
    globalSubrsData.size + 
    (vstoreData?.size ?? 0) + 
    charStringsData.size + 
    fontDictList.size +
    _privateDictListSize + 
    _localSubrsListSize;

  static void _calculateEntryOffsets(
    List<CFFDictEntry> entryList,
    List<int> offsetList,
    int operandIndex,
  ) {
    bool sizeChanged;

    /// Iterating and changing offsets while operand size is changing
    /// A bit dirty, maybe there's easier way to do that
    do {
      sizeChanged = false;

      for (int i = 0; i < entryList.length; i++) {
        final entry = entryList[i];
        final oldOperand = entry.operandList[operandIndex];
        final newOperand = CFFOperand.fromValue(offsetList[i]);

        final sizeDiff = newOperand.size - oldOperand.size;

        if (oldOperand.value != newOperand.value) {
          entry.operandList.replaceRange(operandIndex, operandIndex + 1, [newOperand]);
        }
        
        if (sizeDiff > 0) {
          sizeChanged = true;

          for (int i = 0; i < offsetList.length; i++) {
            offsetList[i] += sizeDiff;
          }
        }
      }
    } while (sizeChanged);
  }
}