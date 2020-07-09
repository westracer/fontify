import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../common/calculatable_offsets.dart';
import '../common/codable/binary.dart';
import '../common/generic_glyph.dart';
import '../utils/exception.dart';
import '../utils/ttf.dart';

import 'defaults.dart';
import 'reader.dart';
import 'table/abstract.dart';
import 'table/all.dart';
import 'table/offset.dart';

/// Ordered list of table tags for encoding (Optimized Table Ordering)
const _kTableTagsToEncode = {
  kHeadTag, kHheaTag, kMaxpTag, kOS2Tag, kHmtxTag, kCmapTag, kLocaTag, kGlyfTag, kCFF2Tag, kNameTag, kPostTag, kGSUBTag
};

class TrueTypeFont implements BinaryCodable {
  TrueTypeFont(this.offsetTable, this.tableMap);

  factory TrueTypeFont.fromByteData(ByteData byteData) {
    final reader = TTFReader.fromByteData(byteData);
    return reader.read();
  }

  // TODO: pass list of char codes
  factory TrueTypeFont.createFromGlyphs({
    @required List<GenericGlyph> glyphList, 
    @required String fontName,
    List<String> glyphNameList,
    String description,
    Revision revision,
    String achVendID,
    bool useCFF2 = true,
  }) {
    if (glyphNameList != null && glyphNameList.length != glyphList.length) {
      throw TableDataFormatException(
        'Lengths of glyph list and glyph name list must be same'
      );
    }

    revision ??= kDefaultFontRevision;
    achVendID ??= kDefaultAchVendID;

    // A power of two is recommended only for TrueType outlines
    final unitsPerEm = useCFF2 ? kDefaultOpenTypeUnitsPerEm : kDefaultTrueTypeUnitsPerEm;
    
    final ascender = unitsPerEm - kDefaultBaselineExtension;

    // TODO: resize glyphs according to ascender/descender
    final fullGlyphList = [
      ...generateDefaultGlyphList(ascender),
      ...glyphList,
    ];

    final glyf = GlyphDataTable.fromGlyphs(fullGlyphList);
    final head = HeaderTable.create(glyf, revision, unitsPerEm);
    final loca = IndexToLocationTable.create(head.indexToLocFormat, glyf);
    final hmtx = HorizontalMetricsTable.create(glyf, unitsPerEm);
    final hhea = HorizontalHeaderTable.create(glyf, hmtx, ascender);
    final post = PostScriptTable.create(glyphNameList);
    final name = NamingTable.create(fontName, description, revision);
    final maxp = MaximumProfileTable.create(glyf, useCFF2);
    final cmap = CharacterToGlyphTable.create(glyphList.length);
    final gsub = GlyphSubstitutionTable.create();
    final os2  = OS2Table.create(hmtx, head, hhea, cmap, gsub, achVendID);

    final cff2 = useCFF2 ? CFF2Table.create(fullGlyphList) : null;

    final tables = {
      if (!useCFF2) 
        ...{
          kGlyfTag: glyf,
          kLocaTag: loca,
        },
      if (useCFF2)
        kCFF2Tag: cff2,
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

    final offsetTable = OffsetTable.create(tables.length, useCFF2);

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
  CFF2Table get cff2 => tableMap[kCFF2Tag] as CFF2Table;

  @override
  void encodeToBinary(ByteData byteData) {
    int currentTableOffset = kOffsetTableLength + entryListSize;

    final entryList = <TableRecordEntry>[];

    for (final tag in _kTableTagsToEncode) {
      final table = tableMap[tag];

      if (table == null) {
        continue;
      }

      if (table is CalculatableOffsets) {
        (table as CalculatableOffsets).recalculateOffsets();
      }

      final tableSize = table.size;

      table.encodeToBinary(byteData.sublistView(currentTableOffset, tableSize));
      final encodedTable = ByteData.sublistView(byteData, currentTableOffset, currentTableOffset + tableSize);

      table.entry = TableRecordEntry(tag, calculateTableChecksum(encodedTable), currentTableOffset, tableSize);
      entryList.add(table.entry);

      currentTableOffset += getPaddedTableSize(tableSize);
    }

    // The directory entry tags must be in ascending order
    entryList.sort((e1, e2) => e1.tag.compareTo(e2.tag));

    for (int i = 0; i < entryList.length; i++) {
      final entryOffset = kOffsetTableLength + i * kTableRecordEntryLength;
      final entryByteData = byteData.sublistView(entryOffset, kTableRecordEntryLength);
      entryList[i].encodeToBinary(entryByteData);
    }

    offsetTable.encodeToBinary(byteData.sublistView(0, kOffsetTableLength));

    // Setting checksum for whole font in the head table
    final fontChecksum = calculateFontChecksum(byteData);
    byteData.setUint32(head.entry.offset + 8, fontChecksum);
  }

  int get entryListSize => kTableRecordEntryLength * tableMap.length;

  int get tableListSize => tableMap.values.fold<int>(0, (p, t) => p + getPaddedTableSize(t.size));

  @override
  int get size => kOffsetTableLength + entryListSize + tableListSize;
}