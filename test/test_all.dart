import 'package:test/test.dart';

import 'svg_test.dart' as svg;
import 'ttf_test.dart' as ttf;

void main() {
  group('TTF', ttf.main);
  group('SVG', svg.main);
}