import 'dart:typed_data';

class PascalString {
  PascalString(this.string, this.length);

  factory PascalString.fromByteData(ByteData byteData, int offset) {
    final length = byteData.getUint8(offset++);
    final bytes = List.generate(length, (i) => byteData.getUint8(offset + i));
    return PascalString(String.fromCharCodes(bytes), length);
  }

  factory PascalString.fromString(String string) => 
    PascalString(string, string.length);

  final String string;
  final int length;

  int get size => length + 1;

  @override
  String toString() => string;
}