import 'package:recase/recase.dart';
import 'package:path/path.dart' as p;

import '../common/constant.dart';
import '../common/generic_glyph.dart';
import '../otf/defaults.dart';

const _kUnnamedIconName = 'unnamed';
const _kDefaultIndent = 2;
const _kDefaultClassName = 'FontifyIcons';
const _kDefaultFontFileName = 'fontify_icons.otf';

/// Removes any characters that are not valid for variable name.
/// 
/// Returns a new string.
String _getVarName(String string) {
  final replaced = string.replaceAll(RegExp(r'[^a-zA-Z0-9_$]'), '');
  return RegExp(r'^[a-zA-Z$].*').firstMatch(replaced)?.group(0) ?? '';
}

/// A helper for generating Flutter-compatible class with IconData objects for each icon.
class FlutterClassGenerator {
  /// * [glyphList] is a list of non-default glyphs.
  /// * [className] is generated class' name (preferably, in PascalCase).
  /// * [familyName] is font's family name to use in IconData.
  /// * [fontFileName] is font file's name. Used in generated docs for class.
  /// * [indent] is a number of spaces in leading indentation for class' members. Defaults to 2.
  FlutterClassGenerator(
    this.glyphList, {
      String className,
      String familyName,
      String fontFileName,
      int indent,
  }) 
  : _indent = ' ' * (indent ?? _kDefaultIndent),
    _className = _getVarName(className ?? _kDefaultClassName),
    _familyName = familyName ?? kDefaultFontFamily,
    _fontFileName = fontFileName ?? _kDefaultFontFileName,
    _iconVarNames = _generateVariableNames(glyphList);

  final List<GenericGlyph> glyphList;
  final String _fontFileName;
  final String _className;
  final String _familyName;
  final String _indent;
  final List<String> _iconVarNames;

  static List<String> _generateVariableNames(List<GenericGlyph> glyphList) {
    final iconNameSet = <String>{};

    return glyphList.map((g) {
      final baseName = _getVarName(p.basenameWithoutExtension(g.metadata.name)).snakeCase;
      final usingDefaultName = baseName.isEmpty;

      var variableName = usingDefaultName ? _kUnnamedIconName : baseName;
      
      // Handling same names by adding numeration to them
      if (iconNameSet.contains(variableName)) {
        // If name already contains numeration, then splitting it
        final countMatch = RegExp(r'^(.*)_([0-9]+)$').firstMatch(variableName);

        var variableNameCount = 1;
        var variableWithoutCount = variableName;

        if (countMatch != null) {
          variableNameCount = int.parse(countMatch.group(2));
          variableWithoutCount = countMatch.group(1);
        }

        String variableNameWithCount;

        do {
          variableNameWithCount = '${variableWithoutCount}_${++variableNameCount}';
        } while (iconNameSet.contains(variableNameWithCount));

        variableName = variableNameWithCount;
      }

      iconNameSet.add(variableName);

      return variableName;
    }).toList();
  }

  String get _fontFamilyConst => "static const _kFontFamily = '$_familyName';";

  List<String> _generateIconConst(int index) {
    final glyphMeta = glyphList[index].metadata;

    final charCode = glyphMeta.charCode;
    final iconName = glyphMeta.name;

    final varName = _iconVarNames[index];
    final hexCode = charCode.toRadixString(16);

    return [
      '',
      '/// $iconName',
      'static const IconData $varName = IconData(0x$hexCode, fontFamily: _kFontFamily);'
    ];
  }

  /// Generates content for a class' file.
  String generate() {
    final classContent = [
      '$_className._();',
      '',
      _fontFamilyConst,
      for (var i = 0; i < glyphList.length; i++)
        ..._generateIconConst(i),
    ];

    final classContentString = classContent.map((e) => e.isEmpty ? '' : '$_indent$e').join('\n');

    return 
'''
// Generated code: do not hand-edit.

// Generated using $kVendorName.
// Copyright © ${DateTime.now().year} $kVendorName ($kVendorUrl).

import 'package:flutter/widgets.dart';

/// Identifiers for the icons.
///
/// Use with the [Icon] class to show specific icons.
///
/// Icons are identified by their name as listed below.
///
/// To use this class, make sure you declare the font in your
/// project's `pubspec.yaml` file in the `fonts` section. This ensures that
/// the "$_familyName" font is included in your application. This font is used to
/// display the icons. For example:
/// 
/// ```yaml
/// flutter:
///   fonts:
///     - family: $_familyName
///       fonts:
///         - asset: fonts/$_fontFileName
/// ```
class $_className {
$classContentString
}
''';
  }
}