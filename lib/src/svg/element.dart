import 'package:xml/xml.dart';

import 'path.dart';
import 'shapes.dart';

abstract class SvgElement {
  factory SvgElement.fromXmlElement(XmlElement element) {
    switch (element.name.local) {
      case 'path':
        return PathElement.fromXmlElement(element);
      case 'g':
        return GroupElement.fromXmlElement(element);
      case 'rect':
        return RectElement.fromXmlElement(element);
      case 'circle':
        return CircleElement.fromXmlElement(element);
    }

    return null;
  }
}

class GroupElement implements SvgElement {
  GroupElement(this.elementList);

  factory GroupElement.fromXmlElement(XmlElement element) {
    // TODO: apply transform
    final elementList = element.children
      .whereType<XmlElement>()
      .map((e) => SvgElement.fromXmlElement(e))
      .where((e) => e != null)
      .toList();

    return GroupElement(elementList);
  }

  final List<SvgElement> elementList;
}