import 'dart:typed_data';

import '../../utils/pascal_string.dart';
import '../../utils/ttf.dart' as ttf_utils;
import '../debugger.dart';

import 'abstract.dart';
import 'table_record_entry.dart';

const _kFormat2 = 0x2;
const _kHeaderSize = 32;

class PostScriptTableHeader {
  PostScriptTableHeader(
    this.version,
    this.italicAngle,
    this.underlinePosition,
    this.underlineThickness,
    this.isFixedPitch,
    this.minMemType42,
    this.maxMemType42,
    this.minMemType1,
    this.maxMemType1,
  );

  factory PostScriptTableHeader.fromByteData(
    ByteData byteData,
    TableRecordEntry entry
  ) {
    final version = byteData.getFixed(entry.offset);

    return PostScriptTableHeader(
      version,
      byteData.getFixed(entry.offset + 4),
      byteData.getFWord(entry.offset + 8),
      byteData.getFWord(entry.offset + 10),
      byteData.getUint32(entry.offset + 12),
      byteData.getUint32(entry.offset + 16),
      byteData.getUint32(entry.offset + 20),
      byteData.getUint32(entry.offset + 24),
      byteData.getUint32(entry.offset + 28),
    );
  }

  final int version;
  final int italicAngle;
  final int underlinePosition;
  final int underlineThickness;
  final int isFixedPitch;
  final int minMemType42;
  final int maxMemType42;
  final int minMemType1;
  final int maxMemType1;
}

abstract class PostScriptFormatData {
  static PostScriptFormatData fromByteData(
    ByteData byteData,
    int offset,
    PostScriptTableHeader header
  ) {
    switch (header.version) {
      case _kFormat2:
        return PostScriptFormat20.fromByteData(byteData, offset);
      default:
        TTFDebugger.debugUnsupportedTableVersion(ttf_utils.kPostTag, header.version);
        return null;
    }
  }
}

class PostScriptFormat20 extends PostScriptFormatData {
  PostScriptFormat20(
    this.numberOfGlyphs, 
    this.glyphNameIndex, 
    this.glyphNames
  );

  factory PostScriptFormat20.fromByteData(
    ByteData byteData,
    int offset
  ) {
    final numberOfGlyphs = byteData.getUint16(offset);
    offset += 2;

    final glyphNameIndex = List.generate(
      numberOfGlyphs,
      (i) => byteData.getUint16(offset + i * 2)
    );
    offset += numberOfGlyphs * 2;

    final glyphNames = List.generate(
      numberOfGlyphs,
      (i) {
        final glyphIndex = glyphNameIndex[i];
        final isStandard = glyphIndex < _kMacStandardGlyphNames.length;

        if (isStandard) {
          return PascalString.fromString(_kMacStandardGlyphNames[glyphIndex]);
        }

        final string = PascalString.fromByteData(byteData, offset);
        offset += string.size;
        return string;
      }
    );

    return PostScriptFormat20(
      numberOfGlyphs,
      glyphNameIndex,
      glyphNames
    );
  }

  final int numberOfGlyphs;
  final List<int> glyphNameIndex;
  final List<PascalString> glyphNames;
}

class PostScriptTable extends FontTable {
  PostScriptTable(
    TableRecordEntry entry,
    this.header,
    this.data
  ) : super.fromTableRecordEntry(entry);

  factory PostScriptTable.fromByteData(
    ByteData byteData,
    TableRecordEntry entry
  ) {
    final header = PostScriptTableHeader.fromByteData(byteData, entry);

    return PostScriptTable(
      entry, 
      header,
      PostScriptFormatData.fromByteData(byteData, entry.offset + _kHeaderSize, header)
    );
  }

  final PostScriptTableHeader header;
  final PostScriptFormatData data;
}

const _kMacStandardGlyphNames = [
  '.notdef', '.null', 'nonmarkingreturn', 'space', 'exclam', 'quotedbl', 'numbersign',
  'dollar', 'percent', 'ampersand', 'quotesingle', 'parenleft', 'parenright', 'asterisk',
  'plus', 'comma', 'hyphen', 'period', 'slash', 'zero', 'one', 'two', 'three', 'four',
  'five', 'six', 'seven', 'eight', 'nine', 'colon', 'semicolon', 'less', 'equal', 'greater',
  'question', 'at', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
  'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'bracketleft', 'backslash', 'bracketright',
  'asciicircum', 'underscore', 'grave', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
  'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'braceleft', 'bar',
  'braceright', 'asciitilde', 'Adieresis', 'Aring', 'Ccedilla', 'Eacute', 'Ntilde', 'Odieresis',
  'Udieresis', 'aacute', 'agrave', 'acircumflex', 'adieresis', 'atilde', 'aring', 'ccedilla',
  'eacute', 'egrave', 'ecircumflex', 'edieresis', 'iacute', 'igrave', 'icircumflex', 'idieresis',
  'ntilde', 'oacute', 'ograve', 'ocircumflex', 'odieresis', 'otilde', 'uacute', 'ugrave', 'ucircumflex',
  'udieresis', 'dagger', 'degree', 'cent', 'sterling', 'section', 'bullet', 'paragraph', 'germandbls',
  'registered', 'copyright', 'trademark', 'acute', 'dieresis', 'notequal', 'AE', 'Oslash', 'infinity',
  'plusminus', 'lessequal', 'greaterequal', 'yen', 'mu', 'partialdiff', 'summation', 'product', 'pi',
  'integral', 'ordfeminine', 'ordmasculine', 'Omega', 'ae', 'oslash', 'questiondown', 'exclamdown', 'logicalnot',
  'radical', 'florin', 'approxequal', 'Delta', 'guillemotleft', 'guillemotright', 'ellipsis', 'nonbreakingspace',
  'Agrave', 'Atilde', 'Otilde', 'OE', 'oe', 'endash', 'emdash', 'quotedblleft', 'quotedblright', 'quoteleft',
  'quoteright', 'divide', 'lozenge', 'ydieresis', 'Ydieresis', 'fraction', 'currency', 'guilsinglleft',
  'guilsinglright', 'fi', 'fl', 'daggerdbl', 'periodcentered', 'quotesinglbase', 'quotedblbase', 'perthousand',
  'Acircumflex', 'Ecircumflex', 'Aacute', 'Edieresis', 'Egrave', 'Iacute', 'Icircumflex', 'Idieresis',
  'Igrave', 'Oacute', 'Ocircumflex', 'apple', 'Ograve', 'Uacute', 'Ucircumflex', 'Ugrave', 'dotlessi',
  'circumflex', 'tilde', 'macron', 'breve', 'dotaccent', 'ring', 'cedilla', 'hungarumlaut', 'ogonek',
  'caron', 'Lslash', 'lslash', 'Scaron', 'scaron', 'Zcaron', 'zcaron', 'brokenbar', 'Eth', 'eth',
  'Yacute', 'yacute', 'Thorn', 'thorn', 'minus', 'multiply', 'onesuperior', 'twosuperior', 'threesuperior',
  'onehalf', 'onequarter', 'threequarters', 'franc', 'Gbreve', 'gbreve', 'Idotaccent', 'Scedilla',
  'scedilla', 'Cacute', 'cacute', 'Ccaron', 'ccaron', 'dcroat'
];