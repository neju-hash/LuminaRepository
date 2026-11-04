import 'dart:ui';

/// Entity types that can be detected in RAF schedules
enum EntityType {
  time,
  day,
  subjectCode,
  instructorName,
  roomNumber,
  units,
  header,
  unknown,
}

/// Intelligent text categorization service for STI RAF schedule detection
/// 
/// This service uses pattern matching and context analysis to identify
/// schedule components from OCR text, specifically designed for STI
/// Registration and Assessment Forms (RAF).
class TextCategorizer {
  // Regex patterns for entity detection
  static final RegExp _timePattern = RegExp(
    r'\d{1,2}:\d{2}\s*(?:AM|PM)?(?:\s*[-–—]\s*\d{1,2}:\d{2}\s*(?:AM|PM)?)?',
    caseSensitive: false,
  );

  static final RegExp _dayPattern = RegExp(
    r'^(?:[MTWThFS]{1,5}|Mon|Tue|Wed|Thu|Fri|Sat|Sun)$',
    caseSensitive: false,
  );

  static final RegExp _subjectCodePattern = RegExp(
    r'^[A-Z]{2,6}[\s-]?\d{3,4}[A-Z]?$',
  );

  static final RegExp _instructorNamePattern = RegExp(
    r'^(?:(?:Prof|Dr|Engr|Mr|Ms|Atty)\.\s+)?[A-Z][a-z]+(?:\s+(?:Dela|De|Del|Von|Van))?\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?(?:\s+(?:Jr|Sr|III|IV|II))?\.?$',
  );

  static final RegExp _roomNumberPattern = RegExp(
    r'^(?:Room\s+)?[A-Z]{0,8}[-\s]?\d{2,4}[A-Z]?$|^(?:GYM|LIBRARY|AUDITORIUM|COVERED\s+COURT|COMLAB\d+|MACLAB\d?)$',
    caseSensitive: false,
  );

  static final RegExp _unitsPattern = RegExp(
    r'^[0-6](?:\.[05])?$',
  );

  // Header keywords for column identification
  static final List<String> _headerKeywords = [
    'subject',
    'code',
    'time',
    'day',
    'instructor',
    'room',
    'units',
    'subj',
    'instr',
    'prof',
    'schedule',
    'description',
  ];

  /// Main classification method that runs patterns in priority order
  /// 
  /// Analyzes the given text and returns the most confident EntityType match.
  /// Uses bounding box and context information to improve accuracy.
  /// 
  /// [text] - The OCR text to classify
  /// [boundingBox] - The bounding box coordinates of the text
  /// [context] - Surrounding text elements for context-aware classification
  /// 
  /// Returns the classified EntityType
  EntityType categorizeText(
    String text,
    Rect boundingBox,
    List<dynamic> context,
  ) {
    if (text.trim().isEmpty) {
      return EntityType.unknown;
    }

    final cleanText = text.trim();

    // Priority order for pattern matching
    // 1. Header detection (highest priority - defines structure)
    if (isHeader(cleanText)) {
      return EntityType.header;
    }

    // 2. Time patterns (distinctive format)
    if (isTimePattern(cleanText)) {
      return EntityType.time;
    }

    // 3. Day patterns (short, specific format)
    if (isDayPattern(cleanText)) {
      return EntityType.day;
    }

    // 4. Units (simple numeric, but specific range)
    if (isUnits(cleanText)) {
      return EntityType.units;
    }

    // 5. Subject code (alphanumeric pattern)
    if (isSubjectCode(cleanText)) {
      return EntityType.subjectCode;
    }

    // 6. Room number (can overlap with subject codes)
    if (isRoomNumber(cleanText)) {
      return EntityType.roomNumber;
    }

    // 7. Instructor name (most flexible pattern, check last)
    if (isInstructorName(cleanText)) {
      return EntityType.instructorName;
    }

    return EntityType.unknown;
  }

  /// Match time formats
  /// 
  /// Detects time patterns including:
  /// - 12-hour format with AM/PM
  /// - 24-hour format
  /// - Time ranges with various separators (-, –, —)
  /// 
  /// Examples: "7:30-9:00", "07:30 AM - 09:00 AM", "7:30"
  bool isTimePattern(String text) {
    return _timePattern.hasMatch(text);
  }

  /// Match day abbreviations
  /// 
  /// Detects day patterns including:
  /// - Single or combined letters (M, T, W, Th, F, S)
  /// - Full abbreviations (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
  /// 
  /// Examples: "MWF", "TTh", "MW", "Mon-Wed-Fri"
  bool isDayPattern(String text) {
    return _dayPattern.hasMatch(text);
  }

  /// Match course codes
  /// 
  /// Detects STI subject code patterns:
  /// - 2-6 uppercase letters followed by 3-4 digits
  /// - Optional letter suffix
  /// - Optional space or hyphen separator
  /// 
  /// Examples: "PROG1234", "CS101", "MATH 101", "IT-ELEC1"
  bool isSubjectCode(String text) {
    return _subjectCodePattern.hasMatch(text);
  }

