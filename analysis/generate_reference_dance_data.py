import mediapipe as mp
import cv2

"""
1. Open a source video file.
2. Every X seconds, extract a frame.
3. Run pose detection on the frame.
4. Record the landmarks.
5. By the end of the video, save all the landmarks to a file. (CSV)
"""

video_path = "videos/IMG_8407.mp4"
output_csv_path = "reference_dance_data.csv"
time_interval = 3.0  # seconds
frame_rate = 30  # fps
frame_interval = int(frame_rate * time_interval)
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()

cap = cv2.VideoCapture(video_path)
frame_count = 0
landmark_data = []
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    if frame_count % frame_interval == 0:
        pass
