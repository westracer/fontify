class TableVersionException implements Exception {
  TableVersionException(this.tableName, this.version);
  
  final String tableName;
  final int version;

  @override
  String toString() => 'Unsupported $tableName table version: $version';
}