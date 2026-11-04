import 'dart:ui';

/// Represents different types of entities that can be detected in a RAF (Registration Add Form)
enum EntityType {
  SUBJECT,
  TIME,
  INSTRUCTOR,
  DAY,
  ROOM,
  UNITS,
  HEADER,
  UNKNOWN,
}

/// Extension to provide color mapping for each entity type
extension EntityTypeColor on EntityType {
  /// Returns the color associated with this entity type for visual identification
  Color getColor() {
    switch (this) {
      case EntityType.SUBJECT:
        return const Color(0xFF4CAF50); // Green
      case EntityType.TIME:
        return const Color(0xFF2196F3); // Blue
      case EntityType.INSTRUCTOR:
        return const Color(0xFF9C27B0); // Purple
      case EntityType.DAY:
        return const Color(0xFFFF9800); // Orange
      case EntityType.ROOM:
        return const Color(0xFFFFC107); // Yellow
      case EntityType.UNITS:
        return const Color(0xFFF44336); // Red
      case EntityType.HEADER:
        return const Color(0xFF9E9E9E); // Gray
      case EntityType.UNKNOWN:
        return const Color(0x00000000); // Black transparent
    }
  }
}

/// Represents a detected entity in a RAF document with its bounding box and confidence level
class DetectedEntity {
  /// The text content of the detected entity
  final String text;

  /// The type/category of the detected entity
  final EntityType type;

  /// The bounding box coordinates of the detected entity in the image
  final Rect boundingBox;

  /// Confidence score of the detection (0.0 to 1.0)
  /// Higher values indicate higher confidence in the detection
  final double confidence;

  /// Creates a new detected entity
  ///
  /// [text] - The extracted text content
  /// [type] - The classified entity type
  /// [boundingBox] - The rectangular area where the entity was found
  /// [confidence] - Detection confidence score between 0.0 and 1.0
  DetectedEntity({
    required this.text,
    required this.type,
    required this.boundingBox,
    required this.confidence,
  }) : assert(confidence >= 0.0 && confidence <= 1.0,
            'Confidence must be between 0.0 and 1.0');

  /// Returns the color associated with this entity's type
  Color getColor() => type.getColor();

  @override
  String toString() {
    return 'DetectedEntity(text: $text, type: $type, confidence: ${confidence.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetectedEntity &&
        other.text == text &&
        other.type == type &&
        other.boundingBox == boundingBox &&
        other.confidence == confidence;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        type.hashCode ^
        boundingBox.hashCode ^
        confidence.hashCode;
  }
}
