import '../utils/logger.dart';

class OTFDebugger {
  static void _debug(String message) => logger.w(message);

  static void debugUnsupportedTable(String tableName) =>
      _debug('Unsupported table: $tableName');

  static void debugUnsupportedTableVersion(String tableName, int version) =>
      _debug('Unsupported $tableName table version: $version');

  static void debugUnsupportedTableFormat(String tableName, int format) =>
      _debug('Unsupported $tableName table format: $format');

  static void debugUnsupportedFeature(String featureDescription) =>
      _debug('Unsupported feature: $featureDescription');
}
