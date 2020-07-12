import 'package:xml/xml.dart';

import '../svg/element.dart';
import '../svg/shapes.dart';

extension XmlElementExt on XmlElement {
  num getScalarAttribute(String name, {String namespace, bool zeroIfAbsent = true}) {
    final attr = getAttribute(name, namespace: namespace);

    if (attr == null) {
      return zeroIfAbsent ? 0 : null;
    }

    return num.parse(attr);
  }

  List<SvgElement> parseSvgElements(bool parseShapes) {
    var elements = children
      .whereType<XmlElement>()
      .map((e) => SvgElement.fromXmlElement(e, parseShapes))
      // Ignoring unknown elements
      .where((e) => e != null)
      // Expanding groups
      .expand((e) => e is GroupElement ? e.elementList : [e]);

    if (parseShapes) {
      // Converting shapes into paths
      elements = elements.map((e) => e is PathConvertible ? (e as PathConvertible).getPath() : e);
    }

    return elements.toList();
  }
}