import 'package:flutter/material.dart';
//import activities here
import 'scan.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: WelcomeScreen(), // 🟢 Points to your class below
    ),
  );
}

// 🟢 YOUR NEW SIMPLE CLASS
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(220, 0, 82, 204),
            Color.fromARGB(255, 5, 7, 14),
          ],
          stops: [0.1, 0.45],
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent, 
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(220, 0, 82, 204),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 40),
                width: 280,
                height: 100,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.all(10),
                child: const Column(
                  children: [
                    Text(
                      'Welcome to Lumina!',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 197, 215, 255),
                      ),
                    ),
                    Text(
                      'Your academic companion for schedules, handouts, and grades',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        color: Color.fromARGB(255, 197, 215, 255),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ), 
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        'What should we call you?',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: Color.fromARGB(255, 197, 215, 255),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(1),
                      child: TextField(
                        style: const TextStyle(color: Colors.white), // Makes typed text visible
                        decoration: const InputDecoration(
                          hintText: 'Killua',
                          hintStyle: TextStyle(
                            color: Color.fromARGB(193, 143, 153, 175), 
                          ),
                          prefixIcon: Icon(Icons.person),
                          prefixIconColor: Color.fromARGB(255, 197, 215, 255), 
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromARGB(255, 197, 215, 255),   
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blueAccent,   
                            ),
                          ),
                        ),
                      ), 
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
                      MaterialPageRoute(builder: (context)=> const ScanScreen()),);
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
                  child: const Text('Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
