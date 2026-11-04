import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'text_categorizer.dart';
import '../models/schedule_entry.dart';

/// Represents a detected table column with its position and type
class TableColumn {
  /// Column header text
  final String name;

  /// Center X coordinate of the column
  final double xPosition;

  /// Width of the column
  final double width;

  /// Entity type associated with this column
  final EntityType type;

  TableColumn({
    required this.name,
    required this.xPosition,
    required this.width,
    required this.type,
  });

  @override
  String toString() {
    return 'TableColumn(name: $name, xPosition: $xPosition, width: $width, type: $type)';
  }
}

/// Represents a detected table row with its position and cell data
class TableRow {
  /// Center Y coordinate of the row
  final double yPosition;

  /// Height of the row
  final double height;

  /// Cell data mapped by column name
  final Map<String, String> cells;

  TableRow({
    required this.yPosition,
    required this.height,
    required this.cells,
  });

  @override
  String toString() {
    return 'TableRow(yPosition: $yPosition, height: $height, cells: $cells)';
  }
}

/// Service for detecting and extracting structured table data from RAF schedules
///
/// This service analyzes OCR text results to identify table structure (columns and rows),
/// then extracts schedule data by mapping cells to their appropriate entity types.
class TableDetector {
  final TextCategorizer _categorizer = TextCategorizer();

  /// Detects table columns from recognized text
  ///
  /// Finds the header row in the top 15% of the image, extracts column headers,
  /// and clusters them by X-axis position to identify column boundaries.
  ///
  /// [recognizedText] - The OCR result from ML Kit
  ///
  /// Returns a list of detected TableColumn objects
  List<TableColumn> detectColumns(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return [];
    }

    // Calculate image bounds
    double minY = double.infinity;
    double maxY = 0;

    for (final block in recognizedText.blocks) {
      final blockTop = block.boundingBox.top;
      final blockBottom = block.boundingBox.bottom;
      if (blockTop < minY) minY = blockTop;
      if (blockBottom > maxY) maxY = blockBottom;
    }

    // Define header region (top 15% of image)
    final headerThreshold = minY + ((maxY - minY) * 0.15);

