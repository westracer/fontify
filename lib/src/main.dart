import 'dart:io';

import 'ttf/reader.dart';
import 'ttf/table/all.dart';
import 'ttf/ttf.dart';

import 'utils/ttf.dart' as ttf_utils;

Future<void> main() async {
  final TrueTypeFont ttf = TTFReader(File('./test_assets/test_font.ttf')).read();
  TrueTypeFont.fromGlyphs((ttf.tableMap[ttf_utils.kGlyfTag] as GlyphDataTable).glyphList);
}