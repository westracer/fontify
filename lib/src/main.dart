import 'dart:io';
import 'dart:typed_data';

import 'common/generic_glyph.dart';
import 'ttf/reader.dart';
import 'ttf/table/all.dart';
import 'ttf/ttf.dart';
import 'ttf/writer.dart';

void main(List<String> args) {
  final font = TTFReader.fromFile(File('./test_assets/test_font.ttf')).read();
  
  final glyphNameList = (font.post.data as PostScriptVersion20).glyphNames.map((s) => s.string).toList();
  final glyphList = ([...font.glyf.glyphList]..removeAt(0)).map((e) => GenericGlyph.fromSimpleTrueTypeGlyph(e)).toList();

  final newFont = TrueTypeFont.createFromGlyphs(
    glyphList: glyphList, 
    glyphNameList: [...glyphNameList]..removeAt(0),
    fontName: 'TestFont',
    achVendID: 'TEST',
    useCFF2: true,
  );
  
  final newFontData = ByteData(newFont.size);
  newFont.encodeToBinary(newFontData);
  TTFWriter.fromFile(File('./generated_font.otf')).write(newFont);
}