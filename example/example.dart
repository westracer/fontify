import 'dart:io';

import 'package:fontify/fontify.dart';

void main() {
  const svgFileName = 'icon.svg';
  const fontFileName = 'fontify_icons.otf';
  const classFileName = 'fontify_icons.dart';

  // TODO: Encapsulate to function
  // Parsing SVG icon
  final svg = Svg.parse(svgFileName, '<svg viewBox="0 0 0 0"></svg>');

  // Converting parsed SVG to generic glyph
  final glyph = GenericGlyph.fromSvg(svg);

  // Creating OpenType font
  final font = OpenTypeFont.createFromGlyphs(
    glyphList: [glyph],
  );

  // Writing font to a file
  writeToFile(fontFileName, font);

  // Generating Flutter class
  // TODO:
  // final iconMap = {
  //   font.generatedCharCodeList.first: svgFileName,
  // };

  // final classGenerator = FlutterClassGenerator(iconMap);
  // final classFileContent = classGenerator.generate();

  // Writing Flutter class content
  // File(classFileName).writeAsStringSync(classFileContent);
}