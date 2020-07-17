import 'dart:io';

import 'package:args/args.dart';
import 'package:fontify/src/cli/arguments.dart';
import 'package:fontify/src/cli/options.dart';
import 'package:fontify/src/common/generic_glyph.dart';
import 'package:fontify/src/otf/io.dart';
import 'package:fontify/src/otf/otf.dart';
import 'package:fontify/src/svg/svg.dart';
import 'package:fontify/src/utils/flutter_class_gen.dart';
import 'package:fontify/src/utils/logger.dart';
import 'package:path/path.dart' as p;

final _argParser = ArgParser(allowTrailingOptions: true);

void main(List<String> args) {
  defineOptions(_argParser);
  
  final parsedArgs = parseArguments(_argParser, args, _usageError, _printHelp);

  try {
    _run(parsedArgs);
  } catch (e) { // ignore: avoid_catches_without_on_clauses
    logger.e(e.toString());
    exit(65);
  }
}

void _run(CliArguments parsedArgs) {
  final stopwatch = Stopwatch()..start();

  if (parsedArgs.verbose) {
    logger.setFilterLevel(Level.verbose);
  }

  final svgFileList = parsedArgs.svgDir
    .listSync()
    .where((e) => p.extension(e.path).toLowerCase() == '.svg')
    .toList();
  
  final svgList = svgFileList
    .map((e) {
      final baseName = p.basenameWithoutExtension(e.path);
      final data = File(e.path).readAsStringSync();
      
      return Svg.parse(baseName, data, ignoreShapes: parsedArgs.ignoreShapes);
    })
    .toList();

  if (!parsedArgs.normalize) {
    for (int i = 1; i < svgList.length; i++) {
      if (svgList[i - 1].viewBox.height != svgList[i].viewBox.height) {
        logger.logOnce(
          Level.warning,
          'Some SVG files contain different view box height, '
          'while normalization option is disabled. '
          'This is not recommended.'
        );
        break;
      }
    }
  }

  final glyphList = svgList.map((e) => GenericGlyph.fromSvg(e)).toList();

  final font = OpenTypeFont.createFromGlyphs(
    glyphList: glyphList,
    fontName: parsedArgs.fontName,
    normalize: parsedArgs.normalize,
    useCFF2: true,
  );
  
  writeToFile(parsedArgs.fontFile, font);

  if (parsedArgs.classFile == null) {
    logger.v('No output path for Flutter class was specified.');
  } else {
    final charCodeList = font.generatedCharCodeList;
    final iconMap = {
      for (int i = 0; i < svgFileList.length; i++)
        charCodeList[i]: p.basename(svgFileList[i].path)
    };
    
    final fontFileName = p.basename(parsedArgs.fontFile.path);
    final generator = FlutterClassGenerator(
      fontFileName,
      iconMap,
      className: parsedArgs.className,
      familyName: font.familyName,
      indent: parsedArgs.indent,
    );

    final classString = generator.generate();
    parsedArgs.classFile.writeAsStringSync(classString);
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

void _printUsage([String error]) {
  final message = error ?? _kAbout;
  
  stdout.write(
'''
$message

$_kUsage
${_argParser.usage}
''');
  exit(64);
}

const _kAbout = 'Converts .svg icons to an OpenType font and generates Flutter-compatible class.';

const _kUsage = 
'''
Usage:   fontify <input-svg-dir> <output-font-file> [options]

Example: fontify assets/svg/ fonts/my_icons_font.otf --output-class-file=lib/my_icons.dart

Converts every .svg file from <input-svg-dir> directory to an OpenType font and writes it to <output-font-file> file.
If "--output-class-file" option is specified, Flutter-compatible class that contains identifiers for the icons is generated.
''';