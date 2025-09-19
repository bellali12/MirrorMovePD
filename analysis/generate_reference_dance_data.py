import pandas as pd
import mediapipe as mp
import cv2

"""
1. Open a source video file.
2. Every X seconds, extract a frame.
3. Run pose detection on the frame.
4. Record the landmarks.
5. By the end of the video, save all the landmarks to a file. (CSV)
"""

# EDIT THIS to your target video path
video_path = "videos/IMG_8407.mp4"

# EDIT THIS to your desired output path
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
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb_frame)
        if results.pose_landmarks:
            landmarks = results.pose_landmarks.landmark
            timestamp = cap.get(cv2.CAP_PROP_POS_MSEC) / 1000.0
            landmark_row = [timestamp] + [coord for landmark in landmarks for coord in (
                landmark.x, landmark.y, landmark.z, landmark.visibility)]
            landmark_data.append(landmark_row)
    frame_count += 1
cap.release()
pose.close()


pose_idx_to_name = {i: lm.name for i, lm in enumerate(mp_pose.PoseLandmark)}
# print(pose_idx_to_name)

columns = ['timestamp'] + [f"{pose_idx_to_name[i]}_{coord}" for i in range(
    len(pose_idx_to_name)) for coord in ['x', 'y', 'z', 'visibility']]
df = pd.DataFrame(landmark_data, columns=columns)
df.to_csv(output_csv_path, index=False)
print(f"Landmark data saved to {output_csv_path}")
