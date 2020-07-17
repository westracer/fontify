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
  final bool ignoreShapes;
  final bool normalize;
  final bool verbose;
}

/// Parses argument list.
/// 
/// Returns an instance of [CliArguments] containing all parsed data.
CliArguments parseArguments(
  ArgParser argParser,
  List<String> args,
  void Function(String) errorCallback,
  void Function() helpCallback,
) {
  ArgResults argResults;
  try {
    argResults = argParser.parse(args);
  } on FormatException catch (err) {
    errorCallback(err.message);
  }

  if (argResults['help'] as bool) {
    helpCallback();
  }

  if (argResults.rest.length < 2) {
    errorCallback(
      'Too few positional arguments: '
      '2 required, ${argResults.rest.length} given.'
    );
  }

  final svgDir = Directory(argResults.rest[0]);

  if (svgDir.statSync().type != FileSystemEntityType.directory) {
    errorCallback("<input-svg-dir> is not a directory or the directory doesn't exist.");
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
    errorCallback('--indent must be a non-negative integer, was "$indentArg".');
  }

  final className = argResults['class-name'] as String;
  final fontName = argResults['font-name'] as String;
  final normalize = argResults['normalize'] as bool;
  final ignoreShapes = argResults['ignore-shapes'] as bool;
  final verbose = argResults['verbose'] as bool;

  return CliArguments(
    svgDir,
    fontFile,
    classFile,
    className,
    indent,
    fontName,
    ignoreShapes,
    normalize,
    verbose,
  );
}