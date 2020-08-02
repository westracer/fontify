import 'dart:io';

import 'package:args/args.dart';

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
    this.verbose
  );

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
}

/// Parses argument list.
/// 
/// Throws [CliArgumentException], if there is an error in arg parsing.
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

  if (argResults.rest.length < 2) {
    throw CliArgumentException(
      'Too few positional arguments: '
      '2 required, ${argResults.rest.length} given.'
    );
  }

  final svgDir = Directory(argResults.rest[0]);

  if (svgDir.statSync().type != FileSystemEntityType.directory) {
    throw CliArgumentException("<input-svg-dir> is not a directory or the directory doesn't exist.");
  }

  final fontFile = File(argResults.rest[1]);
  final classFilePath = argResults['output-class-file'] as String;
  final classFile = classFilePath?.isNotEmpty ?? false ? File(classFilePath) : null;

  int indent;
  final indentArg = argResults['indent'] as String;
  try {
    if (indentArg != null) {
      indent = int.parse(indentArg);

      if (indent < 0) {
        throw const FormatException();
      }
    }
  } on FormatException catch (_) {
    throw CliArgumentException('--indent must be a non-negative integer, was "$indentArg".');
  }

  final className = argResults['class-name'] as String;
  final fontName = argResults['font-name'] as String;
  final recursive = argResults['recursive'] as bool;
  final ignoreShapes = argResults['ignore-shapes'] as bool;
  final normalize = argResults['normalize'] as bool;
  final verbose = argResults['verbose'] as bool;

  return CliArguments(
    svgDir,
    fontFile,
    classFile,
    className,
    indent,
    fontName,
    recursive,
    ignoreShapes,
    normalize,
    verbose,
  );
}

class CliArgumentException implements Exception {
  CliArgumentException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CliHelpException implements Exception {}