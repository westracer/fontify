import 'dart:io';
import 'dart:typed_data';

import 'ttf.dart';

class TTFWriter {
  TTFWriter.fromFile(this._file);

  final File _file;

  // TODO: extension otf/ttf warning
  void write(TrueTypeFont font) {
    final byteData = ByteData(font.size);
    font.encodeToBinary(byteData);

    _file.writeAsBytesSync(byteData.buffer.asUint8List());
  }
}