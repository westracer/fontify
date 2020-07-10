import 'dart:io';

import 'common/generic_glyph.dart';
import 'otf/otf.dart';
import 'otf/reader.dart';
import 'otf/table/all.dart';
import 'otf/writer.dart';

void main(List<String> args) {
  final font = OTFReader.fromFile(File('./test_assets/test_font.ttf')).read();
  
  final glyphNameList = [...(font.post.data as PostScriptVersion20).glyphNames.map((s) => s.string).toList()]..removeAt(0);
  final glyphList = ([...font.glyf.glyphList]..removeAt(0)).map((e) => GenericGlyph.fromSimpleTrueTypeGlyph(e)).toList();
  
  final newFontCFF2 = OpenTypeFont.createFromGlyphs(
    glyphList: glyphList, 
    glyphNameList: glyphNameList,
    fontName: 'TestFont',
    achVendID: 'TEST',
    useCFF2: true,
  );

  final newFontTTF = OpenTypeFont.createFromGlyphs(
    glyphList: glyphList, 
    glyphNameList: glyphNameList,
    fontName: 'TestFont',
    achVendID: 'TEST',
    useCFF2: false,
  );

  OTFWriter.fromFile(File('./generated_font.otf')).write(newFontCFF2);
  OTFWriter.fromFile(File('./generated_font.ttf')).write(newFontTTF);
}