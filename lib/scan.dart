import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'schedule_input.dart';
import 'calculator.dart';

void main() {
  runApp(
    const MaterialApp(
      home: ScanScreen(),
    ),
  );
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? image;
  final picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  // Each subject is a map with 'name', 'days', and 'time'
  List<Map<String, String>> extractedSubjects = [];
  bool isProcessing = false;

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
        extractedSubjects = [];
      });
      await extractTextFromImage();
    }
  }

  Future<void> extractTextFromImage() async {
    if (image == null) return;
    setState(() {
      isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFile(image!);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      List<Map<String, String>> subjects =
          parseSubjectsFromText(recognizedText.text);

      setState(() {
        extractedSubjects = subjects;
        isProcessing = false;
      });

      if (subjects.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects found. Please try a clearer photo.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // Returns a List of Maps containing 'name', 'days', and 'time'
  List<Map<String, String>> parseSubjectsFromText(String text) {
    List<String> lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> subjects = [];
    List<String> days = [];
    List<String> times = [];

    final timeRegex = RegExp(
        r'\d{1,2}:[0-9O]{2}\s*[AP]M\s*-\s*\d{1,2}:[0-9O]{2}\s*[AP]M',
        caseSensitive: false);
    final daysRegex = RegExp(r'^(M|T|W|Th|F|S|TF|MW|TTh|FS)+$');

    // Whole words that only appear in headers, labels, and fee lines
    const junkWords = {
      'college', 'student', 'term', 'program', 'academic', 'financial',
      'payment', 'balance', 'name', 'instructor', 'room', 'unit', 'units',
      'schedule', 'assessment', 'cash', 'refund', 'charge', 'total',
      'registration', 'miscellaneous', 'tuition', 'school', 'enrollment',
      'amount', 'sponsorship', 'due', 'form', 'subject', 'subjects',
      'description', 'section', 'code', 'day', 'days', 'time', 'date',
      'semester', 'year', 'fee', 'fees', 'page', 'email', 'tel', 'campus',
      'raf', 'status', 'enrolled', 'adviser', 'advisor', 'signature'
    };
    const junkPhrases = ['global city', 'sti college', 'academic year'];

    // Returns the cleaned course name, or null if the line is not a course name
    String? extractCourseName(String line) {
      String text = line.trim();
      String lower = text.toLowerCase();

      // Reject lines that contain times, money, or dates
      if (RegExp(r'\d{1,2}:\d{2}').hasMatch(text)) return null;
      if (RegExp(r'\d+[.,]\d{2}\b').hasMatch(text)) return null;
      if (RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}').hasMatch(text)) return null;

      // Reject known header phrases
      for (final p in junkPhrases) {
        if (lower.contains(p)) return null;
      }

      // Reject if any whole word is a junk word
      final words = lower.split(RegExp(r'[^a-z]+')).where((w) => w.isNotEmpty);
      for (final w in words) {
        if (junkWords.contains(w)) return null;
      }

      // Remove a leading subject code like "CC101", "ITE 1001", "GE-102"
      text = text.replaceFirst(RegExp(r'^[A-Z]{2,6}[\s-]?\d{2,4}[A-Z]?\s+'), '');
      // Remove trailing units like "3.0"
      text = text.replaceFirst(RegExp(r'\s+\d+\.\d+$'), '').trim();

      // A course name must be mostly letters
      final letters = RegExp(r'[a-zA-Z]').allMatches(text).length;
      final nonSpace = text.replaceAll(RegExp(r'\s'), '').length;
      if (nonSpace == 0 || letters / nonSpace < 0.75) return null;

      // Must have at least one real word and a reasonable length
      if (text.length < 5) return null;
      if (!RegExp(r'[a-zA-Z]{4,}').hasMatch(text)) return null;

      return text;
    }

    for (String line in lines) {
      String cleanLine = line.replaceAll('OAM', '0AM').replaceAll('OPM', '0PM');

      if (timeRegex.hasMatch(cleanLine)) {
        times.add(timeRegex.firstMatch(cleanLine)?.group(0) ?? "");
      } else if (daysRegex.hasMatch(cleanLine)) {
        days.add(cleanLine);
      } else {
        final courseName = extractCourseName(line);
        if (courseName != null) subjects.add(courseName);
      }
    }

    List<Map<String, String>> combined = [];
    int maxCount = subjects.length;
    if (times.length > maxCount) maxCount = times.length;
    if (days.length > maxCount) maxCount = days.length;

    for (int i = 0; i < maxCount; i++) {
      String s = i < subjects.length ? subjects[i] : "Unknown Subject ${i + 1}";
      String d = i < days.length ? days[i] : "";
      String t = i < times.length ? times[i] : "";

      if (t.isNotEmpty || d.isNotEmpty || s != "Unknown Subject ${i + 1}") {
        combined.add({
          'name': s,
          'days': d,
          'time': t,
        });
      }
    }

    return combined;
  }

  void proceedToScheduleInput() {
    if (extractedSubjects.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ScheduleInputScreen(subjects: extractedSubjects)),
    );
  }

  void proceedDirectlyToCalculator() {
    if (extractedSubjects.isEmpty) return;
    // Maps it back to a simple string list just for the calculator screen
    List<String> subjectNames =
        extractedSubjects.map((s) => s['name']!).toList();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GwaScreen(subjects: subjectNames)),
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
        title: const Text('Upload RAF',
            style: TextStyle(
                color: Color.fromARGB(255, 197, 215, 255),
                fontFamily: 'DMSans',
                fontSize: 20,
                fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 340,
                width: 340,
                child: image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(image!, fit: BoxFit.cover))
                    : Container(
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color.fromARGB(76, 158, 158, 158),
                                width: 1.0)),
                        child: const Center(
                            child: Text("No image uploaded..",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16))),
                      ),
              ),
              const SizedBox(height: 20),

              if (isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color.fromARGB(255, 197, 215, 255))),
                      SizedBox(width: 10),
                      Text('Extracting subjects...',
                          style: TextStyle(
                              color: Color.fromARGB(255, 197, 215, 255),
                              fontFamily: 'DMSans',
                              fontSize: 14)),
                    ],
                  ),
                ),

              if (extractedSubjects.isNotEmpty && !isProcessing)
                Container(
                  width: 340,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 5, 14, 36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color.fromARGB(76, 197, 215, 255),
                          width: 1.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Extracted Subjects:',
                          style: TextStyle(
                              color: Color.fromARGB(255, 197, 215, 255),
                              fontFamily: 'DMSans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ...extractedSubjects.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2.0),
                                child: Icon(Icons.check_circle_outline,
                                    color: Colors.green, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entry.value['name']!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'DMSans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    if (entry.value['days']!.isNotEmpty ||
                                        entry.value['time']!.isNotEmpty)
                                      Text(
                                          'Day: ${entry.value['days']!.isEmpty ? '--' : entry.value['days']}  |  Time: ${entry.value['time']!.isEmpty ? '--' : entry.value['time']}',
                                          style: TextStyle(
                                              color: Colors.grey[400],
                                              fontFamily: 'DMSans',
                                              fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text('${extractedSubjects.length} classes found',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontFamily: 'DMSans',
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        isProcessing ? null : () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 50),
                        backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                        foregroundColor: const Color.fromARGB(255, 197, 215, 255),
                        textStyle: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 50),
                        backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                        foregroundColor: const Color.fromARGB(255, 197, 215, 255),
                        textStyle: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: isProcessing ? null : proceedToScheduleInput,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(280, 70),
                    backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                    foregroundColor: const Color.fromARGB(255, 197, 215, 255),
                    textStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)))),
                child: const Text('Add Schedule'),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: isProcessing ? null : proceedDirectlyToCalculator,
                style: TextButton.styleFrom(
                    minimumSize: const Size(280, 50),
                    foregroundColor: Colors.grey,
                    textStyle:
                        const TextStyle(fontFamily: 'DMSans', fontSize: 16)),
                child: const Text('Skip to GWA Calculator'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}