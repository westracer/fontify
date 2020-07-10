import 'dart:io';
import 'dart:typed_data';

import 'otf.dart';

/// A helper for writing an OpenType font as a binary data
class OTFWriter {
  OTFWriter.fromFile(this._file);

  final File _file;

  // TODO: check extension and log otf/ttf warning
  /// Writes OpenType font as a binary data
  void write(OpenTypeFont font) {
    final byteData = ByteData(font.size);
    font.encodeToBinary(byteData);

    _file.writeAsBytesSync(byteData.buffer.asUint8List());
  }
}