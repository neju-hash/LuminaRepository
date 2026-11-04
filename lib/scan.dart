import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'schedule_input.dart';
import 'calculator.dart';
import 'services/text_categorizer.dart' as services;
import 'services/table_detector.dart';
import 'models/detected_entity.dart';
import 'models/schedule_entry.dart';
import 'screens/detection_result_screen.dart';
import 'screens/schedule_confirmation_screen.dart';

void main(){
  runApp(
    const MaterialApp(
      home: ScanScreen(),
    )
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
  final textCategorizer = services.TextCategorizer();
  final tableDetector = TableDetector();
  List<String> extractedSubjects = [];
  List<DetectedEntity> detectedEntities = [];
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
        extractedSubjects = []; // Reset extracted subjects when new image is picked
      });
      
      // Automatically process the image for text extraction
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
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      // Perform intelligent detection using TextCategorizer
      List<DetectedEntity> entities = [];
      
      for (var block in recognizedText.blocks) {
        for (var line in block.lines) {
          for (var element in line.elements) {
            // Get bounding box coordinates
            final boundingBox = element.boundingBox;
            
            // Categorize the text (passing required parameters)
            final category = textCategorizer.categorizeText(
              element.text,
              boundingBox,
              [], // context - could be enhanced with nearby elements
            );
            
            // Map TextCategorizer EntityType to DetectedEntity EntityType
            final entityType = _mapEntityType(category);
            
            // Create DetectedEntity
            final entity = DetectedEntity(
              text: element.text,
              type: entityType,
              boundingBox: boundingBox,
              confidence: element.confidence ?? 0.0,
            );
            
            entities.add(entity);
          }
        }
      }

      setState(() {
        detectedEntities = entities;
        isProcessing = false;
      });

      // Navigate to DetectionResultScreen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetectionResultScreen(
              imageFile: image!,
              detectedEntities: entities,
              onRetake: () {
                Navigator.pop(context);
              },
              onConfirm: () {
                _extractScheduleAndNavigate(recognizedText);
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _extractScheduleAndNavigate(RecognizedText recognizedText) {
    try {
      // Detect table structure
      final columns = tableDetector.detectColumns(recognizedText);
      final rows = tableDetector.detectRows(recognizedText);
      
      // Extract schedule data
      final scheduleEntries = tableDetector.extractScheduleData(columns, rows);
      
      // Navigate to ScheduleConfirmationScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleConfirmationScreen(
            scheduleEntries: scheduleEntries,
            onSave: (List<ScheduleEntry> entries) {
              // Handle saved schedule entries
              // User can navigate to schedule input or calculator
              Navigator.popUntil(context, (route) => route.isFirst);
              
              // Show success message with options
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${entries.length} schedule entries saved!'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'View Calculator',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GwaScreen(scheduleEntries: entries),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting schedule: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Map TextCategorizer EntityType to DetectedEntity EntityType
  EntityType _mapEntityType(services.EntityType categorizerType) {
    switch (categorizerType) {
      case services.EntityType.subjectCode:
        return EntityType.SUBJECT;
      case services.EntityType.time:
        return EntityType.TIME;
      case services.EntityType.instructorName:
        return EntityType.INSTRUCTOR;
      case services.EntityType.day:
        return EntityType.DAY;
      case services.EntityType.roomNumber:
        return EntityType.ROOM;
      case services.EntityType.units:
        return EntityType.UNITS;
      case services.EntityType.header:
        return EntityType.HEADER;
      case services.EntityType.unknown:
        return EntityType.UNKNOWN;
    }
  }

  List<String> parseSubjectsFromText(String text) {
    // Split text by lines
    List<String> lines = text.split('\n');
    List<String> subjects = [];

    // Filter lines that look like subject names
    // This is a simple implementation - you may need to adjust based on RAF format
    for (String line in lines) {
      String trimmed = line.trim();
      
      // Skip empty lines, very short lines, or lines that are just numbers
      if (trimmed.isEmpty || trimmed.length < 3 || RegExp(r'^\d+$').hasMatch(trimmed)) {
        continue;
      }

      // Skip common header words
      if (trimmed.toLowerCase().contains('subject') ||
          trimmed.toLowerCase().contains('code') ||
          trimmed.toLowerCase().contains('units') ||
          trimmed.toLowerCase().contains('schedule') ||
          trimmed.toLowerCase().contains('instructor')) {
        continue;
      }

      // If line contains subject-like pattern (letters, possible numbers, reasonable length)
      if (RegExp(r'[a-zA-Z]{3,}').hasMatch(trimmed) && trimmed.length >= 5) {
        subjects.add(trimmed);
      }
    }

    return subjects;
  }

  void proceedToScheduleInput() {
    if (extractedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a RAF image first to extract subjects.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleInputScreen(subjects: extractedSubjects),
      ),
    );
  }

  void proceedDirectlyToCalculator() {
    if (extractedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a RAF image first to extract subjects.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GwaScreen(subjects: extractedSubjects),
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
          'Upload RAF',
          style: TextStyle(
            color: Color.fromARGB(255, 197, 215, 255),
            fontFamily: 'DMSans',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image preview container with helpful hints
              SizedBox(
                height: 340,
                width: 340,
                child: Stack(
                  children: [
                    image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image!,
                            fit: BoxFit.cover, 
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent, 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(76, 158, 158, 158),
                              width: 1.0,
                            ),
                          ),
                          child: const Center( 
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.table_chart_outlined,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No image uploaded..",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    "Align RAF table in frame\nEnsure good lighting",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color.fromARGB(153, 158, 158, 158),
                                      fontSize: 12,
                                      fontFamily: 'DMSans',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    // Overlay hint when camera is about to be used
                    if (image == null)
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(200, 5, 14, 36),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(76, 197, 215, 255),
                              width: 1.0,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Color.fromARGB(255, 197, 215, 255),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tip: Use good lighting for best results',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 197, 215, 255),
                                    fontSize: 11,
                                    fontFamily: 'DMSans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Processing indicator
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
                          color: Color.fromARGB(255, 197, 215, 255),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Detecting schedule information...',
                        style: TextStyle(
                          color: Color.fromARGB(255, 197, 215, 255),
                          fontFamily: 'DMSans',
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Display extracted subjects
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
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extracted Subjects:',
                        style: TextStyle(
                          color: Color.fromARGB(255, 197, 215, 255),
                          fontFamily: 'DMSans',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...extractedSubjects.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'DMSans',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        '${extractedSubjects.length} subject${extractedSubjects.length > 1 ? 's' : ''} found',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // Image picker buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'), 
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 50),
                      backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                      foregroundColor: const Color.fromARGB(255, 197, 215, 255), 
                      textStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 50),
                      backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                      foregroundColor: const Color.fromARGB(255, 197, 215, 255), 
                      textStyle: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Add Schedule button
              ElevatedButton( 
                onPressed: isProcessing ? null : proceedToScheduleInput,
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
                child: const Text('Add Schedule'),
              ),
              
              const SizedBox(height: 12),

              // Skip to Calculator button
              TextButton(
                onPressed: isProcessing ? null : proceedDirectlyToCalculator,
                style: TextButton.styleFrom(
                  minimumSize: const Size(280, 50),
                  foregroundColor: Colors.grey,
                  textStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 16,
                  ),
                ),
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
