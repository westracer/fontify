import 'package:recase/recase.dart';
import 'package:path/path.dart' as p;

import '../common/constant.dart';

const _kUnnamedIconName = 'unnamed';
const _kDefaultIndent = '  ';
const _kDefaultFamilyName = 'FontifyFont';
const _kDefaultClassName = 'FontifyIcons';

/// Removes any characters that are not valid for variable name.
/// 
/// Returns a new string.
String _getVarName(String string) {
  final replaced = string.replaceAll(RegExp(r'[^a-zA-Z0-9_$]'), '');
  return RegExp(r'^[a-zA-Z$].*').firstMatch(replaced)?.group(0) ?? '';
}

// A helper for generating Flutter-compatible class with IconData objects for each icon.
class FlutterClassGenerator {
  /// * [iconMap] contains charcode to file name mapping.
  /// * [indent] is a indent for class' members. Defaults to two spaces.
  FlutterClassGenerator(
    this._fontFileName,
    String className,
    String familyName,
    Map<int, String> iconMap, {
      String indent
  }) 
  : _indent = indent ?? _kDefaultIndent,
    _className = _getVarName(className) ?? _kDefaultClassName,
    _familyName = familyName ?? _kDefaultFamilyName,
    _iconOriginalNames = iconMap,
    _iconVarNames = _generateVariableNames(iconMap);

  final String _fontFileName;
  final String _className;
  final String _familyName;
  final String _indent;
  final Map<int, String> _iconOriginalNames;
  final Map<int, String> _iconVarNames;

  static Map<int, String> _generateVariableNames(Map<int, String> iconOriginalNames) {
    final iconNameSet = <String>{};

    return iconOriginalNames.map((charCode, iconName) {
      final baseName = _getVarName(p.basenameWithoutExtension(iconName)).snakeCase;
      final usingDefaultName = baseName.isEmpty;

      String variableName = usingDefaultName ? _kUnnamedIconName : baseName;
      
      // Handling same names by adding numeration to them
      if (iconNameSet.contains(variableName)) {
        // If name already contains numeration, then splitting it
        final countMatch = RegExp(r'^(.*)_([0-9]+)$').firstMatch(variableName);

        int variableNameCount = 1;
        String variableWithoutCount = variableName;

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

      return MapEntry(charCode, variableName);
    });
  }

  String get _fontFamilyConst => "static const _kFontFamily = '$_familyName';";

  List<String> _generateIconConst(int index) {
    final charCode = _iconVarNames.keys.elementAt(index);
    final hexCode = charCode.toRadixString(16);
    final varName = _iconVarNames[charCode];
    final iconName = _iconOriginalNames[charCode];

    return [
      '',
      '/// $iconName',
      'static const IconData $varName = IconData(0x$hexCode, fontFamily: _kFontFamily);'
    ];
  }

  String generate() {
    final classContent = [
      '$_className._();',
      '',
      _fontFamilyConst,
      for (int i = 0; i < _iconVarNames.length; i++)
        ..._generateIconConst(i),
    ];

    final classContentString = classContent.map((e) => '$_indent$e').join('\n');

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
/// the $_familyName font is included in your application. This font is used to
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