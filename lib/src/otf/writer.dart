import 'dart:io';
import 'dart:typed_data';

import 'ttf.dart';

/// A helper for writing an OpenType font as a binary data
class TTFWriter {
  TTFWriter.fromFile(this._file);

  final File _file;

  // TODO: check extension and log otf/ttf warning
  /// Writes OpenType font as a binary data
  void write(TrueTypeFont font) {
    final byteData = ByteData(font.size);
    font.encodeToBinary(byteData);

    _file.writeAsBytesSync(byteData.buffer.asUint8List());
  }
}