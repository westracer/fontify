import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../ttf/table/head.dart';
import 'misc.dart';

const String kHeadTag = 'head';
const String kGSUBTag = 'GSUB';
const String kOS2Tag  = 'OS/2';
const String kCmapTag = 'cmap';
const String kGlyfTag = 'glyf';
const String kHheaTag = 'hhea';
const String kHmtxTag = 'hmtx';
const String kLocaTag = 'loca';
const String kMaxpTag = 'maxp';
const String kNameTag = 'name';
const String kPostTag = 'post';

const kPlatformUnicode   = 0;
const kPlatformMacintosh = 1;
const kPlatformWindows   = 3;

final _longDateTimeStart = DateTime.parse('1904-01-01T00:00:00.000Z');

String convertTagToString(Uint8List bytes) => 
  String.fromCharCodes(bytes);

DateTime getDateTime(int seconds) => 
  _longDateTimeStart.add(Duration(seconds: seconds));

int getLongDateTime(DateTime dateTime) => 
  dateTime.difference(_longDateTimeStart).inSeconds;

bool checkBitMask(int value, int mask) => 
  (value & mask) == mask;

int calculateTableChecksum(ByteData encodedTable) {
  final length = (encodedTable.lengthInBytes / 4).floor();

  int sum = 0;

  for (int i = 0; i < length; i++) {
    sum = (sum + encodedTable.getUint32(4 * i)).toUnsigned(32);
  }

  final notAlignedBytesLength = encodedTable.lengthInBytes % 4;
  
  if (notAlignedBytesLength > 0) {
    final endBytes = [
      // Reading remaining bytes
      for (int i = 4 * length; i < encodedTable.lengthInBytes; i++)
        encodedTable.getUint8(i),

      // Filling with zeroes
      for (int i = 0; i < 4 - notAlignedBytesLength; i++)
        0,
    ];

    int endValue = 0;

    for (final byte in endBytes) {
      endValue <<= 8;
      endValue += byte;
    }

    sum = (sum + endValue).toUnsigned(32);
  }

  return sum;
}

int calculateFontChecksum(ByteData byteData) {
  return (kChecksumMagicNumber - calculateTableChecksum(byteData)).toUnsigned(32);
}

extension TTFByteDateExt on ByteData {
  int getFixed(int offset) => getUint16(offset);
  int getFWord(int offset) => getInt16(offset);
  int getUFWord(int offset) => getUint16(offset);
}

extension TTFStringExt on String {
  String getAsciiPrintable() =>
    replaceAll(RegExp(r'([^\x00-\x7E]|[\(\[\]\(\)\{\}<>\/%])'), '');
}


@immutable
class Revision {
  const Revision(int major, int minor) : 
    major = major ?? 0, 
    minor = minor ?? 0;

  const Revision.fromInt32(int revision) 
  : major = (revision >> 16) & 0xFFFF,
    minor = revision & 0xFFFF;

  final int major;
  final int minor;

  int get int32value => major * 0x10000 + minor;

  @override
  int get hashCode => combineHashCode(major.hashCode, minor.hashCode);

  @override
  bool operator==(Object other) {
    if (other is Revision) {
      return major == other.major && minor == other.minor;
    }

    return false;
  }
}