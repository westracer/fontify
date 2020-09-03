import 'package:test/test.dart';

import 'cli_test.dart' as cli;
import 'normalize_test.dart' as norm;
import 'svg_test.dart' as svg;
import 'ttf_test.dart' as ttf;

void main() {
  group('TTF', ttf.main);
  group('SVG', svg.main);
  group('CLI', cli.main);
  group('Normalization', norm.main);
}