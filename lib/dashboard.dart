import 'package:flutter/material.dart';
import 'calculator.dart';
import 'scan.dart';

// A single class shown on the dashboard
class ClassItem {
  final String subject;
  final String room;
  final String instructor;
  final String time;
  final int handouts;

  const ClassItem({
    required this.subject,
    required this.room,
    required this.instructor,
    required this.time,
    this.handouts = 0,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _bg = Color.fromARGB(255, 5, 7, 14);
  static const Color _dark = Color.fromARGB(255, 5, 14, 36);
  static const Color _light = Color.fromARGB(255, 197, 215, 255);
  static const Color _card = Color.fromARGB(255, 168, 196, 255);
  static const Color _badge = Color.fromARGB(255, 235, 87, 60);

  // Default values (change these once you have real data)
  String userName = 'user';
  String? semester; // null = shows "Add Sem"
  double gwa = 0.00;
  ClassItem? upNext; // null = shows "No values yet..."
  List<ClassItem> today = [];
  List<ClassItem> tomorrow = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg, Color.fromARGB(255, 0, 60, 160)],
          stops: [0.55, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              Text(
                "Welcome, $userName!",
                style: const TextStyle(
                  color: _light,
                  fontFamily: 'DMSans',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Semester + GWA chips
              Row(
                children: [
                  _chip(semester ?? 'Add Sem'),
                  const SizedBox(width: 12),
                  _chip('Current GWA: ${gwa.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 20),

              // Up next card
              _buildUpNext(),
              const SizedBox(height: 24),

              // Today's timeline
              _sectionTitle("Today's timeline"),
              const SizedBox(height: 12),
              ..._buildTimeline(today),
              const SizedBox(height: 12),

              // Tomorrow's timeline
              _sectionTitle("Tomorrow's timeline"),
              const SizedBox(height: 12),
              ..._buildTimeline(tomorrow),
            ],
          ),
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  // ---------- Pieces ----------

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _dark,
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _light,
        fontFamily: 'DMSans',
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        "No values yet...",
        style: TextStyle(
          color: Color.fromARGB(255, 60, 75, 110),
          fontFamily: 'DMSans',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUpNext() {
    final item = upNext;
    if (item == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Up next",
            style: TextStyle(
              color: _light,
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _emptyCard(),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Up next",
                style: TextStyle(
                  color: _badge,
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _badge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Soon",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.subject,
            style: const TextStyle(
              color: _dark,
              fontFamily: 'DMSans',
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${item.time} · ${item.room}",
            style: const TextStyle(
                color: _dark, fontFamily: 'DMSans', fontSize: 14),
          ),
          Text(
            "Instructor: ${item.instructor}",
            style: const TextStyle(
                color: _dark, fontFamily: 'DMSans', fontSize: 14),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(List<ClassItem> items) {
    if (items.isEmpty) return [_emptyCard()];

    return [
      for (final item in items) ...[
        _timelineCard(item),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _timelineCard(ClassItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  item.subject,
                  style: const TextStyle(
                    color: _dark,
                    fontFamily: 'DMSans',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                item.time,
                style: const TextStyle(
                  color: _dark,
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            "${item.room} · ${item.instructor}",
            style: const TextStyle(
                color: _dark, fontFamily: 'DMSans', fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _dark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, color: _light, size: 14),
                const SizedBox(width: 6),
                Text(
                  "${item.handouts} handouts available",
                  style: const TextStyle(
                    color: _light,
                    fontFamily: 'DMSans',
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: _light, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Bottom navigation ----------

  Widget _buildNavBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _dark,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _navItem(Icons.grid_view_rounded, "Dashboard",
                        selected: true, onTap: () {}),
                    _navItem(Icons.folder_open, "File Manager", onTap: () {
                      // TODO: open file manager screen
                    }),
                    _navItem(Icons.calculate_outlined, "Calculator", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GwaScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ScanScreen()),
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: _card,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: _dark, size: 28),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool selected = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _card.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? _card : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? _card : Colors.grey,
                fontFamily: 'DMSans',
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}