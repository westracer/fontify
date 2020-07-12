import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../utils/exception.dart';
import '../utils/svg.dart';
import 'element.dart';

class Svg {
  Svg(this.name, this.viewBox, this.elementList);

  /// Parses SVG.
  /// 
  /// Throws [XmlParserException] if XML parsing exception occurs.
  /// Throws [SvgParserException] on any problem related to SVG parsing.
  factory Svg.parse(String name, String xmlString, {bool parseShapes = false}) {
    final xml = XmlDocument.parse(xmlString);
    final root = xml.rootElement;

    if (root.name.local != 'svg') {
      throw SvgParserException('Root element must be SVG');
    }

    final vb = root.getAttribute('viewBox')
      .split(RegExp(r'[\s|,]'))
      .where((e) => e != null)
      .map(num.parse)
      .toList();

    if (vb.isEmpty || vb.length > 4) {
      throw SvgParserException('viewBox must contain 1..4 parameters');
    }

    final fvb = [
      ...List.filled(4 - vb.length, 0),
      ...vb,
    ];

    final viewBox = math.Rectangle(fvb[0], fvb[1], fvb[2], fvb[3]);

    return Svg(name, viewBox, root.parseSvgElements(parseShapes));
  }

  final String name;
  final math.Rectangle viewBox;
  final List<SvgElement> elementList;

  @override
  String toString() => '$name (${elementList.length} elements)';
}