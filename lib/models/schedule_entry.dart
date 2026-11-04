/// Represents a single schedule entry extracted from a RAF document
class ScheduleEntry {
  /// Subject code (e.g., "CS101", "MATH200")
  final String? subjectCode;

  /// Full subject name (e.g., "Mobile Programming")
  final String? subjectName;

  /// Time of the class (e.g., "7:30-9:00", "13:00-15:00")
  final String? time;

  /// Day(s) of the week (e.g., "MWF", "TTH", "Monday")
  final String? day;

  /// Instructor name (e.g., "Jonell Verano")
  final String? instructor;

  /// Room/location (e.g., "Room 301", "Lab A")
  final String? room;

  /// Number of units for this subject
  final double? units;

  /// Whether this is a laboratory class
  final bool isLab;

  /// Overall confidence score for this schedule entry (0.0 to 1.0)
  final double confidence;

  /// Creates a new schedule entry
  ///
  /// [subjectCode] - The subject code
  /// [subjectName] - The full subject name
  /// [time] - The class time
  /// [day] - The day(s) of the week
  /// [instructor] - The instructor name
  /// [room] - The room/location
  /// [units] - Number of units
  /// [isLab] - Whether this is a lab class (defaults to false)
  /// [confidence] - Overall confidence score (defaults to 1.0)
  ScheduleEntry({
    this.subjectCode,
    this.subjectName,
    this.time,
    this.day,
    this.instructor,
    this.room,
    this.units,
    this.isLab = false,
    this.confidence = 1.0,
  }) : assert(confidence >= 0.0 && confidence <= 1.0,
            'Confidence must be between 0.0 and 1.0');

  /// Validates if this schedule entry has the minimum required information
  ///
  /// Returns true if at least subjectCode and time exist
  bool isValid() {
    return subjectCode != null &&
        subjectCode!.isNotEmpty &&
        time != null &&
        time!.isNotEmpty;
  }

  /// Converts this schedule entry to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'time': time,
      'day': day,
      'instructor': instructor,
      'room': room,
      'units': units,
      'isLab': isLab,
      'confidence': confidence,
    };
  }

  /// Creates a schedule entry from a JSON map
  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      subjectCode: json['subjectCode'] as String?,
      subjectName: json['subjectName'] as String?,
      time: json['time'] as String?,
      day: json['day'] as String?,
      instructor: json['instructor'] as String?,
      room: json['room'] as String?,
      units: json['units'] != null ? (json['units'] as num).toDouble() : null,
      isLab: json['isLab'] as bool? ?? false,
      confidence: json['confidence'] as double? ?? 1.0,
    );
  }

  /// Creates a copy of this schedule entry with updated fields
  ScheduleEntry copyWith({
    String? subjectCode,
    String? subjectName,
    String? time,
    String? day,
    String? instructor,
    String? room,
    double? units,
    bool? isLab,
    double? confidence,
  }) {
    return ScheduleEntry(
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      time: time ?? this.time,
      day: day ?? this.day,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      units: units ?? this.units,
      isLab: isLab ?? this.isLab,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'ScheduleEntry(subjectCode: $subjectCode, subjectName: $subjectName, '
        'time: $time, day: $day, instructor: $instructor, room: $room, '
        'units: $units, isLab: $isLab, confidence: ${confidence.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScheduleEntry &&
        other.subjectCode == subjectCode &&
        other.subjectName == subjectName &&
        other.time == time &&
        other.day == day &&
        other.instructor == instructor &&
        other.room == room &&
        other.units == units &&
        other.isLab == isLab &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return subjectCode.hashCode ^
        subjectName.hashCode ^
        time.hashCode ^
        day.hashCode ^
        instructor.hashCode ^
        room.hashCode ^
        units.hashCode ^
        isLab.hashCode ^
        confidence.hashCode;
  }
}
