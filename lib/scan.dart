import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'checking.dart';

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

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 5, 7, 14),
      body: Center(
        child: Column( 
          mainAxisAlignment: MainAxisAlignment.center, // Centers the 400x400 box vertically on screen
          children: [
            SizedBox(
              height: 340,
              width: 340,
              child: image != null
                ? Image.file(
                    image!,
                    fit: BoxFit.cover, 
                  )
                : Container(
                    // Uses Flutter's native thin border decoration
                    decoration: BoxDecoration(
                      color: Colors.transparent, 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3), // Light, thin border
                        width: 1.0,                         // Thin line
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
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
              
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt), // Your prefix icon
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
                  )  // Your button text
                ),
                  ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library), // Your prefix icon
                  label: const Text('gallery'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(140, 50),
                    backgroundColor: const Color.fromARGB(255, 5, 14, 36),
                    foregroundColor: const Color.fromARGB(255, 197, 215, 255), 
                    textStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  )      // Your button text
                ),
              ],
              ),
            ),

             Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton( 
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context)=> const CheckingScreen()),);
                  },
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
                  child: const Text('Next'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
