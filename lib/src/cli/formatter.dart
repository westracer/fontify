import 'dart:io';

import 'arguments.dart';

typedef CliArgumentFormatter = Object Function(Object arg);

const _kArgumentFormatters = <CliArgument, CliArgumentFormatter>{
  CliArgument.svgDir: _dir,
  CliArgument.fontFile: _file,

  CliArgument.classFile: _file,
  CliArgument.indent: _indent,

  CliArgument.configFile: _file,
};

Directory _dir(Object arg) =>
  arg == null ? null : Directory(arg as String);

File _file(Object arg) =>
  arg == null ? null : File(arg as String);

int _indent(Object arg) {
  if (arg is int) {
    return arg;
  }

  void throwException() {
    throw CliArgumentException('indent must be integer, was "$arg".');
  }

  if (arg is double) {
    throwException();
  }

  int indent;
  final indentArg = arg as String;

  try {
    if (indentArg != null) {
      indent = int.parse(indentArg);
    }
  } on FormatException catch (_) {
    throwException();
  }

  return indent;
}

/// Formats arguments.
Map<CliArgument, Object> formatArguments(Map<CliArgument, Object> args) {
  return args.map((k, v) {
    final formatter = _kArgumentFormatters[k];

    if (formatter == null) {
      return MapEntry(k, v);
    }

    return MapEntry(k, formatter(v));
  });
}