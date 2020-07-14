import 'package:logger/logger.dart';

export 'package:logger/logger.dart';

final Logger logger = Logger(
  filter: ProductionFilter(),
  printer: SimplePrinter(),
  level: Level.info,
);

extension LoggerExt on Logger {
  static final List<int> _loggedOnce = [];

  void logOnce(Level level, Object message) {
    final hashCode = message.hashCode;

    if (_loggedOnce.contains(hashCode)) {
      return;
    }
    
    log(level, message);
    _loggedOnce.add(hashCode);
  }
}