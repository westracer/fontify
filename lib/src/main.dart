import 'dart:io';

import 'ttf/reader.dart';
import 'ttf/table/all.dart';
import 'ttf/ttf.dart';

void main(List<String> args) {
  final font = TTFReader.fromFile(File('./test_assets/test_font.ttf')).read();

  final glyphNameList = (font.post.data as PostScriptVersion20).glyphNames.map((s) => s.string).toList();
  final newFont = TrueTypeFont.createFromGlyphs(
    glyphList: font.glyf.glyphList, 
    glyphNameList: glyphNameList,
    fontName: 'TestFont',
    achVendID: 'TEST',
  );
}