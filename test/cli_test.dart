import 'package:args/args.dart';
import 'package:fontify/src/cli/arguments.dart';
import 'package:fontify/src/cli/options.dart';
import 'package:test/test.dart';

void main() {
  group('Arguments', () {
    final _argParser = ArgParser(allowTrailingOptions: true);
    defineOptions(_argParser);

    void expectCliArgumentException(List<String> args) {
      expect(() => parseArguments(_argParser, args).validate(),
          throwsA(const TypeMatcher<CliArgumentException>()));
    }

    test('No positional args', () {
      expectCliArgumentException([
        '--output-class-file=test/a/df.dart',
        '--indent=4',
        '--class-name=MyIcons',
        '--font-name=My Icons',
      ]);
    });

    test('Positional args validation', () {
      // dir doesn't exist
      expectCliArgumentException(['./asdasd/', 'asdasdasd']);
    });

    test('Options validation', () {
      // indent is positive integer
      expectCliArgumentException(['./', 'asd', '--indent=-1']);
      expectCliArgumentException(['./', 'asd', '--indent=asdasdasd']);
      expectCliArgumentException(['./', 'asd', '--indent=1e-1']);
      expectCliArgumentException(['./', 'asd', '--indent=1.1']);
    });

    test('All arguments with non-defaults', () {
      const args = [
        './',
        'test/fonts/my_font.otf',
        '--output-class-file=test/a/df.dart',
        '--indent=4',
        '--class-name=MyIcons',
        '--font-name=My Icons',
        '--no-normalize',
        '--no-ignore-shapes',
        '--recursive',
        '--verbose',
        '--config-file=test/config.yaml',
        '--package=test_package',
      ];

      final parsedArgs = parseArguments(_argParser, args)..validate();

      expect(parsedArgs.svgDir.path, args.first);
      expect(parsedArgs.fontFile.path, args[1]);
      expect(parsedArgs.classFile.path, 'test/a/df.dart');
      expect(parsedArgs.indent, 4);
      expect(parsedArgs.className, 'MyIcons');
      expect(parsedArgs.fontName, 'My Icons');
      expect(parsedArgs.normalize, isFalse);
      expect(parsedArgs.ignoreShapes, isFalse);
      expect(parsedArgs.recursive, isTrue);
      expect(parsedArgs.verbose, isTrue);
      expect(parsedArgs.configFile.path, 'test/config.yaml');
      expect(parsedArgs.fontPackage, 'test_package');
    });

    test('All arguments with defaults', () {
      const args = [
        './',
        'test/fonts/my_font.otf',
        '--normalize',
        '--ignore-shapes',
      ];

      final parsedArgs = parseArguments(_argParser, args)..validate();

      expect(parsedArgs.svgDir.path, args.first);
      expect(parsedArgs.fontFile.path, args[1]);
      expect(parsedArgs.classFile, isNull);
      expect(parsedArgs.indent, 2);
      expect(parsedArgs.className, isNull);
      expect(parsedArgs.fontName, isNull);
      expect(parsedArgs.normalize, isTrue);
      expect(parsedArgs.ignoreShapes, isTrue);
      expect(parsedArgs.recursive, isFalse);
      expect(parsedArgs.verbose, isFalse);
      expect(parsedArgs.configFile, isNull);
      expect(parsedArgs.fontPackage, isNull);
    });

    test('Help', () {
      void expectCliHelpException(List<String> args) {
        expect(() => parseArguments(_argParser, args).validate(),
            throwsA(const TypeMatcher<CliHelpException>()));
      }

      expectCliHelpException(['-h']);
      expectCliHelpException([
        './',
        'test/fonts/my_font.otf',
        '--output-class-file=test/a/df.dart',
        '--indent=4',
        '--class-name=MyIcons',
        '--font-name=My Icons',
        '--no-normalize',
        '--no-ignore-shapes',
        '--recursive',
        '--verbose',
        '--help',
      ]);
      expectCliHelpException([
        './asdasd/sad/sad/asd',
        'adsfsdasfdsdfdsf',
        '--help',
      ]);
    });

    test('All arguments and config', () {
      const args = [
        'no',
        'no',
        '--output-class-file=no',
        '--indent=0',
        '--class-name=no',
        '--font-name=no',
        '--normalize',
        '--ignore-shapes',
        '--recursive',
        '--verbose',
        '--package=no',
        '--config-file=test/assets/test_config.yaml',
      ];

      final parsedArgs = parseArgsAndConfig(_argParser, args)..validate();

      expect(parsedArgs.svgDir.path, './');
      expect(parsedArgs.fontFile.path, 'generated_font.otf');
      expect(parsedArgs.classFile.path, 'lib/test_font.dart');
      expect(parsedArgs.indent, 4);
      expect(parsedArgs.className, 'MyIcons');
      expect(parsedArgs.fontName, 'My Icons');
      expect(parsedArgs.normalize, isFalse);
      expect(parsedArgs.ignoreShapes, isFalse);
      expect(parsedArgs.recursive, isFalse);
      expect(parsedArgs.verbose, isFalse);
      expect(parsedArgs.configFile, isNull);
      expect(parsedArgs.fontPackage, 'test_package');
    });

    test('No arguments and config', () {
      const args = [
        '--config-file=test/assets/test_config.yaml',
      ];

      final parsedArgs = parseArgsAndConfig(_argParser, args)..validate();

      expect(parsedArgs.svgDir.path, './');
      expect(parsedArgs.fontFile.path, 'generated_font.otf');
      expect(parsedArgs.classFile.path, 'lib/test_font.dart');
      expect(parsedArgs.indent, 4);
      expect(parsedArgs.className, 'MyIcons');
      expect(parsedArgs.fontName, 'My Icons');
      expect(parsedArgs.normalize, isFalse);
      expect(parsedArgs.ignoreShapes, isFalse);
      expect(parsedArgs.recursive, isFalse);
      expect(parsedArgs.verbose, isFalse);
      expect(parsedArgs.configFile, isNull);
      expect(parsedArgs.fontPackage, 'test_package');
    });
  });

  group('Config', () {
    void expectCliArgumentException(String cfg) {
      expect(() => parseConfig(cfg).validate(),
          throwsA(const TypeMatcher<CliArgumentException>()));
    }

    test('No required', () {
      expectCliArgumentException('''
fontify:  
  output_class_file: lib/test_font.dart
  class_name: MyCoolIcons
  indent: 4

  font_name: My Cool Icons
      ''');
    });

    test('Positional args validation', () {
      // dir doesn't exist
      expectCliArgumentException('''
fontify:
  input_svg_dir: asdasdasasdsd/
  output_font_file: asdasdasd
      ''');
    });

    test('Options validation', () {
      // indent is positive integer
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: asdasdasd
  indent: -1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: asdasdasd
  indent: asdasdasd
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: asdasdasd
  indent: 1e-1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: asdasdasd
  indent: 1.1
      ''');
    });

    test('All arguments with non-defaults', () {
      final parsedArgs = parseConfig('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  
  output_class_file: lib/test_font.dart
  class_name: MyIcons
  indent: 4
  package: test_package

  font_name: My Icons
  normalize: false
  ignore_shapes: false

  recursive: true
  verbose: true
      ''')..validate();

      expect(parsedArgs.svgDir.path, './');
      expect(parsedArgs.fontFile.path, 'generated_font.otf');
      expect(parsedArgs.classFile.path, 'lib/test_font.dart');
      expect(parsedArgs.indent, 4);
      expect(parsedArgs.className, 'MyIcons');
      expect(parsedArgs.fontName, 'My Icons');
      expect(parsedArgs.normalize, isFalse);
      expect(parsedArgs.ignoreShapes, isFalse);
      expect(parsedArgs.recursive, isTrue);
      expect(parsedArgs.verbose, isTrue);
      expect(parsedArgs.fontPackage, 'test_package');
    });

    test('All arguments with defaults', () {
      final parsedArgs = parseConfig('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
      ''')..validate();

      expect(parsedArgs.svgDir.path, './');
      expect(parsedArgs.fontFile.path, 'generated_font.otf');
      expect(parsedArgs.classFile, isNull);
      expect(parsedArgs.indent, null);
      expect(parsedArgs.className, isNull);
      expect(parsedArgs.fontName, isNull);
      expect(parsedArgs.normalize, isNull);
      expect(parsedArgs.ignoreShapes, isNull);
      expect(parsedArgs.recursive, isNull);
      expect(parsedArgs.verbose, isNull);
      expect(parsedArgs.fontPackage, isNull);
    });

    test('Type validation', () {
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  output_class_file: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  class_name: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  font_name: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  normalize: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  ignore_shapes: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  recursive: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  verbose: 1
      ''');
      expectCliArgumentException('''
fontify:
  input_svg_dir: ./
  output_font_file: generated_font.otf
  package: 1
      ''');
    });
  });
}
