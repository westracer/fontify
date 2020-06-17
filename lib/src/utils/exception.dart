abstract class FontReaderException implements Exception {}

class UnsupportedTableVersionException implements FontReaderException {
  UnsupportedTableVersionException(this.tableName, this.version);
  
  final String tableName;
  final int version;

  @override
  String toString() => 'Unsupported $tableName table version: $version';
}

class UnsupportedTableException implements FontReaderException {
  UnsupportedTableException(this.tableName);
  
  final String tableName;

  @override
  String toString() => 'Unsupported table: $tableName';
}

class UnsupportedTableFormatException implements FontReaderException {
  UnsupportedTableFormatException(this.tableName, this.format);
  
  final String tableName;
  final int format;

  @override
  String toString() => 'Unsupported $tableName table format: $format';
}

class UnsupportedFeatureException implements FontReaderException {
  UnsupportedFeatureException(this.featureDescription);
  
  final String featureDescription;

  @override
  String toString() => 'Unsupported feature: $featureDescription';
}