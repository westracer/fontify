import 'dart:io';

import 'ttf/reader.dart';
import 'ttf/table/all.dart';
import 'ttf/ttf.dart';

Future<void> main() async {
  final font = TTFReader(File('./test_assets/test_font.ttf')).read();

  final glyphNameList = (font.post.data as PostScriptVersion20).glyphNames.map((s) => s.string).toList();
  final newFont = TrueTypeFont.fromGlyphs(
    glyphList: font.glyf.glyphList, 
    glyphNameList: glyphNameList,
    fontName: 'TestFont',
  );
}