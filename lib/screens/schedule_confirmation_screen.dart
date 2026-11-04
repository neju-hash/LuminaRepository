import 'package:flutter/material.dart';
import '../models/schedule_entry.dart';

/// Screen for confirming and managing detected schedule entries
class ScheduleConfirmationScreen extends StatefulWidget {
  final List<ScheduleEntry> scheduleEntries;
  final Function(List<ScheduleEntry>) onSave;

  const ScheduleConfirmationScreen({
    super.key,
    required this.scheduleEntries,
    required this.onSave,
  });

  @override
  State<ScheduleConfirmationScreen> createState() =>
      _ScheduleConfirmationScreenState();
}

class _ScheduleConfirmationScreenState
    extends State<ScheduleConfirmationScreen> {
  late List<ScheduleEntry> _scheduleEntries;

  @override
  void initState() {
    super.initState();
    _scheduleEntries = List.from(widget.scheduleEntries);
  }

  /// Navigate to edit screen for existing entry
  Future<void> _editEntry(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ScheduleEntryForm(
          entry: _scheduleEntries[index],
        ),
      ),
    );

    if (result != null && result is ScheduleEntry) {
      setState(() {
        _scheduleEntries[index] = result;
      });
    }
  }

  /// Navigate to add screen for new entry
  Future<void> _addEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _ScheduleEntryForm(),
      ),
    );

    if (result != null && result is ScheduleEntry) {
      setState(() {
        _scheduleEntries.add(result);
      });
    }
  }

  /// Delete entry with undo option
  void _deleteEntry(int index) {
    final deletedEntry = _scheduleEntries[index];
    setState(() {
      _scheduleEntries.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedEntry.subjectCode ?? "Entry"} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _scheduleEntries.insert(index, deletedEntry);
            });
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Convert abbreviated days to full names
  String _formatDays(String? days) {
    if (days == null || days.isEmpty) return 'No days specified';

    final dayMap = {
      'M': 'Monday',
      'T': 'Tuesday',
      'W': 'Wednesday',
      'Th': 'Thursday',
      'F': 'Friday',
      'S': 'Saturday',
      'Su': 'Sunday',
    };

    // Handle common abbreviations
    if (days.contains('MWF')) {
      return 'Monday, Wednesday, Friday';
    } else if (days.contains('TTh') || days.contains('TH')) {
      return 'Tuesday, Thursday';
    } else if (days.contains('MW')) {
      return 'Monday, Wednesday';
    }

    // Try to parse individual letters
    final result = <String>[];
    for (var entry in dayMap.entries) {
      if (days.contains(entry.key)) {
        result.add(entry.value);
      }
    }

    return result.isNotEmpty ? result.join(', ') : days;
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
        title: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Confirm Schedule ',
                style: TextStyle(
                  color: Color.fromARGB(255, 197, 215, 255),
                  fontFamily: 'DMSans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: '(${_scheduleEntries.length} ${_scheduleEntries.length == 1 ? "subject" : "subjects"} detected)',
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _scheduleEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schedule entries',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'DMSans',
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add a subject',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontFamily: 'DMSans',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _scheduleEntries.length,
                    itemBuilder: (context, index) {
                      return _buildScheduleCard(index);
                    },
                  ),
          ),
          _buildSaveButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: const Color.fromARGB(255, 179, 217, 255),
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 5, 7, 14),
          size: 32,
        ),
      ),
    );
  }

  Widget _buildScheduleCard(int index) {
    final entry = _scheduleEntries[index];

    return Dismissible(
      key: Key('${entry.subjectCode}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      onDismissed: (_) => _deleteEntry(index),
      child: GestureDetector(
        onTap: () => _editEntry(index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFB3D9FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject code and name
              Row(
                children: [
                  const Text(
                    '📚 ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.subjectCode ?? "N/A"}${entry.subjectName != null ? " - ${entry.subjectName}" : ""}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 5, 14, 36),
                        fontFamily: 'DMSans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Confidence warning
                  if (entry.confidence < 0.8)
                    const Tooltip(
                      message: 'Low confidence detection',
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Time
              if (entry.time != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        '🕐 ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        entry.time!,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 5, 14, 36),
                          fontFamily: 'DMSans',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // Days
              if (entry.day != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        '📅 ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Expanded(
                        child: Text(
                          _formatDays(entry.day),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 5, 14, 36),
                            fontFamily: 'DMSans',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Instructor
              if (entry.instructor != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        '👤 ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        entry.instructor!,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 5, 14, 36),
                          fontFamily: 'DMSans',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // Room
              if (entry.room != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Text(
                        '📍 ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        entry.room!,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 5, 14, 36),
                          fontFamily: 'DMSans',
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              // Units and Lab/Lecture badge
              Row(
                children: [
                  if (entry.units != null) ...[
                    const Text(
                      '⭐ ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${entry.units} ${entry.units == 1 ? "unit" : "units"}',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 5, 14, 36),
                        fontFamily: 'DMSans',
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Lab/Lecture badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: entry.isLab
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.isLab ? '🔬 ' : '📖 ',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          entry.isLab ? 'Lab' : 'Lecture',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 14, 36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _scheduleEntries.isEmpty
                ? null
                : () {
                    widget.onSave(_scheduleEntries);
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFFB3D9FF),
              disabledBackgroundColor: Colors.grey.shade800,
              foregroundColor: const Color.fromARGB(255, 5, 14, 36),
              disabledForegroundColor: Colors.grey.shade600,
              textStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
            ),
            child: const Text('Save to Schedule'),
          ),
        ),
      ),
    );
  }
}

/// Simple form for editing/adding schedule entries
class _ScheduleEntryForm extends StatefulWidget {
  final ScheduleEntry? entry;

  const _ScheduleEntryForm({this.entry});

  @override
  State<_ScheduleEntryForm> createState() => _ScheduleEntryFormState();
}

class _ScheduleEntryFormState extends State<_ScheduleEntryForm> {
  late TextEditingController _subjectCodeController;
  late TextEditingController _subjectNameController;
  late TextEditingController _timeController;
  late TextEditingController _dayController;
  late TextEditingController _instructorController;
  late TextEditingController _roomController;
  late TextEditingController _unitsController;
  bool _isLab = false;

  @override
  void initState() {
    super.initState();
    _subjectCodeController =
        TextEditingController(text: widget.entry?.subjectCode ?? '');
    _subjectNameController =
        TextEditingController(text: widget.entry?.subjectName ?? '');
    _timeController = TextEditingController(text: widget.entry?.time ?? '');
    _dayController = TextEditingController(text: widget.entry?.day ?? '');
    _instructorController =
        TextEditingController(text: widget.entry?.instructor ?? '');
    _roomController = TextEditingController(text: widget.entry?.room ?? '');
    _unitsController =
        TextEditingController(text: widget.entry?.units?.toString() ?? '');
    _isLab = widget.entry?.isLab ?? false;
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _timeController.dispose();
    _dayController.dispose();
    _instructorController.dispose();
    _roomController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    if (_subjectCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject code is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entry = ScheduleEntry(
      subjectCode: _subjectCodeController.text,
      subjectName: _subjectNameController.text.isEmpty
          ? null
          : _subjectNameController.text,
      time: _timeController.text.isEmpty ? null : _timeController.text,
      day: _dayController.text.isEmpty ? null : _dayController.text,
      instructor: _instructorController.text.isEmpty
          ? null
          : _instructorController.text,
      room: _roomController.text.isEmpty ? null : _roomController.text,
      units: _unitsController.text.isEmpty
          ? null
          : double.tryParse(_unitsController.text),
      isLab: _isLab,
      confidence: widget.entry?.confidence ?? 1.0,
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 7, 14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.entry == null ? 'Add Subject' : 'Edit Subject',
          style: const TextStyle(
            color: Color.fromARGB(255, 197, 215, 255),
            fontFamily: 'DMSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFFB3D9FF),
                fontFamily: 'DMSans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildTextField('Subject Code *', _subjectCodeController),
            const SizedBox(height: 16),
            _buildTextField('Subject Name', _subjectNameController),
            const SizedBox(height: 16),
            _buildTextField('Time (e.g., 7:30-9:00)', _timeController),
            const SizedBox(height: 16),
            _buildTextField('Days (e.g., MWF, TTh)', _dayController),
            const SizedBox(height: 16),
            _buildTextField('Instructor', _instructorController),
            const SizedBox(height: 16),
            _buildTextField('Room', _roomController),
            const SizedBox(height: 16),
            _buildTextField('Units', _unitsController,
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'Laboratory Class',
                style: TextStyle(
                  color: Color.fromARGB(255, 197, 215, 255),
                  fontFamily: 'DMSans',
                  fontSize: 16,
                ),
              ),
              value: _isLab,
              onChanged: (value) {
                setState(() {
                  _isLab = value;
                });
              },
              activeThumbColor: const Color(0xFFB3D9FF),
              tileColor: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'DMSans',
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: 'DMSans',
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color.fromARGB(76, 197, 215, 255),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFB3D9FF),
            width: 2,
          ),
        ),
      ),
    );
  }
}
