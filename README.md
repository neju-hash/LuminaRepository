# Lumina

An intelligent academic companion app for STI students to manage schedules, tasks, and grades efficiently.

## 🎯 Features

### ✅ Implemented
- **RAF OCR Integration** - Upload your Registration and Assessment Form (RAF) and automatically extract subjects using Google ML Kit text recognition
- **Dynamic GWA Calculator** - Automatically generates input fields based on subjects from your RAF
  - Supports unlimited subjects
  - Calculates individual subject grades: `(Prelim + Midterm + Pre-finals + Finals×2) / 5`
  - Computes overall GWA from all subject averages
- **Interactive Dashboard** - View upcoming deadlines and academic overview
- **Schedule Management** - Track your class schedules and reminders
- **Task Tracking** - Manage assignments and academic tasks
- **Notification System** - Get alerts for schedules, tasks, and reminders

### 🚧 In Development
- **AI Quiz Generator** - Built-in AI for creating practice quizzes
- **Schedule Time Differentiation** - Distinguish between lab and lecture schedules with start/end times
- **Enhanced OCR** - Improved text recognition for class schedules and time parsing

## 🛠️ Tech Stack

- **Framework:** Flutter 3.13.4+
- **Language:** Dart
- **OCR:** Google ML Kit Text Recognition
- **Font:** DM Sans (Google Fonts)
- **Image Processing:** Image Picker

## 📱 Screens

1. **Welcome Screen** - Personalized greeting and app introduction
2. **RAF Scanner** - Camera/gallery upload with OCR extraction
3. **GWA Calculator** - Dynamic subject-based grade calculation
4. **Dashboard** - Academic overview and quick actions
5. **Checking/Task Manager** - Track assignments and deadlines

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.13.4 or higher
- Dart SDK
- Android Studio / Xcode (for mobile deployment)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/neju-hash/LuminaRepository.git
cd LuminaRepository
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 📖 Usage

### GWA Calculator Workflow

1. **Upload RAF**: Take a photo or select from gallery
2. **Auto-Extract**: OCR automatically detects subject names
3. **Verify Subjects**: Review extracted subjects list
4. **Input Grades**: Enter grades for Prelim, Midterm, Pre-finals, Finals
5. **Calculate**: Get your GWA instantly

### Grade Calculation Formula

**Per Subject:**
```
Subject Grade = (Prelim + Midterm + Pre-finals + Finals×2) / 5
```

**Overall GWA:**
```
GWA = (Subject1 + Subject2 + ... + SubjectN) / N
```

## 🎨 Design

- **Color Scheme:** Dark theme with blue accents
- **Primary:** `#05070E` (Background)
- **Accent:** `#C5D7FF` (Light Blue)
- **Cards:** `#050E24` (Dark Blue)
- **Typography:** DM Sans

## 📂 Project Structure

```
lib/
├── main.dart              # App entry point & welcome screen
├── scan.dart              # RAF upload & OCR processing
├── calculator.dart        # Dynamic GWA calculator
├── dashboard.dart         # Main dashboard view
├── checking.dart          # Task/assignment management
└── assets/
    └── fonts/             # DM Sans font files
```

## 🔄 Recent Updates

### v2.0 - RAF OCR & Dynamic Calculator (Latest)
- ✅ Implemented Google ML Kit OCR for RAF scanning
- ✅ Dynamic subject card generation from OCR results
- ✅ Smart text parsing to filter subject names
- ✅ Fixed number of subjects based on RAF upload
- ✅ Individual subject grade calculation with Finals weight
- ✅ Overall GWA computation from subject averages
- ✅ Fixed all deprecation warnings (Flutter 3.27+)
- ✅ Added loading indicators and error handling
- ✅ Memory leak prevention with proper disposal
- ✅ Visual feedback for OCR processing

## 🤝 Contributing

This is a student project for STI. Contributions and suggestions are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is part of an academic requirement for STI.

## 👨‍💻 Authors

- **John killua E. Ibaite** - Current Development
- **Neji** - Initial Project Setup

## 🙏 Acknowledgments

- STI College for project requirements
- Flutter & Dart communities
- Google ML Kit for OCR capabilities
- DM Sans typography

---

Built with ❤️ for STI students by STI students
