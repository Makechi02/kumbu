import 'package:intl/intl.dart';

final _key = DateFormat('yyyy-MM-dd');
final _pretty = DateFormat('EEEE, d MMMM y');
final _weekday = DateFormat('EEEE');
final _shortWeekday = DateFormat('EEE');
final _long = DateFormat('d MMMM y');
final _month = DateFormat('MMMM y');
final _dayNumber = DateFormat('d');

/// The writer's local calendar date as `yyyy-MM-dd`. Entries are keyed by this.
String dateKey(DateTime d) => _key.format(d);

String todayKey() => dateKey(DateTime.now());

DateTime _parse(String key) => DateTime.parse(key);

/// `2026-10-12` becomes `Monday, 12 October 2026`.
String prettyDate(String key) => _pretty.format(_parse(key));

/// `Monday`
String weekdayName(String key) => _weekday.format(_parse(key));

/// `Mon`
String shortWeekday(String key) => _shortWeekday.format(_parse(key));

/// `12 October 2026`
String longDate(String key) => _long.format(_parse(key));

/// `October 2026`
String monthLabel(String key) => _month.format(_parse(key));

/// `12`
String dayNumber(String key) => _dayNumber.format(_parse(key));
