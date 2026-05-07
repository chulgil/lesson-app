import 'package:flutter/material.dart';

import '../../domain/value_objects/clock_time.dart';

extension ClockTimeUiX on ClockTime {
  TimeOfDay toFlutterTimeOfDay() => TimeOfDay(hour: hour, minute: minute);
}

extension FlutterTimeOfDayDomainX on TimeOfDay {
  ClockTime toClockTime() => ClockTime(hour: hour, minute: minute);
}
