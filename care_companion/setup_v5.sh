#!/bin/bash
# care_companion klasöründe çalıştır:  bash setup_v5.sh
set -e
python3 setup_ui.py
python3 setup_voice.py
flutter pub add provider flutter_tts sqflite path shared_preferences speech_to_text google_fonts
flutter pub add --dev flutter_launcher_icons
dart run flutter_launcher_icons
flutter pub get
echo "Hazir. Simdi: flutter run -d macos"
