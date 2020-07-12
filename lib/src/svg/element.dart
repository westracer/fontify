import 'package:xml/xml.dart';

import 'path.dart';

// TODO: arc, circle etc.
abstract class SvgElement {
  factory SvgElement.fromXmlElement(XmlElement element) {
    switch (element.name.local) {
      case 'path':
        return PathElement.fromXmlElement(element);
    }

    return null;
  }
}