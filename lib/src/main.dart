import 'dart:io';

import 'common/generic_glyph.dart';
import 'ttf/reader.dart';
import 'ttf/table/all.dart';
import 'ttf/ttf.dart';
import 'ttf/writer.dart';

void main(List<String> args) {
  final font = TTFReader.fromFile(File('./test_assets/test_font.ttf')).read();
  
  final glyphNameList = [...(font.post.data as PostScriptVersion20).glyphNames.map((s) => s.string).toList()]..removeAt(0);
  final glyphList = ([...font.glyf.glyphList]..removeAt(0)).map((e) => GenericGlyph.fromSimpleTrueTypeGlyph(e)).toList();
  
  final newFontCFF2 = TrueTypeFont.createFromGlyphs(
    glyphList: glyphList, 
    glyphNameList: glyphNameList,
    fontName: 'TestFont',
    achVendID: 'TEST',
    useCFF2: true,
  );

  final newFontTTF = TrueTypeFont.createFromGlyphs(
    glyphList: glyphList, 
    glyphNameList: glyphNameList,
    fontName: 'TestFont',
    achVendID: 'TEST',
    useCFF2: false,
  );

  TTFWriter.fromFile(File('./generated_font.otf')).write(newFontCFF2);
  TTFWriter.fromFile(File('./generated_font.ttf')).write(newFontTTF);
}