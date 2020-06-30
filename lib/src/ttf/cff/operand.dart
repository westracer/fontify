
import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/exception.dart';

const _kRealNumberTerminator = 0xF;

const _kStringForRealNumberByte = [
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
  '.', 'E', 'E-', '', '-', '',
];

class CFFOperand extends BinaryCodable {
  CFFOperand(this.value, this._size);

  factory CFFOperand.fromByteData(ByteData byteData, int offset, int b0) {
    /// -107 to +107
    int decodeOneByte() {
      return b0 - 139;
    }

    /// +108 to +1131
    int decodeTwoBytePositive() {
      final b1 = byteData.getUint8(offset++);

      return (b0 - 247) * 256 + b1 + 108;
    }

    /// -1131 to -108
    int decodeTwoByteNegative() {
      final b1 = byteData.getUint8(offset++);

      return -(b0 - 251) * 256 - b1 - 108;
    }

    /// -32768 to +32767
    int decodeThreeByte() {
      final b1 = byteData.getUint8(offset++);
      final b2 = byteData.getUint8(offset++);

      return b1 << 8 | b2;
    }
    
    /// -(2^31) to +(2^31 - 1)
    int decodeFiveByte() {
      final b1 = byteData.getUint8(offset++);
      final b2 = byteData.getUint8(offset++);
      final b3 = byteData.getUint8(offset++);
      final b4 = byteData.getUint8(offset++);

      return b1 << 24 | b2 << 16 | b3 << 8 | b4;
    }

    /// Real number
    double decodeRealNumber() {
      final sb = StringBuffer();
      
      // ignore: literal_only_boolean_expressions
      while (true) {
        final b = byteData.getUint8(offset++);

        final n1 = b >> 4;
        if (n1 == _kRealNumberTerminator) {
          break;
        }

        sb.write(_kStringForRealNumberByte[n1]);

        final n2 = b & 0xF;
        if (n2 == _kRealNumberTerminator) {
          break;
        }
        
        sb.write(_kStringForRealNumberByte[n2]);
      }

      return double.parse(sb.toString());
    }

    if (b0 == 28) {
      return CFFOperand(decodeThreeByte(), 3);
    } else if (b0 == 29) {
      return CFFOperand(decodeFiveByte(), 5);
    } else if (b0 == 30) {
      final currentOffset = offset;
      return CFFOperand(decodeRealNumber(), currentOffset - offset);
    } else if (b0 >= 32 && b0 <= 246) {
      return CFFOperand(decodeOneByte(), 1);
    } else if (b0 >= 247 && b0 <= 250) {
      return CFFOperand(decodeTwoBytePositive(), 2);
    } else if (b0 >= 251 && b0 <= 254) {
      return CFFOperand(decodeTwoByteNegative(), 2);
    } else {
      throw TableDataFormatException('Unknown operand type in CFF table (offset $offset)');
    }
  }

  /// Either real or integer number
  final num value;

  int _size;

  @override
  void encodeToBinary(ByteData byteData) {
    // TODO: implement encodeToBinary
  }

  @override
  int get size {
    if (_size != null) {
      return _size;
    }

    return _size = () {
      if (value is double) {
        return 1 + ((value.toString().length + 1) / 2).ceil();
      } else if (value >= -107 && value <= 107) {
        return 1;
      } else if (value >= 108 && value <= 1131 || value >= -1131 && value <= -108) {
        return 2;
      } else if (value >= -32768 && value <= 32767) {
        return 3;
      } else {
        return 5;
      }
    }();
  }
}