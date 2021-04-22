import 'dart:io';

import 'arguments.dart';

typedef CliArgumentFormatter = dynamic Function(dynamic arg);

const _kArgumentFormatters = <CliArgument, CliArgumentFormatter>{
  CliArgument.svgDir: _dir,
  CliArgument.fontFile: _file,
  CliArgument.classFile: _file,
  CliArgument.indent: _indent,
  CliArgument.configFile: _file,
};

Directory _dir(dynamic arg) => Directory(arg as String);

File _file(dynamic arg) => File(arg as String);

int _indent(dynamic arg) {
  if (arg is int) {
    return arg;
  }

  void throwException() {
    throw CliArgumentException('indent must be integer, was "$arg".');
  }

  if (arg is! String) {
    throwException();
  }

  late final int indent;
  final indentArg = arg as String;

  try {
    indent = int.parse(indentArg);
  } on FormatException catch (_) {
    throwException();
  }

  return indent;
}

/// Formats arguments.
Map<CliArgument, dynamic> formatArguments(Map<CliArgument, dynamic> args) {
  return args.map<CliArgument, dynamic>((k, dynamic v) {
    final formatter = _kArgumentFormatters[k];

    if (formatter == null || v == null) {
      return MapEntry<CliArgument, dynamic>(k, v);
    }

    return MapEntry<CliArgument, dynamic>(k, formatter(v));
  });
}

// Ignoring as CLI arguments are dynamically typed
// ignore_for_file: avoid_annotating_with_dynamic
