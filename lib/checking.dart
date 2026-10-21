import 'package:flutter/material.dart';
import 'dashboard.dart';

// Holds the controllers for one schedule card
class _ScheduleEntry {
  final subject = TextEditingController();
  final date = TextEditingController();
  final time = TextEditingController();
  final room = TextEditingController();
  final instructor = TextEditingController();

  void dispose() {
    subject.dispose();
    date.dispose();
    time.dispose();
    room.dispose();
    instructor.dispose();
  }
}

class CheckingScreen extends StatefulWidget {
  const CheckingScreen({super.key});

  @override
  State<CheckingScreen> createState() => _CheckingScreenState();
}

class _CheckingScreenState extends State<CheckingScreen> {
  static const Color _bg = Color.fromARGB(255, 5, 7, 14);
  static const Color _dark = Color.fromARGB(255, 5, 14, 36);
  static const Color _light = Color.fromARGB(255, 197, 215, 255);

  // Start with one empty card
  final List<_ScheduleEntry> _entries = [_ScheduleEntry()];

  void _addCard() {
    setState(() => _entries.add(_ScheduleEntry()));
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  void _confirm() {
    // TODO: save the schedule from _entries
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Review your schedule",
                  style: TextStyle(
                    color: _light,
                    fontFamily: 'DMSans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Scrollable list of schedule cards
            // (add the "We detected..." notice at the top of this list later)
            // The buttons sit at the end of the list, so they always
            // appear below the last card.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  for (int i = 0; i < _entries.length; i++) ...[
                    _buildCard(_entries[i]),
                    const SizedBox(height: 16),
                  ],

                  // Add another card
                  OutlinedButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Add another subject'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: _light,
                      side: BorderSide(color: _light.withOpacity(0.3), width: 1.5),
                      textStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fixed bottom buttons (they stay put while the cards scroll)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  _buildButton(
                    label: 'Rescan form',
                    onPressed: () => Navigator.pop(context),
                    outlined: true,
                  ),
                  const SizedBox(height: 12),
                  _buildButton(
                    label: 'Confirm schedule and create value',
                    onPressed: _confirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_ScheduleEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _light.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField("Subject", entry.subject),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField("Date", entry.date)),
              const SizedBox(width: 12),
              Expanded(child: _buildField("Time", entry.time)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildField("Room", entry.room)),
              const SizedBox(width: 12),
              Expanded(child: _buildField("Instructor", entry.instructor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'DMSans',
            fontSize: 15,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _light.withOpacity(0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _light, width: 1.5),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: _dark,
        foregroundColor: _light,
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(15.0)),
          side: outlined
              ? BorderSide(color: _light.withOpacity(0.3), width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}