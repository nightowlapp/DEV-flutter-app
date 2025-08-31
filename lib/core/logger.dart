import 'package:logger/logger.dart';

final Logger _logger = Logger(
  printer: PrettyPrinter(methodCount: 1, colors: true, printEmojis: true),
);

void logD(String message) => _logger.d(message);
void logI(String message) => _logger.i(message);
void logW(String message) => _logger.w(message);
void logE(String message, Object error, StackTrace? stack) =>
    _logger.e(message, error: error, stackTrace: stack);
