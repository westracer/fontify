import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import '../utils/enum_class.dart';
import '../utils/logger.dart';
import 'formatter.dart';

const _kDefaultConfigPathList = ['pubspec.yaml', 'fontify.yaml'];
const _kPositionalArguments = [CliArgument.svgDir, CliArgument.fontFile];

const _kArgAllowedTypes = <CliArgument, List<Type>>{
  CliArgument.svgDir: [String],
  CliArgument.fontFile: [String],
  CliArgument.classFile: [String],
  CliArgument.className: [String],
  CliArgument.fontPackage: [String],
  CliArgument.indent: [String, int],
  CliArgument.fontName: [String],
  CliArgument.normalize: [bool],
  CliArgument.ignoreShapes: [bool],
  CliArgument.recursive: [bool],
  CliArgument.verbose: [bool],
  CliArgument.help: [bool],
  CliArgument.configFile: [String],
  CliArgument.variableNameCase: [String]
};

const kDefaultVerbose = false;
const kDefaultRecursive = false;

const kOptionNames = EnumClass<CliArgument, String>({
  // svgDir and fontFile are not options

  CliArgument.classFile: 'output-class-file',
  CliArgument.className: 'class-name',
  CliArgument.indent: 'indent',
  CliArgument.fontPackage: 'package',

  CliArgument.fontName: 'font-name',
  CliArgument.normalize: 'normalize',
  CliArgument.ignoreShapes: 'ignore-shapes',

  CliArgument.recursive: 'recursive',
  CliArgument.verbose: 'verbose',
  CliArgument.variableNameCase: 'variable-name-case',

  CliArgument.help: 'help',
  CliArgument.configFile: 'config-file',
});

const kConfigKeys = EnumClass<CliArgument, String>({
  CliArgument.svgDir: 'input_svg_dir',
  CliArgument.fontFile: 'output_font_file',

  CliArgument.classFile: 'output_class_file',
  CliArgument.className: 'class_name',
  CliArgument.indent: 'indent',
  CliArgument.fontPackage: 'package',

  CliArgument.fontName: 'font_name',
  CliArgument.normalize: 'normalize',
  CliArgument.ignoreShapes: 'ignore_shapes',
  CliArgument.variableNameCase: 'variable_name_case',

  CliArgument.recursive: 'recursive',
  CliArgument.verbose: 'verbose',

  // help and configFile are not part of config
});

final Map<CliArgument, String> argumentNames = {
  ...kConfigKeys.map,
  ...kOptionNames.map,
};

enum CliArgument {
  // Required
  svgDir,
  fontFile,

  // Class-related
  classFile,
  className,
  indent,
  fontPackage,

  // Font-related
  fontName,
  ignoreShapes,
  normalize,

  // Others
  recursive,
  verbose,
  variableNameCase,

  // Only in CLI
  help,
  configFile,
}

/// Contains all the parsed data for the application.
class CliArguments {
  CliArguments(
    this.svgDir,
    this.fontFile,
    this.classFile,
    this.className,
    this.indent,
    this.fontPackage,
    this.fontName,
    this.recursive,
    this.ignoreShapes,
    this.normalize,
    this.verbose,
    this.configFile,
    this.variableNameCase,
  );

  /// Creates [CliArguments] for a map of raw values.
  ///
  /// Validates type of each argument and formats them.
  ///
  /// Throws [CliArgumentException], if there is an error in arg parsing
  /// or if argument has wrong type.
  factory CliArguments.fromMap(Map<CliArgument, dynamic> map) {
    return CliArguments(
      map[CliArgument.svgDir] as Directory,
      map[CliArgument.fontFile] as File,
      map[CliArgument.classFile] as File?,
      map[CliArgument.className] as String?,
      map[CliArgument.indent] as int?,
      map[CliArgument.fontPackage] as String?,
      map[CliArgument.fontName] as String?,
      map[CliArgument.recursive] as bool?,
      map[CliArgument.ignoreShapes] as bool?,
      map[CliArgument.normalize] as bool?,
      map[CliArgument.verbose] as bool?,
      map[CliArgument.configFile] as File?,
      map[CliArgument.variableNameCase] as String?,
    );
  }

  final Directory svgDir;
  final File fontFile;
  final File? classFile;
  final String? className;
  final String? fontPackage;
  final int? indent;
  final String? fontName;
  final bool? recursive;
  final bool? ignoreShapes;
  final bool? normalize;
  final bool? verbose;
  final File? configFile;
  final String? variableNameCase;
}

