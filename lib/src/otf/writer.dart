import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../utils/logger.dart';
import 'otf.dart';

/// A helper for writing an OpenType font as a binary data
class OTFWriter {
  OTFWriter.fromFile(this._file) 
  : extension = p.extension(_file.path).toLowerCase();

  final File _file;
  final String extension;

  /// Writes OpenType font as a binary data
  void write(OpenTypeFont font) {
    final byteData = ByteData(font.size);
    font.encodeToBinary(byteData);

    if (extension != '.otf' && font.isOpenType) {
      logger.w('A font that contains only CFF outline data should have an .OTF extension.');
    }

    _file.writeAsBytesSync(byteData.buffer.asUint8List());
  }
}