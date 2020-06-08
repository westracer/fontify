import 'dart:typed_data';

const String kHeadTag = 'head';
const String kGSUBTag = 'GSUB';
const String kOS2Tag = 'OS/2';
const String kCmapTag = 'cmap';
const String kGlyfTag = 'glyf';
const String kHheaTag = 'hhea';
const String kHmtxTag = 'hmtx';
const String kLocaTag = 'loca';
const String kMaxpTag = 'maxp';
const String kNameTag = 'name';
const String kPostTag = 'post';

final _longDateTimeStart = DateTime.parse('1904-01-01T00:00:00.000Z');

String convertTag(Uint8List bytes) => 
  String.fromCharCodes(bytes);

DateTime getDateTime(int seconds) => 
  _longDateTimeStart.add(Duration(seconds: seconds));

int getLongDateTime(DateTime dateTime) => 
  dateTime.difference(_longDateTimeStart).inSeconds;