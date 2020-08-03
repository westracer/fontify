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

  CliArgument.classFile: [Null, String],
  CliArgument.className: [Null, String],
  CliArgument.indent: [Null, String, int],

  CliArgument.fontName: [Null, String],
  CliArgument.normalize: [Null, bool],
  CliArgument.ignoreShapes: [Null, bool],

  CliArgument.recursive: [Null, bool],
  CliArgument.verbose: [Null, bool],
  
  CliArgument.help: [Null, bool],
  CliArgument.configFile: [Null, String],
};

const kDefaultVerbose = false;
const kDefaultRecursive = false;

const kOptionNames = EnumClass<CliArgument, String>({
  // svgDir and fontFile are not options

  CliArgument.classFile: 'output-class-file',
  CliArgument.className: 'class-name',
  CliArgument.indent: 'indent',

  CliArgument.fontName: 'font-name',
  CliArgument.normalize: 'normalize',
  CliArgument.ignoreShapes: 'ignore-shapes',

  CliArgument.recursive: 'recursive',
  CliArgument.verbose: 'verbose',
  
  CliArgument.help: 'help',
  CliArgument.configFile: 'config-file',
});

const kConfigKeys = EnumClass<CliArgument, String>({
  CliArgument.svgDir: 'input_svg_dir',
  CliArgument.fontFile: 'output_font_file',

  CliArgument.classFile: 'output_class_file',
  CliArgument.className: 'class_name',
  CliArgument.indent: 'indent',

  CliArgument.fontName: 'font_name',
  CliArgument.normalize: 'normalize',
  CliArgument.ignoreShapes: 'ignore_shapes',

  CliArgument.recursive: 'recursive',
  CliArgument.verbose: 'verbose',

  // help and configFile are not part of config
});

final Map<CliArgument, String> argumentNames = {
  ...kConfigKeys.map,
  ...kOptionNames.map,
};

enum CliArgument {
  svgDir, fontFile,
  classFile, className, indent, 
  fontName, ignoreShapes, normalize,
  recursive, verbose,
  
  // Only in CLI
  help, configFile,
}

/// Contains all the parsed data for the application.
class CliArguments {
  CliArguments(
    this.svgDir,
    this.fontFile,
    this.classFile,
    this.className,
    this.indent,
    this.fontName,
    this.recursive,
    this.ignoreShapes,
    this.normalize,
    this.verbose,
    this.configFile,
  );

  /// Creates [CliArguments] for a map of raw values.
  /// 
  /// Validates type of each argument and formats them.
  /// 
  /// Throws [CliArgumentException], if there is an error in arg parsing 
  /// or if argument has wrong type.
  factory CliArguments.fromMap(Map<CliArgument, Object> rawArgMap) {
    // Validating types
    for (final e in _kArgAllowedTypes.entries) {
      final arg = e.key;
      final argType = rawArgMap[arg].runtimeType;
      final allowedTypes = e.value;

      if (!allowedTypes.contains(argType)) {
        throw CliArgumentException(
          "'${argumentNames[arg]}' argument\'s type "
          'must be one of following: $allowedTypes, '
          "instead got '$argType'."
        );
      }
    }

    final map = formatArguments(rawArgMap);

    return CliArguments(
      map[CliArgument.svgDir] as Directory,
      map[CliArgument.fontFile] as File,
      map[CliArgument.classFile] as File,
      map[CliArgument.className] as String,
      map[CliArgument.indent] as int,
      map[CliArgument.fontName] as String,
      map[CliArgument.recursive] as bool,
      map[CliArgument.ignoreShapes] as bool,
      map[CliArgument.normalize] as bool,
      map[CliArgument.verbose] as bool,
      map[CliArgument.configFile] as File,
    );
  }

  final Directory svgDir;
  final File fontFile;
  final File classFile;
  final String className;
  final int indent;
  final String fontName;
  final bool recursive;
  final bool ignoreShapes;
  final bool normalize;
  final bool verbose;
  final File configFile;

  /// Validates CLI arguments.
  /// 
  /// Throws [CliArgumentException], if argument is not valid.
  void validate() {
    if (svgDir.statSync().type != FileSystemEntityType.directory) {
      throw CliArgumentException("The input directory is not a directory or it doesn't exist.");
    }

    if (indent != null && indent < 0) {
      throw CliArgumentException('indent must be a non-negative integer, was $indent.');
    }
  }
}

/// Parses argument list.
/// 
/// Throws [CliHelpException], if 'help' option is present.
/// 
/// Returns an instance of [CliArguments] containing all parsed data.
CliArguments parseArguments(ArgParser argParser, List<String> args) {
  ArgResults argResults;
  try {
    argResults = argParser.parse(args);
  } on FormatException catch (err) {
    throw CliArgumentException(err.message);
  }

  if (argResults['help'] as bool) {
    throw CliHelpException();
  }

  final posArgsLength = math.min(
    _kPositionalArguments.length,
    argResults.rest.length
  );

  final rawArgMap = <CliArgument, Object>{
    for (final e in kOptionNames.entries)
      e.key: argResults[e.value],
    for (var i = 0; i < posArgsLength; i++)
      _kPositionalArguments[i]: argResults.rest[i],
  };

  return CliArguments.fromMap(rawArgMap);
}

/// Parses config file.
/// 
/// Returns an instance of [CliArguments] containing all parsed data or null,
/// if 'fontify' key is not present in config file.
CliArguments parseConfig(String config) {
  final Object parsedYaml = loadYaml(config);

  if (parsedYaml is! YamlMap) {
    return null;
  }

  final yamlMap = parsedYaml as YamlMap;
  final Object fontifyYaml = yamlMap['fontify'];

  if (fontifyYaml is! YamlMap) {
    return null;
  }

  final fontifyYamlMap = fontifyYaml as YamlMap;

  final argMap = <CliArgument, Object>{
    for (final e in fontifyYamlMap.entries)
      if (e.key is String)
        kConfigKeys.getKeyForValue(e.key as String): e.value,
  };

  return CliArguments.fromMap(argMap);
}

/// Parses argument list and config file, validates parsed data.
/// Config is used, if it contains 'fontify' section.
/// 
/// Throws [CliHelpException], if 'help' option is present.
/// Throws [CliArgumentException], if there is an error in arg parsing.
CliArguments parseArgsAndConfig(ArgParser argParser, List<String> args) {
  CliArguments parsedArgs = parseArguments(argParser, args);

  final defaultConfigList = _kDefaultConfigPathList.map((e) => File(e));
  final configList = [parsedArgs.configFile, ...defaultConfigList];

  for (final configFile in configList) {
    if (configFile?.existsSync() ?? false) {
      final parsedConfig = parseConfig(configFile.readAsStringSync());

      if (parsedConfig != null) {
        logger.i('Using config ${configFile.path}');
        parsedArgs = parsedConfig;
        break;
      }
    }
  }

  parsedArgs.validate();
  return parsedArgs;
}

class CliArgumentException implements Exception {
  CliArgumentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CliHelpException implements Exception {}