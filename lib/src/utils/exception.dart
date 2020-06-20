class TableDataFormatException implements Exception {
  TableDataFormatException(this.message);

  final String message;

  @override
  String toString() => 'Table data format exception: $message';
}