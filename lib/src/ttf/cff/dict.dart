import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/exception.dart';
import 'operand.dart';

const _kOperatorEscapeByte = 0x0C;

class CFFDictEntry extends BinaryCodable {
  CFFDictEntry(this.operandList, this.operatorValue);

  factory CFFDictEntry.fromByteData(ByteData byteData, int startOffset) {
    final operandList = <CFFOperand>[];
    int operatorValue;

    int offset = startOffset;

    while (offset < byteData.lengthInBytes) {
      final b0 = byteData.getUint8(offset++);

      if (b0 < 28) {
        /// Reading an operator (b0 is not in operand range)
        operatorValue = b0;

        if (b0 == _kOperatorEscapeByte) {
          /// An operator is 2-byte long
          operatorValue = (b0 << 8) | byteData.getUint8(offset++);
        }

        return CFFDictEntry(operandList, operatorValue);
      } else {
        final operand = CFFOperand.fromByteData(byteData, offset, b0);
        operandList.add(operand);
        offset += operand.size - 1;
      }
    }
    
    throw TableDataFormatException('No operator for CFF dict entry');
  }

  final int operatorValue;
  final List<CFFOperand> operandList;

  int get _operatorSize => operatorValue.bitLength == 16 ? 2 : 1;

  @override
  void encodeToBinary(ByteData byteData) {
    // TODO: implement encodeToBinary
  }

  @override
  int get size => _operatorSize + operandList.fold<int>(0, (p, e) => p + e.size);
}

class CFFDict extends BinaryCodable {
  CFFDict(this.entryList);

  factory CFFDict.fromByteData(ByteData byteData) {
    final entryList = <CFFDictEntry>[];

    int offset = 0;

    while (offset < byteData.lengthInBytes) {
      final entry = CFFDictEntry.fromByteData(byteData, offset);
      entryList.add(entry);
      offset += entry.size;
    }

    return CFFDict(entryList);
  }

  final List<CFFDictEntry> entryList;

  @override
  void encodeToBinary(ByteData byteData) {
    // TODO: implement encodeToBinary
  }

  @override
  int get size => throw UnimplementedError();
}