    // Extract header text elements
    List<_TextElement> headerElements = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // Check if line is in header region
        if (line.boundingBox.center.dy <= headerThreshold) {
          for (final element in line.elements) {
            final text = element.text.trim();
            if (text.isNotEmpty && _categorizer.isHeader(text)) {
              headerElements.add(_TextElement(
                text: text,
                boundingBox: element.boundingBox,
              ));
            }
          }
        }
      }
    }

    if (headerElements.isEmpty) {
      return [];
    }

    // Sort headers by X position
    headerElements.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    // Cluster headers by X position (±30px tolerance)
    List<List<_TextElement>> columnClusters = [];
    
    for (final element in headerElements) {
      bool addedToCluster = false;

      for (final cluster in columnClusters) {
        final clusterCenter = _getClusterCenterX(cluster);
        if ((element.boundingBox.center.dx - clusterCenter).abs() <= 30) {
          cluster.add(element);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        columnClusters.add([element]);
      }
    }

    // Create TableColumn objects
    List<TableColumn> columns = [];

    for (final cluster in columnClusters) {
      if (cluster.isEmpty) continue;

      // Use the most confident header text in the cluster
      final headerText = _getMostConfidentHeader(cluster);
      final xPosition = _getClusterCenterX(cluster);
      final width = _getClusterWidth(cluster);
      final type = matchHeaderToType(headerText);

      columns.add(TableColumn(
        name: headerText,
        xPosition: xPosition,
        width: width,
        type: type,
      ));
    }

    // Sort columns by X position for consistent ordering
    columns.sort((a, b) => a.xPosition.compareTo(b.xPosition));

    return columns;
  }

  /// Detects table rows from recognized text
  ///
  /// Skips the header row and clusters remaining text by Y-axis position
  /// to identify row boundaries and extract cell data.
  ///
  /// [recognizedText] - The OCR result from ML Kit
  ///
  /// Returns a list of detected TableRow objects
  List<TableRow> detectRows(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return [];
    }

    // Calculate image bounds
    double minY = double.infinity;
    double maxY = 0;

    for (final block in recognizedText.blocks) {
      final blockTop = block.boundingBox.top;
      final blockBottom = block.boundingBox.bottom;
      if (blockTop < minY) minY = blockTop;
      if (blockBottom > maxY) maxY = blockBottom;
    }

    // Define header region to skip (top 15% of image)
    final headerThreshold = minY + ((maxY - minY) * 0.15);

    // Extract data text elements (below header)
    List<_TextElement> dataElements = [];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // Skip header region
        if (line.boundingBox.center.dy > headerThreshold) {
          for (final element in line.elements) {
            final text = element.text.trim();
            if (text.isNotEmpty && !_categorizer.isHeader(text)) {
              dataElements.add(_TextElement(
                text: text,
                boundingBox: element.boundingBox,
              ));
            }
          }
        }
      }
    }

    if (dataElements.isEmpty) {
      return [];
    }

    // Sort by Y position
    dataElements.sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

    // Cluster by Y position (±10px tolerance for same row)
    List<List<_TextElement>> rowClusters = [];

    for (final element in dataElements) {
      bool addedToCluster = false;

      for (final cluster in rowClusters) {
        final clusterCenterY = _getClusterCenterY(cluster);
        if ((element.boundingBox.center.dy - clusterCenterY).abs() <= 10) {
          cluster.add(element);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        rowClusters.add([element]);
      }
    }

    // Create TableRow objects
    List<TableRow> rows = [];

    for (final cluster in rowClusters) {
      if (cluster.isEmpty) continue;

      // Sort elements in row by X position
      cluster.sort((a, b) => a.boundingBox.center.dx.compareTo(b.boundingBox.center.dx));

      final yPosition = _getClusterCenterY(cluster);
      final height = _getClusterHeight(cluster);

      // Create cells map - will be populated later when matched with columns
      Map<String, String> cells = {};
      
      // Store raw elements for later column matching
      for (final element in cluster) {
        cells[element.boundingBox.center.dx.toString()] = element.text;
      }

      rows.add(TableRow(
        yPosition: yPosition,
        height: height,
        cells: cells,
      ));
    }

    // Sort rows by Y position
    rows.sort((a, b) => a.yPosition.compareTo(b.yPosition));

    return rows;
  }

  /// Maps header text to entity type using fuzzy matching
  ///
  /// Performs case-insensitive matching against known header patterns:
  /// - Subject, Subj, Course → SUBJECT
  /// - Time, Schedule → TIME
  /// - Day, Days → DAY
  /// - Instructor, Instr, Teacher → INSTRUCTOR
  /// - Room, Rm → ROOM
  /// - Units, Cred, Credits → UNITS
  ///
  /// [headerText] - The header text to match
  ///
  /// Returns the matched EntityType or EntityType.unknown
  EntityType matchHeaderToType(String headerText) {
    final lower = headerText.toLowerCase();

    // Subject patterns
    if (lower.contains('subject') || lower.contains('subj') || lower.contains('course')) {
      return EntityType.subjectCode;
    }

    // Time patterns
    if (lower.contains('time') || lower.contains('schedule')) {
      return EntityType.time;
    }

    // Day patterns
    if (lower.contains('day')) {
      return EntityType.day;
    }

    // Instructor patterns
    if (lower.contains('instructor') || 
        lower.contains('instr') || 
        lower.contains('teacher') ||
        lower.contains('prof')) {
      return EntityType.instructorName;
    }

    // Room patterns
    if (lower.contains('room') || lower.contains('rm')) {
      return EntityType.roomNumber;
    }

    // Units patterns
    if (lower.contains('unit') || lower.contains('cred') || lower.contains('credit')) {
      return EntityType.units;
    }

    return EntityType.unknown;
  }

  /// Extracts schedule data from detected columns and rows
  ///
  /// Maps cell values to ScheduleEntry fields based on column types,
  /// validates entries, calculates confidence scores, and auto-detects lab classes.
  ///
  /// [columns] - Detected table columns
  /// [rows] - Detected table rows
  ///
  /// Returns a list of valid ScheduleEntry objects
  List<ScheduleEntry> extractScheduleData(
    List<TableColumn> columns,
    List<TableRow> rows,
  ) {
    List<ScheduleEntry> scheduleEntries = [];

    for (final row in rows) {
      // Match cells to columns by X position
      Map<EntityType, String> cellData = {};

      for (final cellEntry in row.cells.entries) {
        final cellX = double.tryParse(cellEntry.key);
        if (cellX == null) continue;

        final cellText = cellEntry.value;

        // Find the closest column
        TableColumn? matchedColumn;
        double minDistance = double.infinity;

        for (final column in columns) {
          final distance = (cellX - column.xPosition).abs();
          if (distance < minDistance && distance <= column.width / 2 + 30) {
            minDistance = distance;
            matchedColumn = column;
          }
        }

        if (matchedColumn != null && matchedColumn.type != EntityType.unknown) {
          // Append to existing data if already exists (multi-word cells)
          if (cellData.containsKey(matchedColumn.type)) {
            cellData[matchedColumn.type] = 
                '${cellData[matchedColumn.type]} $cellText';
          } else {
            cellData[matchedColumn.type] = cellText;
          }
        }
      }

      // Extract schedule entry fields
      String? subjectCode;
      String? subjectName;
      String? time;
      String? day;
      String? instructor;
      String? room;
      double? units;

      for (final entry in cellData.entries) {
        final type = entry.key;
        final value = entry.value.trim();

        switch (type) {
          case EntityType.subjectCode:
            // Try to parse subject code vs subject name
            if (_categorizer.isSubjectCode(value)) {
              subjectCode = value;
            } else {
              subjectName = value;
            }
            break;
          case EntityType.time:
            time = value;
            break;
          case EntityType.day:
            day = value;
            break;
          case EntityType.instructorName:
            instructor = value;
            break;
          case EntityType.roomNumber:
            room = value;
            break;
          case EntityType.units:
            units = double.tryParse(value);
            break;
          default:
            break;
        }
      }

      // Validation: must have at least SUBJECT + (TIME or DAY)
      final hasSubject = (subjectCode != null && subjectCode.isNotEmpty) ||
                         (subjectName != null && subjectName.isNotEmpty);
      final hasTimeOrDay = (time != null && time.isNotEmpty) || 
                           (day != null && day.isNotEmpty);

      if (!hasSubject || !hasTimeOrDay) {
        continue; // Skip invalid entries
      }

      // Calculate confidence based on completeness
      double confidence = 0.0;
      int fieldCount = 0;
      int totalFields = 7;

      if (subjectCode != null && subjectCode.isNotEmpty) {
        fieldCount++;
        confidence += _categorizer.getConfidence(subjectCode, EntityType.subjectCode);
      }
      if (subjectName != null && subjectName.isNotEmpty) fieldCount++;
      if (time != null && time.isNotEmpty) {
        fieldCount++;
        confidence += _categorizer.getConfidence(time, EntityType.time);
      }
      if (day != null && day.isNotEmpty) {
        fieldCount++;
        confidence += _categorizer.getConfidence(day, EntityType.day);
      }
      if (instructor != null && instructor.isNotEmpty) {
        fieldCount++;
        confidence += _categorizer.getConfidence(instructor, EntityType.instructorName);
      }
      if (room != null && room.isNotEmpty) {
        fieldCount++;
        confidence += _categorizer.getConfidence(room, EntityType.roomNumber);
      }
      if (units != null) fieldCount++;

      // Average confidence from filled fields
      confidence = fieldCount > 0 ? (confidence / fieldCount + fieldCount / totalFields) / 2 : 0.5;
      confidence = confidence.clamp(0.0, 1.0);

      // Auto-detect lab classes (duration ≥ 2 hours)
      bool isLab = false;
      if (time != null) {
        isLab = _isLabByDuration(time);
      }

      scheduleEntries.add(ScheduleEntry(
        subjectCode: subjectCode,
        subjectName: subjectName,
        time: time,
        day: day,
        instructor: instructor,
        room: room,
        units: units,
        isLab: isLab,
        confidence: confidence,
      ));
    }

    return scheduleEntries;
  }

  // Helper methods

  /// Get center X coordinate of a cluster
  double _getClusterCenterX(List<_TextElement> cluster) {
    if (cluster.isEmpty) return 0.0;
    double sum = 0;
    for (final element in cluster) {
      sum += element.boundingBox.center.dx;
    }
    return sum / cluster.length;
  }

  /// Get center Y coordinate of a cluster
  double _getClusterCenterY(List<_TextElement> cluster) {
    if (cluster.isEmpty) return 0.0;
    double sum = 0;
    for (final element in cluster) {
      sum += element.boundingBox.center.dy;
    }
    return sum / cluster.length;
  }

  /// Get width of a cluster
  double _getClusterWidth(List<_TextElement> cluster) {
    if (cluster.isEmpty) return 0.0;
    double minX = double.infinity;
    double maxX = 0;
    for (final element in cluster) {
      if (element.boundingBox.left < minX) minX = element.boundingBox.left;
      if (element.boundingBox.right > maxX) maxX = element.boundingBox.right;
    }
    return maxX - minX;
  }

  /// Get height of a cluster
  double _getClusterHeight(List<_TextElement> cluster) {
    if (cluster.isEmpty) return 0.0;
    double minY = double.infinity;
    double maxY = 0;
    for (final element in cluster) {
      if (element.boundingBox.top < minY) minY = element.boundingBox.top;
      if (element.boundingBox.bottom > maxY) maxY = element.boundingBox.bottom;
    }
    return maxY - minY;
  }

  /// Get the most confident header text from a cluster
  String _getMostConfidentHeader(List<_TextElement> cluster) {
    if (cluster.isEmpty) return '';
    
    String bestHeader = cluster.first.text;
    double bestConfidence = 0.0;

    for (final element in cluster) {
      final confidence = _categorizer.getConfidence(element.text, EntityType.header);
      if (confidence > bestConfidence) {
        bestConfidence = confidence;
        bestHeader = element.text;
      }
    }

    return bestHeader;
  }

  /// Determine if a time string represents a lab class (≥ 2 hours duration)
  bool _isLabByDuration(String timeString) {
    // Parse time range (e.g., "7:30-9:00" or "7:30 AM - 9:30 AM")
    final timePattern = RegExp(r'(\d{1,2}):(\d{2})\s*(?:AM|PM)?[\s\-–—]+(\d{1,2}):(\d{2})');
    final match = timePattern.firstMatch(timeString);

    if (match == null) return false;

    try {
      final startHour = int.parse(match.group(1)!);
      final startMinute = int.parse(match.group(2)!);
      final endHour = int.parse(match.group(3)!);
      final endMinute = int.parse(match.group(4)!);

      // Convert to minutes
      final startTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      // Calculate duration
      int duration = endTotalMinutes - startTotalMinutes;
      
      // Handle overnight case (unlikely for schedules, but safe)
      if (duration < 0) {
        duration += 24 * 60;
      }

      // Lab if duration >= 120 minutes (2 hours)
      return duration >= 120;
    } catch (e) {
      return false;
    }
  }
}

/// Internal helper class for text elements with bounding boxes
class _TextElement {
  final String text;
  final Rect boundingBox;

  _TextElement({
    required this.text,
    required this.boundingBox,
  });
}
