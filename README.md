# Wisal (وصال)

Flutter application that translates Arabic text and voice into **Saudi Sign Language** animations using a 3D avatar, and recognizes signs from the camera using hand landmarks.

## Features
- Text and voice input translated to Saudi Sign Language motions on a 3D avatar
- Live camera sign recognition with hand-landmark detection
- On-device TFLite model plus a server-side sign dictionary
- Notes screen and sign motion dictionary

## Tech stack
Flutter (Dart) · TensorFlow Lite · MediaPipe hand landmarks · Python / FastAPI server · 3D avatar models (GLB)

## Project structure
- `lib/` – Flutter app
- `server/` – FastAPI service for the sign dictionary, avatar models and camera hand-landmark matching
- `ai_training/` – scripts to build the dataset from videos and train the sequence model

## Run
```
flutter pub get
flutter run --dart-define=WISAL_SERVER_URL=http://<your-server>:5000
```
Server:
```
cd server
pip install -r requirements.txt
python main.py
```

## Author
Rana Alessi – Computer Science, Umm Al-Qura University