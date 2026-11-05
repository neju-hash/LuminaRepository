import 'package:flutter/material.dart';

class SubjectSchedule {
  String subjectName;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String scheduleType;
  DateTime? date; // Added to support the DatePicker
  String? days; // Added to store days like "TF", "M", "W"

  SubjectSchedule({
    required this.subjectName,
    this.startTime,
    this.endTime,
    this.scheduleType = 'Lecture',
    this.date,
    this.days,
  });

  String formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  int? getDurationMinutes() {
    if (startTime == null || endTime == null) return null;
    
    int startMinutes = startTime!.hour * 60 + startTime!.minute;
    int endMinutes = endTime!.hour * 60 + endTime!.minute;
    
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60; // Handle overnight wrap-around
    }
    
    return endMinutes - startMinutes;
  }

  String getDurationDisplay() {
    final minutes = getDurationMinutes();
    if (minutes == null) return '--';
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0) {
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    }
    return '${remainingMinutes}m';
  }

  String suggestScheduleType() {
    final minutes = getDurationMinutes();
    if (minutes == null) return 'Unknown';
    
    if (minutes >= 180) { // 3 hours or more usually means Lab
      return 'Lab';
    } else if (minutes <= 120) { // 2 hours or less usually means Lecture
      return 'Lecture';
    }
    return 'Both';
  }

  IconData getScheduleIcon() {
    switch (scheduleType) {
      case 'Lab':
        return Icons.science_outlined;
      case 'Lecture':
        return Icons.menu_book_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Color getScheduleColor() {
    switch (scheduleType) {
      case 'Lab':
        return const Color.fromARGB(255, 255, 152, 0);
      case 'Lecture':
        return const Color.fromARGB(255, 33, 150, 243);
      default:
        return const Color.fromARGB(255, 156, 39, 176);
    }
  }
}