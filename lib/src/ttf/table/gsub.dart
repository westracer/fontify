import 'dart:typed_data';

import 'abstract.dart';
import 'feature_list.dart';
import 'script_list.dart';
import 'table_record_entry.dart';

class GlyphSubstitutionTableHeader {
  GlyphSubstitutionTableHeader(
    this.majorVersion,
    this.minorVersion,
    this.scriptListOffset,
    this.featureListOffset,
    this.lookupListOffset,
    this.featureVariationsOffset
  );

  factory GlyphSubstitutionTableHeader.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry,
  ) {
    final minorVersion = byteData.getUint16(entry.offset + 2);
    final isV10 = byteData.getUint16(entry.offset + 2) == 0;

    return GlyphSubstitutionTableHeader(
      byteData.getUint16(entry.offset),
      minorVersion,
      byteData.getUint16(entry.offset + 4),
      byteData.getUint16(entry.offset + 6),
      byteData.getUint16(entry.offset + 8),
      isV10 ? null : byteData.getUint32(entry.offset + 10),
    );
  }

  final int majorVersion;
  final int minorVersion;
  final int scriptListOffset;
  final int featureListOffset;
  final int lookupListOffset;
  final int featureVariationsOffset;

  bool get isV10 => minorVersion == 0;
  
  int get size => isV10 ? 10 : 12;
}

class GlyphSubstitutionTable extends FontTable {
  GlyphSubstitutionTable(
    TableRecordEntry entry,
    this.header,
    this.scriptListTable,
    this.featureListTable,
  ) : super.fromTableRecordEntry(entry);

  factory GlyphSubstitutionTable.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry,
  ) {
    final header = GlyphSubstitutionTableHeader.fromByteData(byteData, entry);

    final scriptListTable = ScriptListTable.fromByteData(byteData, entry.offset + header.scriptListOffset);
    final featureListTable = FeatureListTable.fromByteData(byteData, entry.offset + header.featureListOffset);

    return GlyphSubstitutionTable(
      entry,
      header,
      scriptListTable,
      featureListTable,
    );
  }

  final GlyphSubstitutionTableHeader header;
  final ScriptListTable scriptListTable;
  final FeatureListTable featureListTable;
}