  /// Match Philippine name patterns
  /// 
  /// Detects instructor names with:
  /// - Optional titles (Prof., Dr., Engr., Mr., Ms., Atty.)
  /// - Proper capitalization
  /// - Compound surnames (Dela, De, Del, Von, Van)
  /// - Suffixes (Jr., Sr., III, IV, II)
  /// 
  /// Examples: "Prof. Juan Dela Cruz", "Maria Santos", "Engr. Jose Reyes Jr."
  bool isInstructorName(String text) {
    return _instructorNamePattern.hasMatch(text);
  }

  /// Match STI room formats
  /// 
  /// Detects room numbers and special locations:
  /// - Standard room format: optional letters + numbers
  /// - Lab rooms (COMLAB, MACLAB)
  /// - Special venues (GYM, LIBRARY, AUDITORIUM, COVERED COURT)
  /// 
  /// Examples: "LAB-A", "R-205", "COMLAB1", "401", "GYM"
  bool isRoomNumber(String text) {
    return _roomNumberPattern.hasMatch(text);
  }

  /// Match credit hours
  /// 
  /// Detects unit values:
  /// - Integer values 0-6
  /// - Decimal values with .0 or .5
  /// 
  /// Examples: "3", "2.0", "1.5"
  bool isUnits(String text) {
    return _unitsPattern.hasMatch(text);
  }

  /// Match column headers
  /// 
  /// Detects table headers by matching against known keywords:
  /// - Subject, Code, Time, Day, Instructor, Room, Units
  /// - Case-insensitive
  /// - Supports partial matches (Subj, Instr, Prof)
  bool isHeader(String text) {
    final lowerText = text.toLowerCase();
    return _headerKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Return confidence score based on pattern strength
  /// 
  /// Calculates confidence (0.0-1.0) for a given text and entity type:
  /// - Strong regex match: 0.9-1.0
  /// - Partial match with context: 0.7-0.9
  /// - Weak match: 0.5-0.7
  /// 
  /// [text] - The text to evaluate
  /// [type] - The entity type to check confidence for
  /// 
  /// Returns confidence score between 0.0 and 1.0
  double getConfidence(String text, EntityType type) {
    if (text.trim().isEmpty) {
      return 0.0;
    }

    final cleanText = text.trim();

    switch (type) {
      case EntityType.time:
        // Strong match if contains AM/PM and time range
        if (cleanText.toUpperCase().contains('AM') ||
            cleanText.toUpperCase().contains('PM')) {
          if (cleanText.contains('-') ||
              cleanText.contains('–') ||
              cleanText.contains('—')) {
            return 1.0; // Complete time range with AM/PM
          }
          return 0.95; // Single time with AM/PM
        }
        return isTimePattern(cleanText) ? 0.85 : 0.0;

      case EntityType.day:
        // Strong match for common patterns
        final commonPatterns = ['MWF', 'TTH', 'MW', 'TH', 'SAT', 'SUN'];
        if (commonPatterns.contains(cleanText.toUpperCase())) {
          return 1.0;
        }
        return isDayPattern(cleanText) ? 0.9 : 0.0;

      case EntityType.subjectCode:
        // High confidence if matches standard STI pattern
        if (isSubjectCode(cleanText)) {
          // Higher confidence for longer codes
          return cleanText.length >= 6 ? 0.95 : 0.85;
        }
        return 0.0;

      case EntityType.instructorName:
        // Strong match with title
        if (cleanText.startsWith('Prof.') ||
            cleanText.startsWith('Dr.') ||
            cleanText.startsWith('Engr.')) {
          return 0.95;
        }
        // Medium confidence for name-like patterns
        if (isInstructorName(cleanText)) {
          // Higher confidence for longer names (likely full names)
          final words = cleanText.split(' ');
          return words.length >= 3 ? 0.85 : 0.75;
        }
        return 0.0;

      case EntityType.roomNumber:
        // High confidence for special venues
        final specialVenues = [
          'GYM',
          'LIBRARY',
          'AUDITORIUM',
          'COVERED COURT'
        ];
        if (specialVenues
            .any((venue) => cleanText.toUpperCase().contains(venue))) {
          return 1.0;
        }
        // Medium-high confidence for lab rooms
        if (cleanText.toUpperCase().startsWith('COMLAB') ||
            cleanText.toUpperCase().startsWith('MACLAB')) {
          return 0.95;
        }
        return isRoomNumber(cleanText) ? 0.85 : 0.0;

      case EntityType.units:
        // Very high confidence for valid unit values
        if (isUnits(cleanText)) {
          final value = double.tryParse(cleanText);
          if (value != null && value >= 1.0 && value <= 6.0) {
            return 0.95;
          }
          return 0.8; // Valid but unusual unit value
        }
        return 0.0;

      case EntityType.header:
        // Check for exact keyword matches
        final lowerText = cleanText.toLowerCase();
        final exactMatches = [
          'subject',
          'code',
          'time',
          'day',
          'instructor',
          'room',
          'units'
        ];
        if (exactMatches.any((keyword) => lowerText == keyword)) {
          return 1.0;
        }
        // Partial match
        if (isHeader(cleanText)) {
          return 0.85;
        }
        return 0.0;

      case EntityType.unknown:
        return 0.0;
    }
  }
}
