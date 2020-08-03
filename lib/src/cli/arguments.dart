import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import '../utils/enum_class.dart';
import '../utils/logger.dart';
import 'formatter.dart';

const _kDefaultConfigPath = 'pubspec.yaml';
const _kPositionalArguments = [CliArgument.svgDir, CliArgument.fontFile];

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

  /// Takes a map of raw values for each argument and formats them.
  /// 
  /// Throws [CliArgumentException], if there is an error in arg parsing.
  factory CliArguments.fromMap(Map<CliArgument, Object> rawArgMap) {
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
    if (svgDir == null) {
      throw CliArgumentException('The input directory is not specified.');
    }

    if (svgDir.statSync().type != FileSystemEntityType.directory) {
      throw CliArgumentException("The input directory is not a directory or it doesn't exist.");
    }

    if (fontFile == null) {
      throw CliArgumentException('The output font file is not specified.');
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

  rawArgMap[CliArgument.configFile] ??= _kDefaultConfigPath;

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

  if (parsedArgs.configFile.existsSync()) {
    final parsedConfig = parseConfig(parsedArgs.configFile.readAsStringSync());

    if (parsedConfig != null) {
      logger.i('Using config ${parsedArgs.configFile.path}');
      parsedArgs = parsedConfig;
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