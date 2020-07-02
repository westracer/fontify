import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/exception.dart';

class CFFIndex extends BinaryCodable {
  CFFIndex(this.count, this.offSize, this.offsetList);

  CFFIndex.empty() : count = 0, offSize = null, offsetList = [];

  factory CFFIndex.fromByteData(ByteData byteData) {
    int offset = 0;

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

    for (int i = 0; i < count + 1; i++) {
      int value = 0;

      for (int i = 0; i < offSize; i++) {
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
    // TODO: implement encodeToBinary
  }

  int get _offsetListSize => (count + 1) * offSize;

  @override
  int get size {
    int sizeSum = 4;

    if (isEmpty) {
      return sizeSum;
    }

    return sizeSum += 1 + _offsetListSize;
  }
}