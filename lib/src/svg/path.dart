import 'package:xml/xml.dart';

import '../utils/exception.dart';
import 'element.dart';

class PathElement implements SvgElement {
  PathElement(this.fillRule, this.transform, this.data);

  factory PathElement.fromXmlElement(XmlElement element) {
    final dAttr = element.getAttribute('d');

    if (dAttr == null) {
      throw SvgParserException('Path element must contain "d" attribute');
    }

    final fillRule = element.getAttribute('fill-rule');
    final transform = element.getAttribute('transform');

    return PathElement(fillRule, transform, dAttr);
  }

  final String fillRule;
  final String transform;
  final String data;
}