/// Parses argument list.
///
/// Throws [CliHelpException], if 'help' option is present.
///
/// Returns an instance of [CliArguments] containing all parsed data.
Map<CliArgument, dynamic> parseArguments(ArgParser argParser, List<String> args) {
  late final ArgResults argResults;
  try {
    argResults = argParser.parse(args);
  } on FormatException catch (err) {
    throw CliArgumentException(err.message);
  }

  if (argResults['help'] as bool) {
    throw CliHelpException();
  }

  final posArgsLength = math.min(_kPositionalArguments.length, argResults.rest.length);

  final rawArgMap = <CliArgument, dynamic>{
    for (final e in kOptionNames.entries) e.key: argResults[e.value],
    for (var i = 0; i < posArgsLength; i++) _kPositionalArguments[i]: argResults.rest[i],
  };

  return rawArgMap;
}

MapEntry<CliArgument, dynamic>? _mapConfigKeyEntry(
  MapEntry<dynamic, dynamic> e,
) {
  final dynamic rawKey = e.key;
  void logUnknown() => logger.w('Unknown config parameter "$rawKey"');

  if (rawKey is! String) {
    logUnknown();
    return null;
  }

  final key = kConfigKeys.getKeyForValue(rawKey);
  if (key == null) {
    logUnknown();
    return null;
  }

  return MapEntry<CliArgument, dynamic>(key, e.value);
}

/// Parses config file.
///
/// Returns an instance of [CliArguments] containing all parsed data or null,
/// if 'fontify' key is not present in config file.
Map<CliArgument, dynamic>? parseConfig(String config) {
  final dynamic yamlMap = loadYaml(config);

  if (yamlMap is! YamlMap) {
    return null;
  }

  final dynamic fontifyYamlMap = yamlMap['fontify'];

  if (fontifyYamlMap is! YamlMap) {
    return null;
  }

  final entries = fontifyYamlMap.entries.map(_mapConfigKeyEntry).whereType<MapEntry<CliArgument, dynamic>>();

  return Map<CliArgument, dynamic>.fromEntries(entries);
}

/// Parses argument list and config file, validates parsed data.
/// Config is used, if it contains 'fontify' section.
///
/// Throws [CliHelpException], if 'help' option is present.
/// Throws [CliArgumentException], if there is an error in arg parsing.
CliArguments parseArgsAndConfig(ArgParser argParser, List<String> args) {
  var parsedArgs = parseArguments(argParser, args);
  final dynamic configFile = parsedArgs[CliArgument.configFile];

  final configList = <String>[if (configFile is String) configFile, ..._kDefaultConfigPathList].map((e) => File(e));

  for (final configFile in configList) {
    if (configFile.existsSync()) {
      final parsedConfig = parseConfig(configFile.readAsStringSync());

      if (parsedConfig != null) {
        logger.i('Using config ${configFile.path}');
        parsedArgs = parsedConfig;
        break;
      }
    }
  }

  return CliArguments.fromMap(parsedArgs.validateAndFormat());
}

class CliArgumentException implements Exception {
  CliArgumentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CliHelpException implements Exception {}

extension CliArgumentMapExtension on Map<CliArgument, dynamic> {
  /// Validates raw CLI arguments.
  ///
  /// Throws [CliArgumentException], if argument is not valid.
  void _validateRaw() {
    // Validating types
    for (final e in _kArgAllowedTypes.entries) {
      final arg = e.key;
      final argType = this[arg].runtimeType;
      final allowedTypes = e.value;

      if (argType != Null && !allowedTypes.contains(argType)) {
        throw CliArgumentException("'${argumentNames[arg]}' argument\'s type "
            'must be one of following: $allowedTypes, '
            "instead got '$argType'.");
      }
    }
  }

  /// Validates formatted CLI arguments.
  ///
  /// Throws [CliArgumentException], if argument is not valid.
  void _validateFormatted() {
    final args = this;

    final svgDir = args[CliArgument.svgDir] as Directory?;
    final fontFile = args[CliArgument.fontFile] as File?;
    final indent = args[CliArgument.indent] as int?;

    if (svgDir == null) {
      throw CliArgumentException('The input directory is not specified.');
    }

    if (fontFile == null) {
      throw CliArgumentException('The output font file is not specified.');
    }

    if (svgDir.statSync().type != FileSystemEntityType.directory) {
      throw CliArgumentException("The input directory is not a directory or it doesn't exist.");
    }

    if (indent != null && indent < 0) {
      throw CliArgumentException('indent must be a non-negative integer, was $indent.');
    }
  }

  /// Validates and formats CLI arguments.
  ///
  /// Throws [CliArgumentException], if argument is not valid.
  Map<CliArgument, dynamic> validateAndFormat() {
    _validateRaw();
    return formatArguments(this).._validateFormatted();
  }
}

// Ignoring as CLI arguments are dynamically typed
// ignore_for_file: avoid_annotating_with_dynamic
