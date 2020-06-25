import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../common/codable/binary.dart';
import '../utils/exception.dart';
import '../utils/ttf.dart';

import 'defaults.dart';
import 'reader.dart';
import 'table/abstract.dart';
import 'table/all.dart';
import 'table/glyph/simple.dart';
import 'table/offset.dart';

/// Ordered list of table tags for encoding
const _kTableTagsToEncode = {
  kHeadTag, kHheaTag, kMaxpTag, kOS2Tag, kHmtxTag, kCmapTag, kLocaTag, kGlyfTag, kNameTag, kPostTag, kGSUBTag
};

class TrueTypeFont implements BinaryCodable {
  TrueTypeFont(this.offsetTable, this.tableMap);

  factory TrueTypeFont.fromByteData(ByteData byteData) {
    final reader = TTFReader.fromByteData(byteData);
    return reader.read();
  }

  // TODO: introduce generic glyph class later
  // TODO: pass list of char codes
  factory TrueTypeFont.createFromGlyphs({
    @required List<SimpleGlyph> glyphList, 
    @required String fontName,
    List<String> glyphNameList,
    String description,
    Revision revision = kDefaultFontRevision,
    String achVendID = kDefaultAchVendID,
  }) {
    if (glyphNameList != null && glyphNameList.length != glyphList.length) {
      throw TableDataFormatException(
        'Lengths of glyph list and glyph name list must be same'
      );
    }

    final glyf = GlyphDataTable.fromGlyphs(glyphList);
    final head = HeaderTable.create(glyf, revision);
    final loca = IndexToLocationTable.create(head.indexToLocFormat, glyf.glyphList.length);
    final hmtx = HorizontalMetricsTable.create(glyf);
    final hhea = HorizontalHeaderTable.create(glyf, hmtx, head);
    final post = PostScriptTable.create(glyphNameList);
    final name = NamingTable.create(fontName, description, revision);
    final maxp = MaximumProfileTable.create(glyf);
    final cmap = CharacterToGlyphTable.create(glyf.glyphList.length);
    final gsub = GlyphSubstitutionTable.create();
    final os2  = OS2Table.create(hmtx, head, hhea, cmap, gsub, achVendID);

    final tables = {
      kGlyfTag: glyf,
      kLocaTag: loca,
      kCmapTag: cmap,
      kMaxpTag: maxp,
      kHeadTag: head,
      kHmtxTag: hmtx,
      kHheaTag: hhea,
      kPostTag: post,
      kNameTag: name,
      kGSUBTag: gsub,
      kOS2Tag:  os2,
    };

    final offsetTable = OffsetTable.create(tables.length);

    return TrueTypeFont(offsetTable, tables);
  }
  
  final OffsetTable offsetTable;
  final Map<String, FontTable> tableMap;

  HeaderTable get head => tableMap[kHeadTag] as HeaderTable;
  MaximumProfileTable get maxp => tableMap[kMaxpTag] as MaximumProfileTable;
  IndexToLocationTable get loca => tableMap[kLocaTag] as IndexToLocationTable;
  GlyphDataTable get glyf => tableMap[kGlyfTag] as GlyphDataTable;
  GlyphSubstitutionTable get gsub => tableMap[kGSUBTag] as GlyphSubstitutionTable;
  OS2Table get os2 => tableMap[kOS2Tag] as OS2Table;
  PostScriptTable get post => tableMap[kPostTag] as PostScriptTable;
  NamingTable get name => tableMap[kNameTag] as NamingTable;
  CharacterToGlyphTable get cmap => tableMap[kCmapTag] as CharacterToGlyphTable;
  HorizontalHeaderTable get hhea => tableMap[kHheaTag] as HorizontalHeaderTable;
  HorizontalMetricsTable get hmtx => tableMap[kHmtxTag] as HorizontalMetricsTable;

  @override
  void encodeToBinary(ByteData byteData, int offset) {
    // TODO: implement encodeToBinary
    int currentEntryOffset = kOffsetTableLength;
    int currentTableOffset = kOffsetTableLength + entryListSize;

    for (final tag in _kTableTagsToEncode) {
      try {
        final table = tableMap[tag]
          ..encodeToBinary(byteData, currentTableOffset);

        final tableSize = table.size;
        
        final encodedTable = ByteData.sublistView(byteData, currentTableOffset, currentTableOffset + tableSize);
        table.entry = TableRecordEntry(tag, calculateTableChecksum(encodedTable), currentTableOffset, tableSize);

        table.entry.encodeToBinary(byteData, currentEntryOffset);

        currentEntryOffset += kTableRecordEntryLength;
        currentTableOffset += getPaddedTableSize(tableSize);
      } on UnimplementedError {
        // TODO: remove when done
      }
    }

    offsetTable.encodeToBinary(byteData, offset);
  }

  int get entryListSize => kTableRecordEntryLength * tableMap.length;

  int get tableListSize => tableMap.values.fold<int>(0, (p, t) => p + getPaddedTableSize(t.size));

  @override
  int get size => kOffsetTableLength + entryListSize + tableListSize;
}