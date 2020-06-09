import 'dart:io';

import 'ttf/parser.dart';

Future<void> main() async {
  final ttf = TTFParser(File('./test_assets/test_font.ttf')).parse();
}