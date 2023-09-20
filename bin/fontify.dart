import 'dart:io';

import 'package:args/args.dart';
import 'package:fontify/src/cli/arguments.dart';
import 'package:fontify/src/cli/options.dart';
import 'package:fontify/src/common.dart';
import 'package:fontify/src/otf/io.dart';
import 'package:fontify/src/utils/flutter_class_gen.dart';
import 'package:fontify/src/utils/logger.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final _argParser = ArgParser(allowTrailingOptions: true);

void main(List<String> args) {
  defineOptions(_argParser);

  late final CliArguments parsedArgs;

  try {
    parsedArgs = parseArgsAndConfig(_argParser, args);
  } on CliArgumentException catch (e) {
    _usageError(e.message);
  } on CliHelpException {
    _printHelp();
  } on YamlException catch (e) {
    logger.e(e.toString());
    exit(66);
  }

  try {
    _run(parsedArgs);
  } on Object catch (e) {
    logger.e(e.toString());
    exit(65);
  }
}

void _run(CliArguments parsedArgs) {
  final stopwatch = Stopwatch()..start();

  final isRecursive = parsedArgs.recursive ?? kDefaultRecursive;
  final isVerbose = parsedArgs.verbose ?? kDefaultVerbose;

  if (isVerbose) {
    logger.setFilterLevel(Level.verbose);
  }

  if (parsedArgs.classFile?.existsSync() ?? false) {
    logger.v('Output file for a Flutter class already exists (${parsedArgs.classFile!.path}) - '
        'overwriting it');
  }

  if (!parsedArgs.fontFile.existsSync()) {
    logger.v('Output file for a font file already exists (${parsedArgs.fontFile.path}) - '
        'overwriting it');
  }

  final svgFileList = parsedArgs.svgDir
      .listSync(recursive: isRecursive)
      .where((e) => p.extension(e.path).toLowerCase() == '.svg')
      .toList();

  if (svgFileList.isEmpty) {
    logger.w("The input directory doesn't contain any SVG file (${parsedArgs.svgDir.path}).");
  }

  final svgMap = {
    for (final f in svgFileList) p.basenameWithoutExtension(f.path): File(f.path).readAsStringSync(),
  };

  final otfResult = svgToOtf(
    svgMap: svgMap,
    ignoreShapes: parsedArgs.ignoreShapes,
    normalize: parsedArgs.normalize,
    fontName: parsedArgs.fontName,
  );

  writeToFile(parsedArgs.fontFile.path, otfResult.font);

  if (parsedArgs.classFile == null) {
    logger.v('No output path for Flutter class was specified - '
        'skipping class generation.');
  } else {
    final fontFileName = p.basename(parsedArgs.fontFile.path);

    final classString = generateFlutterClass(
        glyphList: otfResult.glyphList,
        className: parsedArgs.className,
        indent: parsedArgs.indent,
        fontFileName: fontFileName,
        familyName: otfResult.font.familyName,
        package: parsedArgs.fontPackage,
        variableNameCase: VariableNameCase.values.firstWhere((e) => e.option == parsedArgs.variableNameCase));

    parsedArgs.classFile!.writeAsStringSync(classString);
  }

  logger.i('Generated in ${stopwatch.elapsedMilliseconds}ms');
}

void _printHelp() {
  _printUsage();
  exit(exitCode);
}

void _usageError(String error) {
  _printUsage(error);
  exit(64);
}

void _printUsage([String? error]) {
  final message = error ?? _kAbout;

  stdout.write('''
$message

$_kUsage
${_argParser.usage}
''');
  exit(64);
}

const _kAbout = 'Converts .svg icons to an OpenType font and generates Flutter-compatible class.';

const _kUsage = '''
Usage:   fontify <input-svg-dir> <output-font-file> [options]

Example: fontify assets/svg/ fonts/my_icons_font.otf --output-class-file=lib/my_icons.dart

Converts every .svg file from <input-svg-dir> directory to an OpenType font and writes it to <output-font-file> file.
If "--output-class-file" option is specified, Flutter-compatible class that contains identifiers for the icons is generated.
''';
