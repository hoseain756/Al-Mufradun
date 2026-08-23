import 'package:intl/intl.dart';

class ArabicTimeFormatter {
  ArabicTimeFormatter._();

  static final DateFormat _timeFormat = DateFormat('hh:mm a');

  static String formatTime(DateTime time) {
    return _timeFormat.format(time).replaceAll('AM', 'ص').replaceAll('PM', 'م');
  }
}
