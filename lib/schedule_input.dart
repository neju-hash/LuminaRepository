import 'package:flutter/material.dart';
import 'models/subject_schedule.dart';

class ScheduleInputScreen extends StatefulWidget {
  final List<String> subjects;

  const ScheduleInputScreen({super.key, required this.subjects});

  @override
  State<ScheduleInputScreen> createState() => _ScheduleInputScreenState();
}

class _ScheduleInputScreenState extends State<ScheduleInputScreen> {
  List<SubjectSchedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
  }

  void _initializeSchedules() {
    _schedules = widget.subjects
        .map((subject) => SubjectSchedule(subjectName: subject))
        .toList();
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

    // Navigate to calculator with schedules
    // You can pass schedules data to calculator if needed
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
            const Text(
              "Add time and type for each subject",
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'DMSans',
                fontSize: 14,
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
