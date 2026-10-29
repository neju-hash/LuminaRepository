import 'package:flutter/material.dart';

class SubjectSchedule {
  final String subjectName;
  String scheduleType; // "Lab", "Lecture", or "Both"
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? day; // e.g., "MWF", "TTH", "SAT"
  
  SubjectSchedule({
    required this.subjectName,
    this.scheduleType = "Lecture",
    this.startTime,
    this.endTime,
    this.day,
  });

  // Calculate duration in minutes
  int? getDurationMinutes() {
    if (startTime == null || endTime == null) return null;
    
    int startMinutes = startTime!.hour * 60 + startTime!.minute;
    int endMinutes = endTime!.hour * 60 + endTime!.minute;
    
    return endMinutes - startMinutes;
  }

  // Auto-suggest type based on duration
  String suggestScheduleType() {
    final duration = getDurationMinutes();
    if (duration == null) return "Unknown";
    
    if (duration >= 120) return "Lab";      // 2+ hours → Lab
    if (duration <= 90) return "Lecture";   // ≤ 1.5 hours → Lecture
    return "Both";                          // In between
  }

  // Format time for display
  String formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Get formatted time range
  String getTimeRange() {
    if (startTime == null || endTime == null) return "No schedule set";
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }

  // Get duration display
  String getDurationDisplay() {
    final duration = getDurationMinutes();
    if (duration == null) return "";
    
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0 && minutes > 0) {
      return '$hours hr ${minutes} min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$minutes min';
    }
  }

  // Get icon based on schedule type
  IconData getScheduleIcon() {
    switch (scheduleType) {
      case "Lab":
        return Icons.science_outlined;
      case "Lecture":
        return Icons.menu_book_outlined;
      case "Both":
        return Icons.auto_awesome_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  // Get color based on schedule type
  Color getScheduleColor() {
    switch (scheduleType) {
      case "Lab":
        return const Color.fromARGB(255, 255, 152, 0); // Orange for Lab
      case "Lecture":
        return const Color.fromARGB(255, 33, 150, 243); // Blue for Lecture
      case "Both":
        return const Color.fromARGB(255, 156, 39, 176); // Purple for Both
      default:
        return Colors.grey;
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'subjectName': subjectName,
      'scheduleType': scheduleType,
      'startTime': startTime != null ? {'hour': startTime!.hour, 'minute': startTime!.minute} : null,
      'endTime': endTime != null ? {'hour': endTime!.hour, 'minute': endTime!.minute} : null,
      'day': day,
    };
  }

  // Create from JSON
  factory SubjectSchedule.fromJson(Map<String, dynamic> json) {
    return SubjectSchedule(
      subjectName: json['subjectName'],
      scheduleType: json['scheduleType'] ?? "Lecture",
      startTime: json['startTime'] != null
          ? TimeOfDay(hour: json['startTime']['hour'], minute: json['startTime']['minute'])
          : null,
      endTime: json['endTime'] != null
          ? TimeOfDay(hour: json['endTime']['hour'], minute: json['endTime']['minute'])
          : null,
      day: json['day'],
    );
  }

  // Create copy with updated fields
  SubjectSchedule copyWith({
    String? subjectName,
    String? scheduleType,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? day,
  }) {
    return SubjectSchedule(
      subjectName: subjectName ?? this.subjectName,
      scheduleType: scheduleType ?? this.scheduleType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      day: day ?? this.day,
    );
  }
}
