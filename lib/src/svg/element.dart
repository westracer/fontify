import 'package:xml/xml.dart';

import '../utils/svg.dart';
import 'path.dart';
import 'shapes.dart';

abstract class SvgElement {
  factory SvgElement.fromXmlElement(XmlElement element, bool parseShapes) {
    switch (element.name.local) {
      case 'path':
        return PathElement.fromXmlElement(element);
      case 'g':
        return GroupElement.fromXmlElement(element, parseShapes);
      case 'rect':
        return RectElement.fromXmlElement(element);
      case 'circle':
        return CircleElement.fromXmlElement(element);
      case 'polyline':
        return PolylineElement.fromXmlElement(element);
      case 'polygon':
        return PolygonElement.fromXmlElement(element);
      case 'line':
        return LineElement.fromXmlElement(element);
    }

    return null;
  }
}

class GroupElement implements SvgElement {
  GroupElement(this.elementList);

  factory GroupElement.fromXmlElement(XmlElement element, bool parseShapes) {
    // TODO: apply transform
    return GroupElement(element.parseSvgElements(parseShapes));
  }

  final List<SvgElement> elementList;
}