import 'package:xml/xml.dart';

extension XmlElementExt on XmlElement {
  num getScalarAttribute(String name, {String namespace, bool zeroIfAbsent = true}) {
    final attr = getAttribute(name, namespace: namespace);

    if (attr == null) {
      return zeroIfAbsent ? 0 : null;
    }

    return num.parse(attr);
  }
}