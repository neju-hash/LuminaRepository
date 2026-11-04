import 'package:flutter/material.dart';
import 'models/subject_schedule.dart';
import 'models/schedule_entry.dart';
import 'calculator.dart';

class ScheduleInputScreen extends StatefulWidget {
  final List<String> subjects;
  final List<ScheduleEntry>? detectedSchedules;

  const ScheduleInputScreen({
    super.key, 
    required this.subjects,
    this.detectedSchedules,
  });

  @override
  State<ScheduleInputScreen> createState() => _ScheduleInputScreenState();
}

class _ScheduleInputScreenState extends State<ScheduleInputScreen> {
  List<SubjectSchedule> _schedules = [];
  final Map<int, String> _instructors = {}; // index -> instructor name
  final Map<int, String> _rooms = {}; // index -> room number

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
  }

  void _initializeSchedules() {
    if (widget.detectedSchedules != null && widget.detectedSchedules!.isNotEmpty) {
      // Pre-fill from detected schedule entries
      _schedules = [];
      for (int i = 0; i < widget.detectedSchedules!.length; i++) {
        final entry = widget.detectedSchedules![i];
        final schedule = SubjectSchedule(
          subjectName: entry.subjectName ?? entry.subjectCode ?? 'Unknown Subject',
        );
        
        // Parse and set time if available
        if (entry.time != null) {
          final times = _parseTimeRange(entry.time!);
          if (times != null) {
            schedule.startTime = times['start'];
            schedule.endTime = times['end'];
          }
        }
        
        // Set day if available
        if (entry.day != null) {
          schedule.day = entry.day;
        }
        
        // Store instructor and room separately
        if (entry.instructor != null) {
          _instructors[i] = entry.instructor!;
        }
        if (entry.room != null) {
          _rooms[i] = entry.room!;
        }
        
        // Auto-detect schedule type from isLab flag or duration
        if (entry.isLab) {
          schedule.scheduleType = 'Lab';
        } else {
          final suggested = schedule.suggestScheduleType();
          if (suggested != "Unknown") {
            schedule.scheduleType = suggested;
          }
        }
        
        _schedules.add(schedule);
      }
    } else {
      // Fallback to simple subject list
      _schedules = widget.subjects
          .map((subject) => SubjectSchedule(subjectName: subject))
          .toList();
    }
  }

  /// Parse time range string like "7:30-9:00" or "7:30 AM - 9:00 AM"
  Map<String, TimeOfDay>? _parseTimeRange(String timeStr) {
    try {
      // Remove extra spaces and normalize
      final cleaned = timeStr.trim().replaceAll(RegExp(r'\s+'), ' ');
      
      // Split by common separators (-, –, —)
      final parts = cleaned.split(RegExp(r'[-–—]'));
      if (parts.length != 2) return null;
      
      final startStr = parts[0].trim();
      final endStr = parts[1].trim();
      
      final startTime = _parseTime(startStr);
      final endTime = _parseTime(endStr);
      
      if (startTime != null && endTime != null) {
        return {'start': startTime, 'end': endTime};
      }
    } catch (e) {
      debugPrint('Error parsing time range: $timeStr - $e');
    }
    return null;
  }

  /// Parse single time string like "7:30", "7:30 AM", "09:00"
  TimeOfDay? _parseTime(String timeStr) {
    try {
      // Remove AM/PM and extra spaces
      var cleaned = timeStr.trim().toUpperCase();
      final hasAM = cleaned.contains('AM');
      final hasPM = cleaned.contains('PM');
      cleaned = cleaned.replaceAll(RegExp(r'[AP]M'), '').trim();
      
      // Split by colon
      final parts = cleaned.split(':');
      if (parts.length != 2) return null;
      
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Convert to 24-hour format if needed
      if (hasPM && hour < 12) {
        hour += 12;
      } else if (hasAM && hour == 12) {
        hour = 0;
      }
      
      // If no AM/PM specified, assume:
      // 7:00-11:59 = AM
      // 12:00-6:59 = PM (unless already in 24h format)
      // 7:00+ = already in 24h format
      if (!hasAM && !hasPM && hour < 7 && hour != 0) {
        hour += 12; // Assume afternoon classes
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('Error parsing time: $timeStr - $e');
      return null;
    }
  }

  Future<void> _selectTime(BuildContext context, int index, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color.fromARGB(255, 197, 215, 255),
              onPrimary: Color.fromARGB(255, 5, 7, 14),
              surface: Color.fromARGB(255, 5, 14, 36),
              onSurface: Color.fromARGB(255, 197, 215, 255),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _schedules[index].startTime = picked;
        } else {
          _schedules[index].endTime = picked;
        }
        
        // Auto-suggest schedule type based on duration
        final suggested = _schedules[index].suggestScheduleType();
        if (suggested != "Unknown") {
          _schedules[index].scheduleType = suggested;
        }
      });
    }
  }

  void _updateScheduleType(int index, String? newType) {
    if (newType != null) {
      setState(() {
        _schedules[index].scheduleType = newType;
      });
    }
  }

  void _proceedToCalculator() {
    // Check if at least one schedule has times set
    final hasSchedules = _schedules.any(
      (schedule) => schedule.startTime != null && schedule.endTime != null
    );

    if (!hasSchedules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set schedule times for at least one subject.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert SubjectSchedule to ScheduleEntry for calculator
    final scheduleEntries = _schedules.map((schedule) {
      return ScheduleEntry(
        subjectCode: null,
        subjectName: schedule.subjectName,
        time: schedule.getTimeRange(),
        day: schedule.day,
        instructor: _instructors[_schedules.indexOf(schedule)],
        room: _rooms[_schedules.indexOf(schedule)],
        units: null,
        isLab: schedule.scheduleType == 'Lab',
        confidence: 1.0,
      );
    }).toList();

    // Navigate to calculator with schedule entries
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GwaScreen(scheduleEntries: scheduleEntries),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 7, 14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule Details',
          style: TextStyle(
            color: Color.fromARGB(255, 197, 215, 255),
            fontFamily: 'DMSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Set Class Schedules",
              style: TextStyle(
                color: Color.fromARGB(255, 197, 215, 255),
                fontFamily: 'DMSans',
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.detectedSchedules != null && widget.detectedSchedules!.isNotEmpty
                  ? "Review and edit detected schedule data"
                  : "Add time and type for each subject",
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'DMSans',
                fontSize: 14,
              ),
            ),
            // Show detection success indicator
            if (widget.detectedSchedules != null && widget.detectedSchedules!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(51, 76, 175, 80), // 0.2 opacity
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color.fromARGB(255, 76, 175, 80),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color.fromARGB(255, 76, 175, 80),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.detectedSchedules!.length} schedule${widget.detectedSchedules!.length > 1 ? 's' : ''} detected automatically',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 76, 175, 80),
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 25),

            // Schedule Cards
            ..._schedules.asMap().entries.map((entry) {
              int index = entry.key;
              SubjectSchedule schedule = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildScheduleCard(schedule, index),
              );
            }),

            const SizedBox(height: 10),

            // Continue Button
            Center(
              child: ElevatedButton(
                onPressed: _proceedToCalculator,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(280, 70),
                  backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                  foregroundColor: const Color.fromARGB(255, 197, 215, 255),
                  textStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                child: const Text('Continue to Calculator'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(SubjectSchedule schedule, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color.fromARGB(76, 197, 215, 255),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Name with Icon
          Row(
            children: [
              Icon(
                schedule.getScheduleIcon(),
                color: schedule.getScheduleColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule.subjectName,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 197, 215, 255),
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Schedule Type Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 6.0),
                child: Text(
                  "Type",
                  style: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromARGB(76, 197, 215, 255),
                    width: 1.5,
                  ),
                ),
                child: DropdownButton<String>(
                  value: schedule.scheduleType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: const Color.fromARGB(255, 5, 14, 36),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color.fromARGB(255, 197, 215, 255),
                  ),
                  items: ['Lecture', 'Lab', 'Both'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            value == 'Lab'
                                ? Icons.science_outlined
                                : value == 'Lecture'
                                    ? Icons.menu_book_outlined
                                    : Icons.auto_awesome_outlined,
                            size: 18,
                            color: value == 'Lab'
                                ? const Color.fromARGB(255, 255, 152, 0)
                                : value == 'Lecture'
                                    ? const Color.fromARGB(255, 33, 150, 243)
                                    : const Color.fromARGB(255, 156, 39, 176),
                          ),
                          const SizedBox(width: 8),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => _updateScheduleType(index, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Time Pickers Row
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  "Start Time",
                  schedule.startTime,
                  () => _selectTime(context, index, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimePicker(
                  "End Time",
                  schedule.endTime,
                  () => _selectTime(context, index, false),
                ),
              ),
            ],
          ),

          // Duration Display
          if (schedule.getDurationMinutes() != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Duration: ${schedule.getDurationDisplay()}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Day Display (if detected)
          if (schedule.day != null && schedule.day!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color.fromARGB(255, 255, 152, 0),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Day: ${schedule.day}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 152, 0),
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Instructor Display (if detected)
          if (_instructors[index] != null && _instructors[index]!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    color: Color.fromARGB(255, 156, 39, 176),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Instructor: ${_instructors[index]}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 156, 39, 176),
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Room Display (if detected)
          if (_rooms[index] != null && _rooms[index]!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.meeting_room_outlined,
                    color: Color.fromARGB(255, 255, 193, 7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Room: ${_rooms[index]}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 193, 7),
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color.fromARGB(76, 197, 215, 255),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color.fromARGB(255, 197, 215, 255),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  time != null
                      ? SubjectSchedule(subjectName: '').formatTime(time)
                      : '--:--',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
