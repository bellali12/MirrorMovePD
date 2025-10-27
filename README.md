# mirrormotion


App Name: MirrorMove PD

# Presentation Storyboard

## Visual Elements
1. Mobile Flutter App
2. Analysis Visuals (Pose Estimation)

## Timeline
1. Introduction
   - Entry ID: 198
   - Who you are:
     - My name is Bella Li and I am an 11th grader at Concord Academy in Concord, Massachussets. 
    - Product name and purpose: 
     - My project: MirrorMove PD, uses an AI-powered interactive dance therapy to support Parkinson's patients in rehabilitation. Parkinson's Disease is a super widespread neurodegenerative diseases that lacks effective treatment options. As a dancer and avid student resaercher in Parkinson's Disease, I have learned that dance therapy is a very effective non-medical treatment that improves the movement abilities and cognition. After leading dance therapy workshops myself over the past summers, I wondered if I could create a mobile app that allows patients to participate in dance therapy workshops anytime, anywhere. Thus, I created MirrorMove PD, that 
     
2. Feature Overview
   - App:
     - Account system to sync activity data
     - Home Screen: Overview of activities and stats
     - Session Screen: Remote control of the session
     - Profile Screen: User information and settings (also logout)
     - *Stats Screen: Detailed activity statistics
   - Analysis System:
     - Showcase the pose estimation and companion app
     - 

3. User Interaction (Demo)
- asdf





Run Instructions:
1. Python App / Pose Estimation Demo
```bash
cd analysis
source venv/bin/activate
# To run the app:
python3 app.py
# To show pose estimation:
python3 main.py
```



General Concept Overview:
- Two programs working together: mobile app + desktop companion
- Mobile App
  - Stats and History Tracker
  - Session Controller
    - Start, Pause, Stop session
    - Select song/style
    - View real-time feedback
- Desktop Companion
  - Pose Estimation using MediaPipe
    - Input: computer webcam or whatever designated camera
    - Output: shown on the desktop app
    - Controllable with mobile app
      - Communication via local network (WiFi)
      - How to establish this connection
    - Analysis:
      - Obtain the pose data: give the raw video data to mediapipe
        - Extract landmarks of the subject (x, y, z, visibility of a body part)
        - Calculate relevant metrics (joint angles, distance, etc.)
        - Distance: how different the user is from the reference pose
    - Session Components:
      - Song/Style + Reference Choreography
      - X amount of "key frames" (poses) extracted from the source
        - Less computation load than processing every frame


NOTES FOR BELLA:
For the sake of demonstration the connection logic and popups should now work. If you are running the app via an emulator and also running the desktop app on the same machine use 127.0.0.1 as the connection code. Otherwise, use whatever code is given by the desktop program's popup.