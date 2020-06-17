import 'dart:io';

import 'ttf/parser.dart';
import 'ttf/table/all.dart';
import 'ttf/ttf.dart';

import 'utils/ttf.dart' as ttf_utils;

Future<void> main() async {
  final TrueTypeFont ttf = TTFReader(File('./test_assets/test_font.ttf')).parse();
  TrueTypeFont.fromGlyphs((ttf.tableMap[ttf_utils.kGlyfTag] as GlyphDataTable).glyphList);
}