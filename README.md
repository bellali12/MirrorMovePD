# MirrorMove PD

MirrorMove PD, referred to in some project materials as Mirrormotion, is a two-part dance therapy prototype designed to support Parkinson's rehabilitation. This repository combines:

- a Flutter mobile app for authentication, progress tracking, song selection, and remote session control
- a Python desktop companion that plays reference choreography, shows the user's live camera feed, and hosts the local control server the mobile app connects to

The mobile app lives in [`mirrormotion/`](mirrormotion), and the desktop companion plus pose-analysis utilities live in [`analysis/`](analysis).

## Project Structure

```text
.
├── README.md
├── analysis/
│   ├── app.py
│   ├── main.py
│   ├── generate_reference_dance_data.py
│   ├── reference_dance_data.csv
│   ├── audio/
│   ├── images/
│   └── videos/
└── mirrormotion/
    ├── lib/
    │   ├── main.dart
    │   ├── screens/
    │   ├── services/
    │   └── components/
    ├── assets/
    ├── android/
    ├── ios/
    ├── web/
    ├── macos/
    ├── windows/
    └── linux/
```

## What Each Part Does

### `analysis/` - desktop companion app

[`analysis/app.py`](analysis/app.py) is the main desktop experience. It:

- opens a CustomTkinter window with a reference dance video on one side and the user's camera feed on the other
- starts a local Flask server on port `5003`
- exposes `/status`, `/connect`, `/disconnect`, `/command`, and `/song_data` endpoints for the mobile app
- pauses the reference video until a phone connects
- accepts commands such as play/pause, previous/next session, difficulty changes, volume, and song selection

Other files in this folder support pose-estimation experiments:

- [`analysis/main.py`](analysis/main.py): standalone MediaPipe pose-estimation prototype / visualization script
- [`analysis/generate_reference_dance_data.py`](analysis/generate_reference_dance_data.py): extracts pose landmarks from a reference video and saves them as CSV
- [`analysis/reference_dance_data.csv`](analysis/reference_dance_data.csv): example/generated landmark output
- [`analysis/videos/`](analysis/videos): reference choreography videos used by the desktop app
- [`analysis/audio/`](analysis/audio): local audio assets
- [`analysis/images/`](analysis/images): local overlays and experiment assets

### `mirrormotion/` - primary Flutter app

[`mirrormotion/lib/main.dart`](mirrormotion/lib/main.dart) is the entry point for the main user-facing app. The Flutter side is responsible for:

- Firebase initialization and authentication
- creating user records in Firestore
- showing the home dashboard with today's progress and a weekly chart
- loading songs from Firestore
- opening a session screen that connects to the desktop app over the local network
- basic profile actions such as logout and account deletion

Key areas inside the Flutter app:

- [`mirrormotion/lib/screens/`](mirrormotion/lib/screens): signup, login, home, session, and profile flows
- [`mirrormotion/lib/services/auth.dart`](mirrormotion/lib/services/auth.dart): Firebase Auth plus initial user document creation
- [`mirrormotion/lib/services/data.dart`](mirrormotion/lib/services/data.dart): shared app state, song loading, daily progress, and weekly usage calculations
- [`mirrormotion/lib/components/chart.dart`](mirrormotion/lib/components/chart.dart): weekly progress visualization
- [`mirrormotion/lib/components/goaltimepopup.dart`](mirrormotion/lib/components/goaltimepopup.dart): daily goal progress popup

The Flutter project includes platform folders for Android, iOS, web, macOS, Windows, and Linux, but the app logic is centered in [`mirrormotion/lib/`](mirrormotion/lib).

## System Flow

1. Start the desktop companion in [`analysis/app.py`](analysis/app.py).
2. The desktop app shows a connection code derived from the machine's LAN IP and starts listening on port `5003`.
3. Launch the Flutter app from [`mirrormotion/`](mirrormotion).
4. Sign in or create an account.
5. Choose a song from the home screen and open a session.
6. Enter the connection code or host for the desktop app.
7. The mobile app sends song data and remote control commands to the desktop companion.

## Data Expectations

The current code assumes Firebase is configured and that Firestore contains:

- a `users` collection with fields such as `name`, `dailyMinutes`, `goalChanges`, `progress`, `sessionHistory`, and `onboardingComplete`
- a `songs` collection whose documents include values used by the home/session flow, such as `title`, `artist`, `level`, and `duration`

For automatic song switching to work, the song `title` should match a filename in [`analysis/videos/`](analysis/videos) without the file extension. For example, a title of `All That Jazz` maps to `All That Jazz.mp4`.

## Running The Project

### Desktop companion

```bash
cd analysis
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install flask customtkinter simpleaudio
python3 app.py
```

Optional utility scripts:

```bash
cd analysis
source venv/bin/activate
python3 main.py
python3 generate_reference_dance_data.py
```

Note: [`analysis/requirements.txt`](analysis/requirements.txt) covers the MediaPipe/OpenCV stack, but [`analysis/app.py`](analysis/app.py) also imports `flask`, `customtkinter`, and `simpleaudio`, so those need to be available in the environment as well.

### Flutter app

```bash
cd mirrormotion
flutter pub get
flutter run
```

The Flutter app already includes Firebase configuration files in the project, but they still need to match the Firebase project you want to use.

## Connection Notes

- The desktop app listens on port `5003`.
- The mobile and desktop apps should normally be on the same Wi-Fi network.
- The connection popup in the Flutter app accepts the short connection code shown by the desktop app, a full LAN IP, or local development shortcuts such as `127.0.0.1`, `localhost`, or `10.0.2.2`.

## Current Status

This repository is a prototype/research codebase rather than a polished production release. The main end-user flow is the Flutter app plus the desktop companion in [`analysis/app.py`](analysis/app.py); the other Python scripts in [`analysis/`](analysis) are supporting experiments and tooling around pose estimation.





REWARD MECHANISM:
- Unlock face overlay cosmetics
- Unlock more songs
- Score System and Tracker