class TTFDebugger {
  static void debug(String message) => print(message); // ignore: avoid_print

  static void debugUnsupportedTable(String tableName) => 
    debug('Unsupported table: $tableName');

  static void debugUnsupportedTableVersion(String tableName, int version) => 
    debug('Unsupported $tableName table version: $version');

  static void debugUnsupportedTableFormat(String tableName, int format) => 
    debug('Unsupported $tableName table format: $format');

  static void debugUnsupportedFeature(String featureDescription) => 
    debug('Unsupported feature: $featureDescription');
}