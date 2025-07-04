enum FlightStatus {
  scheduled('SCHEDULED'),
  delayed('DELAYED'),
  boarding('BOARDING'),
  departed('DEPARTED'),
  arrived('ARRIVED'),
  cancelled('CANCELLED'),
  diverted('DIVERTED');

  const FlightStatus(this.value);

  final String value;

  static FlightStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SCHEDULED':
        return FlightStatus.scheduled;
      case 'DELAYED':
        return FlightStatus.delayed;
      case 'BOARDING':
        return FlightStatus.boarding;
      case 'DEPARTED':
        return FlightStatus.departed;
      case 'ARRIVED':
        return FlightStatus.arrived;
      case 'CANCELLED':
        return FlightStatus.cancelled;
      case 'DIVERTED':
        return FlightStatus.diverted;
      default:
        throw ArgumentError('Invalid flight status: $value');
    }
  }

  String get displayName {
    switch (this) {
      case FlightStatus.scheduled:
        return '已排班';
      case FlightStatus.delayed:
        return '延誤';
      case FlightStatus.boarding:
        return '登機中';
      case FlightStatus.departed:
        return '已起飛';
      case FlightStatus.arrived:
        return '已抵達';
      case FlightStatus.cancelled:
        return '已取消';
      case FlightStatus.diverted:
        return '改降';
    }
  }

  bool get isActive {
    return this != FlightStatus.cancelled &&
        this != FlightStatus.arrived &&
        this != FlightStatus.diverted;
  }

  bool get allowsBoarding {
    return this == FlightStatus.scheduled ||
        this == FlightStatus.delayed ||
        this == FlightStatus.boarding;
  }

  bool get isTerminal {
    return this == FlightStatus.arrived ||
        this == FlightStatus.cancelled ||
        this == FlightStatus.diverted;
  }

  int get priority {
    switch (this) {
      case FlightStatus.boarding:
        return 5;
      case FlightStatus.delayed:
        return 4;
      case FlightStatus.scheduled:
        return 3;
      case FlightStatus.departed:
        return 2;
      case FlightStatus.cancelled:
        return 1;
      case FlightStatus.arrived:
      case FlightStatus.diverted:
        return 0;
    }
  }
}
