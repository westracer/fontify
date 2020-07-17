import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../utils/exception.dart';
import '../utils/svg.dart';
import 'element.dart';

class Svg extends SvgElement {
  Svg(
    this.name,
    this.viewBox,
    this.elementList,
    XmlElement xmlElement,
  ) : super(null, xmlElement);

  /// Parses SVG.
  /// 
  /// If [ignoreShapes] is set to false, shapes (circle, rect, etc.) are converted into paths.
  /// NOTE: Attributes like "fill" or "stroke" are ignored,
  /// which means only shape's outline will be used.
  /// 
  /// Throws [XmlParserException] if XML parsing exception occurs.
  /// Throws [SvgParserException] on any problem related to SVG parsing.
  factory Svg.parse(String name, String xmlString, {bool ignoreShapes}) {
    ignoreShapes ??= true;

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

    final svg = Svg(name, viewBox, [], root);

    final elementList = root.parseSvgElements(svg, ignoreShapes);
    svg.elementList.addAll(elementList);

    return svg;
  }

  final String name;
  final math.Rectangle viewBox;
  final List<SvgElement> elementList;

  @override
  String toString() => '$name (${elementList.length} elements)';
}