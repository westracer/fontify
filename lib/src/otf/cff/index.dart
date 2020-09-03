import 'dart:typed_data';

import '../../common/calculatable_offsets.dart';
import '../../common/codable/binary.dart';
import '../../utils/exception.dart';
import '../../utils/otf.dart';
import 'dict.dart';

const kEmptyIndexSize = 4;

class CFFIndex extends BinaryCodable {
  CFFIndex(this.count, this.offSize, this.offsetList);

  CFFIndex.empty()
      : count = 0,
        offSize = null,
        offsetList = [];

  factory CFFIndex.fromByteData(ByteData byteData) {
    var offset = 0;

    final count = byteData.getUint32(0);
    offset += 4;

    if (count == 0) {
      return CFFIndex.empty();
    }

    final offSize = byteData.getUint8(offset++);

    if (offSize < 1 || offSize > 4) {
      throw TableDataFormatException('Wrong offSize value');
    }

    final offsetList = <int>[];

    for (var i = 0; i < count + 1; i++) {
      var value = 0;

      for (var i = 0; i < offSize; i++) {
        value <<= 8;
        value += byteData.getUint8(offset++);
      }

      offsetList.add(value);
    }

    return CFFIndex(count, offSize, offsetList);
  }

  final int count;
  final int offSize;
  final List<int> offsetList;

  bool get isEmpty => count == 0;

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    byteData.setUint32(offset, count);
    offset += 4;

    if (isEmpty) {
      return;
    }

    byteData.setUint8(offset++, offSize);

    for (var i = 0; i < count + 1; i++) {
      for (var j = 0; j < offSize; j++) {
        final byte = (offsetList[i] >> 8 * (offSize - j - 1)) & 0xFF;
        byteData.setUint8(offset++, byte);
      }
    }
  }

  int get _offsetListSize => (count + 1) * offSize;

  @override
  int get size {
    var sizeSum = 4;

    if (isEmpty) {
      return kEmptyIndexSize;
    }

    return sizeSum += 1 + _offsetListSize;
  }
}

class CFFIndexWithData<T> implements BinaryCodable, CalculatableOffsets {
  CFFIndexWithData(this.index, this.data);

  /// Decodes INDEX and its data from [ByteData]
  factory CFFIndexWithData.fromByteData(ByteData byteData) {
    final decoder = _getDecoderForType(T);

    final index = CFFIndex.fromByteData(byteData);
    final indexSize = index.size;

    final dataList = <T>[];

    for (var i = 0; i < index.count; i++) {
      final relativeOffset =
          index.offsetList[i] - 1; // -1 because first offset value is always 1
      final elementLength = index.offsetList[i + 1] - index.offsetList[i];

      final fontDictByteData =
          byteData.sublistView(indexSize + relativeOffset, elementLength);

      dataList.add(decoder(fontDictByteData) as T);
    }

    return CFFIndexWithData(index, dataList);
  }

  factory CFFIndexWithData.create(List<T> data) => CFFIndexWithData(null, data);

  CFFIndex index;
  final List<T> data;

  static Object Function(ByteData) _getDecoderForType(Type type) {
    switch (type) {
      case Uint8List:
        return (bd) => Uint8List.fromList(
            bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes));
      case CFFDict:
        return (bd) => CFFDict.fromByteData(bd);
      default:
    }

    throw UnsupportedError('No decoder for type $type');
  }

  void Function(ByteData, T) _getEncoder() {
    switch (T) {
      case Uint8List:
        return (bd, list) => bd.setByteList(0, list as Uint8List);
      case CFFDict:
        return (bd, dict) => (dict as CFFDict).encodeToBinary(bd);
      default:
    }

    throw UnsupportedError('No encoder for type $T');
  }

  int Function(T) _getByteLengthCallback() {
    switch (T) {
      case Uint8List:
        return (list) => (list as Uint8List).lengthInBytes;
      case CFFDict:
        return (dict) => (dict as CFFDict).size;
      default:
    }

    throw UnsupportedError('No length callback for type $T');
  }

  @override
  void recalculateOffsets() {
    if (data.isEmpty) {
      index = CFFIndex.empty();
      return;
    }

    index = _calculateIndex();
  }

  // TODO: memoize: called three times when writing font - on creating ByteData for font, on creating sublistView and on calling encode
  CFFIndex _calculateIndex() {
    final lengthCallback = _getByteLengthCallback();

    final dataSizeList = data.map(lengthCallback).toList();

    /// Generating offset list starting with 1
    final offsetList = [1];

    for (final elementSize in dataSizeList) {
      offsetList.add(offsetList.last + elementSize);
    }

    /// Finding minimum offSize
    CFFIndex newIndex;
    int expectedOffSize = 0, actualOffSize;

    do {
      expectedOffSize++;
      newIndex = CFFIndex(data.length, expectedOffSize, offsetList);
      actualOffSize = (offsetList.last.bitLength / 8).ceil();
    } while (actualOffSize != expectedOffSize);

    if (actualOffSize > 4) {
      throw TableDataFormatException('INDEX offset overflow');
    }

    return newIndex;
  }

  @override
  int get size {
    if (data.isEmpty) {
      return kEmptyIndexSize;
    }

    final newIndex = _calculateIndex();

    return newIndex.size + newIndex.offsetList.last - 1;
  }

  @override
  void encodeToBinary(ByteData byteData) {
    if (data.isEmpty) {
      index.encodeToBinary(byteData.sublistView(0, index.size));
    }

    var offset = 0;

    final indexSize = index.size;

    index.encodeToBinary(byteData.sublistView(offset, indexSize));
    offset += indexSize;

    final encoder = _getEncoder();

    for (var i = 0; i < index.count; i++) {
      final element = data[i];
      final elementSize = index.offsetList[i + 1] - index.offsetList[i];

      encoder(byteData.sublistView(offset, elementSize), element);
      offset += elementSize;
    }
  }
}
