# Notes

A premium, feature-rich notes application built with Flutter. **Notes** offers a seamless experience for capturing ideas through rich text, images, and high-quality voice recordings.

## ✨ Features

- **Rich Text Support**: Elegant typography using Google Fonts (DM Serif Text).
- **Multimedia Integration**: 
  - 📸 Attach images from gallery or camera.
  - 🎤 Record and playback high-quality voice notes with duration tracking.
- **Advanced Search**: Real-time search with visual highlighting of matching text within notes.
- **Premium Design**: 
  - 🌓 Dynamic Dark and Light modes.
  - 🚀 Fluid animations and transitions.
  - 📱 Responsive layout for all devices.
- **Offline First**: Fast and reliable local storage using SQLite (sqflite).
- **Data Privacy**: All notes and media stay on your device.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / VS Code / Xcode
- Dart 3.0+

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/notesapp.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 🛠️ Built With

- **Flutter**: UI Framework.
- **Provider**: State Management.
- **sqflite**: Local SQLite Database.
- **audioplayers & record**: Audio recording and playback.
- **google_fonts**: Beautiful typography.

## 📂 Project Structure

- `lib/models/`: Data models for Notes and Audio.
- `lib/database/`: SQLite database implementation and CRUD logic.
- `lib/pages/`: Main application screens (Notes List, Editor, Settings).
- `lib/components/`: Reusable UI widgets.
- `lib/theme/`: Theme data and color schemes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*Developed by Mohab*
