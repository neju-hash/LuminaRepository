import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'schedule_input.dart';
import 'calculator.dart';

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
  List<String> extractedSubjects = [];
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

      // Extract subject names from the recognized text
      List<String> subjects = parseSubjectsFromText(recognizedText.text);

      setState(() {
        extractedSubjects = subjects;
        isProcessing = false;
      });

      if (subjects.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No subjects found in the image. Please try a clearer photo.'),
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
          SnackBar(
            content: Text('Error extracting text: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
              // Image preview container
              SizedBox(
                height: 340,
                width: 340,
                child: image != null
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
                        child: Text(
                          "No image uploaded..",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                        'Extracting subjects...',
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
