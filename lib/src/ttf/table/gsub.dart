import 'dart:typed_data';

import '../../utils/ttf.dart';
import '../debugger.dart';
import 'abstract.dart';
import 'feature_list.dart';
import 'lookup.dart';
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
    final major = byteData.getUint16(entry.offset);
    final minor = byteData.getUint16(entry.offset + 2);
    final version = Revision(major, minor);

    final isV10 = version == const Revision(1, 0);

    if (!isV10) {
      TTFDebugger.debugUnsupportedTableVersion(kGSUBTag, version.int32value);
    }

    return GlyphSubstitutionTableHeader(
      major,
      minor,
      byteData.getUint16(entry.offset + 4),
      byteData.getUint16(entry.offset + 6),
      byteData.getUint16(entry.offset + 8),
      isV10 ? null : byteData.getUint32(entry.offset + 10),
    );
  }

  factory GlyphSubstitutionTableHeader.create() {
    return GlyphSubstitutionTableHeader(
      1,
      0,
      null,
      null,
      null,
      null
    );
  }

  final int majorVersion;
  final int minorVersion;
  final int scriptListOffset;
  final int featureListOffset;
  final int lookupListOffset;
  final int featureVariationsOffset;

  bool get isV10 => majorVersion == 1 && minorVersion == 0;
  
  int get size => isV10 ? 10 : 12;
}

class GlyphSubstitutionTable extends FontTable {
  GlyphSubstitutionTable(
    TableRecordEntry entry,
    this.header,
    this.scriptListTable,
    this.featureListTable,
    this.lookupListTable
  ) : super.fromTableRecordEntry(entry);

  factory GlyphSubstitutionTable.fromByteData(
    ByteData byteData, 
    TableRecordEntry entry,
  ) {
    final header = GlyphSubstitutionTableHeader.fromByteData(byteData, entry);

    final scriptListTable = ScriptListTable.fromByteData(byteData, entry.offset + header.scriptListOffset);
    final featureListTable = FeatureListTable.fromByteData(byteData, entry.offset + header.featureListOffset);
    final lookupListTable = LookupListTable.fromByteData(byteData, entry.offset + header.lookupListOffset);

    return GlyphSubstitutionTable(
      entry,
      header,
      scriptListTable,
      featureListTable,
      lookupListTable,
    );
  }

  factory GlyphSubstitutionTable.create() {
    final header = GlyphSubstitutionTableHeader.create();

    final scriptListTable = ScriptListTable.create();
    final featureListTable = FeatureListTable.create();
    final lookupListTable = LookupListTable.create();

    return GlyphSubstitutionTable(
      null,
      header,
      scriptListTable,
      featureListTable,
      lookupListTable,
    );
  }

  final GlyphSubstitutionTableHeader header;
  
  final ScriptListTable scriptListTable;
  final FeatureListTable featureListTable;
  final LookupListTable lookupListTable;

  @override
  ByteData encodeToBinary() {
    // TODO: implement encode
    throw UnimplementedError();
  }

  @override
  int get size => 
    header.size 
    + scriptListTable.size 
    + featureListTable.size 
    + lookupListTable.size;
}