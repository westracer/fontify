import 'dart:typed_data';

import '../../utils/ttf.dart';
import 'language_system.dart';

const kScriptRecordSize = 6;

/// Alphabetically ordered (by tag) list of script records
const _kDefaultScriptRecordList = [
  /// Default
  ScriptRecord('DFLT', null),
  
  /// Latin
  ScriptRecord('latn', null),
];

const _kDefaultLangSys = LanguageSystemTable(
  0,
  0xFFFF, // no required features
  1,
  [0]
);

const _kDefaultScriptTable = ScriptTable(
  4,
  0,
  [],
  [], 
  _kDefaultLangSys
);

class ScriptRecord {
  const ScriptRecord(
    this.scriptTag,
    this.scriptOffset
  );

  factory ScriptRecord.fromByteData(ByteData byteData, int offset) {    
    return ScriptRecord(
      convertTagToString(Uint8List.view(byteData.buffer, offset, 4)),
      byteData.getUint16(offset + 4),
    );
  }

  final String scriptTag;
  final int scriptOffset;

  int get size => kScriptRecordSize;
}

class ScriptTable {
  const ScriptTable(
    this.defaultLangSysOffset,
    this.langSysCount,
    this.langSysRecords,
    this.langSysTables,
    this.defaultLangSys,
  );

  factory ScriptTable.fromByteData(
    ByteData byteData, 
    int offset,
    ScriptRecord record
  ) {
    offset += record.scriptOffset;

    final defaultLangSysOffset = byteData.getUint16(offset);
    LanguageSystemTable defaultLangSys;
    if (defaultLangSysOffset != 0) {
      defaultLangSys = LanguageSystemTable.fromByteData(byteData, offset + defaultLangSysOffset);
    }

    final langSysCount = byteData.getUint16(offset + 2);
    final langSysRecords = List.generate(
      langSysCount,
      (i) => LanguageSystemRecord.fromByteData(byteData, offset + 4 + kLangSysRecordSize * i)
    );
    final langSysTables = langSysRecords
      .map((r) => LanguageSystemTable.fromByteData(byteData, offset + r.langSysOffset))
      .toList();
    
    return ScriptTable(
      defaultLangSysOffset,
      langSysCount,
      langSysRecords,
      langSysTables,
      defaultLangSys,
    );
  }

  final int defaultLangSysOffset;
  final int langSysCount;
  final List<LanguageSystemRecord> langSysRecords;

  final List<LanguageSystemTable> langSysTables;
  final LanguageSystemTable defaultLangSys;

  int get size {
    final recordListSize = langSysRecords.fold<int>(0, (p, r) => p + r.size);
    final tableListSize = langSysTables.fold<int>(0, (p, t) => p + t.size);

    return 4 + (defaultLangSys?.size ?? 0) + recordListSize + tableListSize;
  }
}

class ScriptListTable {
  ScriptListTable(
    this.scriptCount,
    this.scriptRecords,
    this.scriptTables
  );

  factory ScriptListTable.fromByteData(ByteData byteData, int offset) {
    final scriptCount = byteData.getUint16(offset);
    final scriptRecords = List.generate(
      scriptCount, 
      (i) => ScriptRecord.fromByteData(byteData, offset + 2 + kScriptRecordSize * i)
    );
    final scriptTables = List.generate(
      scriptCount,
      (i) => ScriptTable.fromByteData(byteData, offset, scriptRecords[i])
    );
    
    return ScriptListTable(scriptCount, scriptRecords, scriptTables);
  }

  factory ScriptListTable.create() {
    final scriptCount = _kDefaultScriptRecordList.length;

    return ScriptListTable(
      scriptCount,
      _kDefaultScriptRecordList,
      List.generate(scriptCount, (index) => _kDefaultScriptTable)
    );
  }

  final int scriptCount;
  final List<ScriptRecord> scriptRecords;

  final List<ScriptTable> scriptTables;

  int get size {
    final recordListSize = scriptRecords.fold<int>(0, (p, r) => p + r.size);
    final tableListSize = scriptTables.fold<int>(0, (p, t) => p + t.size);

    return 2 + recordListSize + tableListSize;
  }
}