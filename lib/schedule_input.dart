import 'package:flutter/material.dart';
import 'models/subject_schedule.dart';

class ScheduleInputScreen extends StatefulWidget {
  // Expects a list of maps with name, days, and time properties
  final List<Map<String, String>> subjects;

  const ScheduleInputScreen({super.key, required this.subjects});

  @override
  State<ScheduleInputScreen> createState() => _ScheduleInputScreenState();
}

class _ScheduleInputScreenState extends State<ScheduleInputScreen> {
  List<SubjectSchedule> _schedules = [];

  final List<String> _dayOptions = [
    'Select Day', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'MW', 'TTh', 'TF', 'FS'
  ];

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
  }

  void _initializeSchedules() {
    _schedules = widget.subjects.map((subjectData) {
      // 1. Grab cleanly separated values from Map
      String cleanName = subjectData['name'] ?? "Unknown Subject";
      String rawDays = subjectData['days'] ?? "";
      String rawTime = subjectData['time'] ?? "";

      TimeOfDay? parsedStartTime;
      TimeOfDay? parsedEndTime;
      String? parsedDays;

      // 2. Parse directly
      if (rawDays.isNotEmpty) {
        parsedDays = _mapExtractedDayToReadable(rawDays);
      }

      if (rawTime.isNotEmpty) {
        List<String> times = rawTime.split('-');
        if (times.length == 2) {
          parsedStartTime = _parseTimeOfDay(times[0]);
          parsedEndTime = _parseTimeOfDay(times[1]);
        }
      }

      SubjectSchedule schedule = SubjectSchedule(
        subjectName: cleanName,
        days: parsedDays,
      );

      schedule.startTime = parsedStartTime;
      schedule.endTime = parsedEndTime;

      if (parsedStartTime != null && parsedEndTime != null) {
        final suggested = schedule.suggestScheduleType();
        if (suggested != "Unknown") {
          schedule.scheduleType = suggested;
        }
      }

      return schedule;
    }).toList();
  }

  String _mapExtractedDayToReadable(String day) {
    switch (day.toUpperCase()) {
      case 'M': return 'Monday';
      case 'T': return 'Tuesday';
      case 'W': return 'Wednesday';
      case 'TH': return 'Thursday';
      case 'F': return 'Friday';
      case 'S': return 'Saturday';
      case 'TF': return 'TF';
      case 'MW': return 'MW';
      case 'TTH': return 'TTh';
      case 'FS': return 'FS';
      default: return day.isNotEmpty ? day : 'Select Day';
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      timeStr = timeStr.toUpperCase().replaceAll('O', '0').replaceAll(' ', '');
      final regex = RegExp(r'(\d{1,2}):(\d{2})([AP]M)');
      final match = regex.firstMatch(timeStr);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String period = match.group(3)!;

        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _selectTime(BuildContext context, int index, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_schedules[index].startTime ?? TimeOfDay.now())
          : (_schedules[index].endTime ?? TimeOfDay.now()),
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

  void _updateScheduleDay(int index, String? newDay) {
    if (newDay != null) {
      setState(() {
        _schedules[index].days = newDay == 'Select Day' ? null : newDay;
      });
    }
  }

  void _deleteSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  void _proceedToCalculator() {
    final hasSchedules = _schedules.any(
      (schedule) => schedule.startTime != null && schedule.endTime != null,
    );

    if (!hasSchedules || _schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add and set schedule times for at least one subject.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, _schedules);
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
          style: TextStyle(color: Color.fromARGB(255, 197, 215, 255), fontFamily: 'DMSans', fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text("Set Class Schedules", style: TextStyle(color: Color.fromARGB(255, 197, 215, 255), fontFamily: 'DMSans', fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Review extracted schedules or add your own", style: TextStyle(color: Colors.grey, fontFamily: 'DMSans', fontSize: 14)),
            const SizedBox(height: 25),

            if (_schedules.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("No schedules added.", style: TextStyle(color: Colors.grey))))
            else
              ..._schedules.asMap().entries.map((entry) {
                int index = entry.key;
                SubjectSchedule schedule = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _buildScheduleCard(schedule, index),
                );
              }),

            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _proceedToCalculator,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(280, 70), backgroundColor: const Color.fromARGB(255, 5, 14, 36), foregroundColor: const Color.fromARGB(255, 197, 215, 255),
                  textStyle: const TextStyle(fontFamily: 'DMSans', fontSize: 22, fontWeight: FontWeight.bold), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15.0))),
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
      width: double.infinity, padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color.fromARGB(76, 197, 215, 255), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(schedule.getScheduleIcon(), color: schedule.getScheduleColor(), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule.subjectName,
                  style: const TextStyle(color: Color.fromARGB(255, 197, 215, 255), fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteSchedule(index), tooltip: 'Delete Schedule', padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 15),

          _buildDayDropdown(schedule, index),
          const SizedBox(height: 15),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(left: 8.0, bottom: 6.0), child: Text("Type", style: TextStyle(color: Colors.grey, fontFamily: 'DMSans', fontSize: 12))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color.fromARGB(76, 197, 215, 255), width: 1.5)),
                child: DropdownButton<String>(
                  value: schedule.scheduleType, isExpanded: true, underline: const SizedBox(), dropdownColor: const Color.fromARGB(255, 5, 14, 36),
                  style: const TextStyle(color: Colors.white, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.bold),
                  icon: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 197, 215, 255)),
                  items: ['Lecture', 'Lab', 'Both'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            value == 'Lab' ? Icons.science_outlined : value == 'Lecture' ? Icons.menu_book_outlined : Icons.auto_awesome_outlined,
                            size: 18, color: value == 'Lab' ? const Color.fromARGB(255, 255, 152, 0) : value == 'Lecture' ? const Color.fromARGB(255, 33, 150, 243) : const Color.fromARGB(255, 156, 39, 176),
                          ),
                          const SizedBox(width: 8), Text(value),
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

          Row(
            children: [
              Expanded(child: _buildTimePicker("Start Time", schedule.startTime, () => _selectTime(context, index, true))),
              const SizedBox(width: 16),
              Expanded(child: _buildTimePicker("End Time", schedule.endTime, () => _selectTime(context, index, false))),
            ],
          ),

          if (schedule.getDurationMinutes() != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.grey, size: 16),
                  const SizedBox(width: 6),
                  Text('Duration: ${schedule.getDurationDisplay()}', style: const TextStyle(color: Colors.grey, fontFamily: 'DMSans', fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayDropdown(SubjectSchedule schedule, int index) {
    List<String> options = List.from(_dayOptions);
    if (schedule.days != null && !options.contains(schedule.days)) {
      options.add(schedule.days!);
    }
    String currentValue = schedule.days ?? 'Select Day';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 8.0, bottom: 6.0), child: Text("Day", style: TextStyle(color: Colors.grey, fontFamily: 'DMSans', fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color.fromARGB(76, 197, 215, 255), width: 1.5)),
          child: DropdownButton<String>(
            value: currentValue, isExpanded: true, underline: const SizedBox(), dropdownColor: const Color.fromARGB(255, 5, 14, 36),
            style: const TextStyle(color: Colors.white, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.bold),
            icon: const Icon(Icons.arrow_drop_down, color: Color.fromARGB(255, 197, 215, 255)),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_view_day, size: 18, color: Color.fromARGB(255, 197, 215, 255)),
                    const SizedBox(width: 8), Text(value),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => _updateScheduleDay(index, value),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 8.0, bottom: 6.0), child: Text(label, style: const TextStyle(color: Colors.grey, fontFamily: 'DMSans', fontSize: 12))),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color.fromARGB(76, 197, 215, 255), width: 1.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Color.fromARGB(255, 197, 215, 255), size: 18),
                const SizedBox(width: 8),
                Text(time != null ? SubjectSchedule(subjectName: '').formatTime(time) : '--:--', style: const TextStyle(color: Colors.white, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}