import 'package:flutter/material.dart';

class GwaScreen extends StatefulWidget {
  const GwaScreen({super.key});

  @override
  State<GwaScreen> createState() => _GwaScreenState();
}

class _GwaScreenState extends State<GwaScreen> {
  final TextEditingController _prelimController = TextEditingController();
  final TextEditingController _midtermController = TextEditingController();
  final TextEditingController _preFinalController = TextEditingController();
  final TextEditingController _finalController = TextEditingController();

  double? _calculatedGwa;

  void _calculateGwa() {
    final double? prelim = double.tryParse(_prelimController.text);
    final double? midterm = double.tryParse(_midtermController.text);
    final double? preFinal = double.tryParse(_preFinalController.text);
    final double? finals = double.tryParse(_finalController.text);

    if (prelim != null && midterm != null && preFinal != null && finals != null) {
      setState(() {
        _calculatedGwa = (prelim + midterm + preFinal + finals*2) / 5;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid grades for all fields.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Clear function tied to the trash icon button
  void _clearAllFields() {
    setState(() {
      _prelimController.clear();
      _midtermController.clear();
      _preFinalController.clear();
      _finalController.clear();
      _calculatedGwa = null; // Hide the result popping container
    });
  }

  @override
  void dispose() {
    _prelimController.dispose();
    _midtermController.dispose();
    _preFinalController.dispose();
    _finalController.dispose();
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "GWA Calculator",
                  style: TextStyle(
                    color: Color.fromARGB(255, 197, 215, 255),
                    fontFamily: 'DMSans',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Card Container
              Container(
                width: 340,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color.fromARGB(255, 197, 215, 255).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading Row containing the title and the clean trash button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Application Development",
                          style: TextStyle(
                            color: Color.fromARGB(255, 197, 215, 255),
                            fontFamily: 'DMSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                          onPressed: _clearAllFields,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    // Row 1: Prelim and Midterm
                    Row(
                      children: [
                        Expanded(child: _buildGradeField("Prelim", _prelimController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGradeField("Midterm", _midtermController)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Row 2: Pre-finals and Finals
                    Row(
                      children: [
                        Expanded(child: _buildGradeField("Pre-finals", _preFinalController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGradeField("Finals", _finalController)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Popping Container: Appears above the button on calculation
              if (_calculatedGwa != null)
                Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 5, 14, 36),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color.fromARGB(255, 197, 215, 255).withOpacity(0.3),
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

              // Calculate Button
              ElevatedButton(
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
            ],
          ),
        ),
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
              fontWeight: FontWeight.bold
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color.fromARGB(255, 197, 215, 255).withOpacity(0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color.fromARGB(255, 197, 215, 255), width: 1.5),
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}
