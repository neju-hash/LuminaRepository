import 'package:flutter/material.dart';

class SubjectGrade {
  final String subjectName;
  final TextEditingController prelimController;
  final TextEditingController midtermController;
  final TextEditingController preFinalController;
  final TextEditingController finalController;

  SubjectGrade({required this.subjectName})
      : prelimController = TextEditingController(),
        midtermController = TextEditingController(),
        preFinalController = TextEditingController(),
        finalController = TextEditingController();

  void dispose() {
    prelimController.dispose();
    midtermController.dispose();
    preFinalController.dispose();
    finalController.dispose();
  }

  double? calculateSubjectAverage() {
    final double? prelim = double.tryParse(prelimController.text);
    final double? midterm = double.tryParse(midtermController.text);
    final double? preFinal = double.tryParse(preFinalController.text);
    final double? finals = double.tryParse(finalController.text);

    if (prelim != null && midterm != null && preFinal != null && finals != null) {
      return (prelim + midterm + preFinal + finals * 2) / 5;
    }
    return null;
  }

  void clear() {
    prelimController.clear();
    midtermController.clear();
    preFinalController.clear();
    finalController.clear();
  }
}

class GwaScreen extends StatefulWidget {
  final List<String>? subjects; // List of subjects from RAF upload

  const GwaScreen({super.key, this.subjects});

  @override
  State<GwaScreen> createState() => _GwaScreenState();
}

class _GwaScreenState extends State<GwaScreen> {
  List<SubjectGrade> _subjectGrades = [];
  double? _calculatedGwa;

  @override
  void initState() {
    super.initState();
    _initializeSubjects();
  }

  void _initializeSubjects() {
    // If subjects are provided from RAF, use them
    // Otherwise, use default subjects for testing
    final List<String> subjects = widget.subjects ?? [
      'Application Development',
      'Mobile Programming',
    ];

    _subjectGrades = subjects.map((subject) => SubjectGrade(subjectName: subject)).toList();
  }

  void _calculateGwa() {
    List<double> subjectAverages = [];
    List<String> incompleteSubjects = [];

    for (var subject in _subjectGrades) {
      final average = subject.calculateSubjectAverage();
      if (average != null) {
        subjectAverages.add(average);
      } else {
        incompleteSubjects.add(subject.subjectName);
      }
    }

    if (incompleteSubjects.isEmpty && subjectAverages.isNotEmpty) {
      setState(() {
        _calculatedGwa = subjectAverages.reduce((a, b) => a + b) / subjectAverages.length;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            incompleteSubjects.isEmpty
                ? 'Please add subjects first.'
                : 'Please enter valid grades for: ${incompleteSubjects.join(", ")}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _clearSubject(int index) {
    setState(() {
      _subjectGrades[index].clear();
    });
  }

  @override
  void dispose() {
    for (var subject in _subjectGrades) {
      subject.dispose();
    }
    super.dispose();
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GWA Calculator",
              style: TextStyle(
                color: Color.fromARGB(255, 197, 215, 255),
                fontFamily: 'DMSans',
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // Dynamic Subject Cards
            ..._subjectGrades.asMap().entries.map((entry) {
              int index = entry.key;
              SubjectGrade subject = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: _buildSubjectCard(subject, index),
              );
            }),

            const SizedBox(height: 10),

            // Popping Container: Appears above the button on calculation
            if (_calculatedGwa != null)
              Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 5, 14, 36),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color.fromARGB(76, 197, 215, 255),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "YOUR GWA",
                        style: TextStyle(
                          color: Colors.grey,
                          fontFamily: 'DMSans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _calculatedGwa!.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 197, 215, 255),
                          fontFamily: 'DMSans',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Calculate Button
            Center(
              child: ElevatedButton(
                onPressed: _calculateGwa,
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
                child: const Text('Calculate'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(SubjectGrade subject, int index) {
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
          // Heading Row containing the subject name and the clear trash button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject.subjectName,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 197, 215, 255),
                    fontFamily: 'DMSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Small clickable trash icon
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => _clearSubject(index),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Row 1: Prelim and Midterm
          Row(
            children: [
              Expanded(child: _buildGradeField("Prelim", subject.prelimController)),
              const SizedBox(width: 16),
              Expanded(child: _buildGradeField("Midterm", subject.midtermController)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Pre-finals and Finals
          Row(
            children: [
              Expanded(child: _buildGradeField("Pre-finals", subject.preFinalController)),
              const SizedBox(width: 16),
              Expanded(child: _buildGradeField("Finals", subject.finalController)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeField(String label, TextEditingController controller) {
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
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'DMSans',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                color: Color.fromARGB(255, 197, 215, 255),
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
