import 'package:args/args.dart';
import 'package:fontify/src/cli/arguments.dart';
import 'package:fontify/src/cli/options.dart';
import 'package:test/test.dart';

void main() {
  group('Arguments', () {
    final _argParser = ArgParser(allowTrailingOptions: true);
    defineOptions(_argParser);
    
    void expectCliArgumentException(List<String> args) {
      expect(
        () => parseArguments(_argParser, args),
        throwsA(const TypeMatcher<CliArgumentException>())
      );
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
      ];

      final parsedArgs = parseArguments(_argParser, args);
      
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
    });

    test('All arguments with defaults', () {
      const args = [
        './',
        'test/fonts/my_font.otf',
        '--normalize',
        '--ignore-shapes',
      ];

      final parsedArgs = parseArguments(_argParser, args);
      
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
    });

    test('Help', () {
      void expectCliHelpException(List<String> args) {
        expect(
          () => parseArguments(_argParser, args),
          throwsA(const TypeMatcher<CliHelpException>())
        );
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
  });
}