import 'package:xml/xml.dart';

import '../utils/exception.dart';
import 'element.dart';

enum PathSegmentType {
  moveTo,
  lineTo, hLineTo, vLineto,
  cubic, smoothCubic,
  quad, smoothQuad,
  arc,
  close,
}

const _kCommandTypeMap = {
  'm': PathSegmentType.moveTo,

  'l': PathSegmentType.lineTo,
  'h': PathSegmentType.hLineTo,
  'v': PathSegmentType.vLineto,

  'c': PathSegmentType.cubic,
  's': PathSegmentType.smoothCubic,
  
  'q': PathSegmentType.quad,
  't': PathSegmentType.smoothQuad,
  
  'a': PathSegmentType.arc,

  'z': PathSegmentType.close,
};

final _commandRegExp = RegExp(r'[M|m|L|l|H|h|V|v|C|c|S|s|Q|q|T|t|A|a|Z|z]');

bool isQuadSegment(PathSegment s) =>
  [PathSegmentType.quad, PathSegmentType.smoothQuad].contains(s.type);

bool isCubicSegment(PathSegment s) =>
  [PathSegmentType.cubic, PathSegmentType.smoothCubic].contains(s.type);

class PathSegment {
  PathSegment(this.command, this.parameterList)
  : type = _kCommandTypeMap[command.toLowerCase()],
    isRelative = command.toLowerCase() == command;

  factory PathSegment.fromString(String string) {
    final parameters = string
      .substring(1)
      .split(RegExp(r'[\s|,]+'))
      .where((e) => e.isNotEmpty)
      .map(num.parse)
      .toList();
    
    return PathSegment(
      string[0],
      parameters
    );
  }
  
  final String command;
  final bool isRelative;
  final PathSegmentType type;
  final List<num> parameterList;

  @override
  String toString() => '$command ${parameterList.join(',')}';
}

class PathElement implements SvgElement {
  PathElement(this.fillRule, this.transform, this.commandList);

  factory PathElement.fromXmlElement(XmlElement element) {
    final dAttr = element.getAttribute('d');

    if (dAttr == null) {
      throw SvgParserException('Path element must contain "d" attribute');
    }

    final commandIndicies = [
      ..._commandRegExp.allMatches(dAttr).map((e) => e.start),
      dAttr.length
    ];

    final commandList = <PathSegment>[
      for (int i = 1; i < commandIndicies.length; i++)
        PathSegment.fromString(
          dAttr.substring(commandIndicies[i - 1], commandIndicies[i])
        )
    ];

    final fillRule = element.getAttribute('fill-rule');
    final transform = element.getAttribute('transform');

    return PathElement(fillRule, transform, commandList);
  }

  final String fillRule;
  final String transform;
  final List<PathSegment> commandList;
}