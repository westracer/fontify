import 'dart:io';

import 'package:fontify/fontify.dart';

void main() {
  const fontFileName = 'fontify_icons.otf';
  const classFileName = 'fontify_icons.dart';

  // Input data
  final svgMap = {'icon': '<svg viewBox="0 0 0 0"></svg>'};

  // Generating font
  final svgToOtfResult = svgToOtf(
    svgMap: svgMap,
    fontName: 'My Icons',
  );

  // Writing font to a file
  writeToFile(fontFileName, svgToOtfResult.font);

  // Generating Flutter class
  final generatedClass = generateFlutterClass(
    glyphList: svgToOtfResult.glyphList,
    familyName: svgToOtfResult.font.familyName,
    className: 'MyIcons',
    fontFileName: fontFileName,
  );

  // Writing class content to a file
  File(classFileName).writeAsStringSync(generatedClass);
}