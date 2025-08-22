# # Variables and types
# var1 = 10  # Integer variable
# var2 = 20.5  # Float variable
# var3 = "Hello, World!"  # String variable
# var4 = False  # Boolean variable

# # Data Structures
# myList = [1, 2, 3, 4, 5]  # List
# myTuple = (10, 20, 30)  # Tuple
# mySet = {1, 2, 3}  # Set
# myDict = {"key1": "value1", "key2": "value2"}  # Dictionary

# # Conditionals
# if var1 < var2:
#     print(f"{var1} is less than {var2}")
# elif var1 > var2:
#     print(f"{var1} is greater than {var2}")
# else:
#     print(f"{var1} is equal to {var2}")

# # - or and not operators
# if var1 < var2 and var3 == "Hello, World!":
#     print("Both conditions are true")
# if var1 < var2 or var3 == "Goodbye!":
#     print("At least one condition is true")
# if not var4:
#     print("var4 is False")


# # Loops
# for i in myList:
#     print(f"List item: {i}")

# for i in range(5):
#     print(f"Range item: {myList[i]}")

# while var1 < 15:
#     print(f"var1 is {var1}, incrementing by 1")
#     var1 += 1


# # Functions
# def foo():
#     print("This is a simple function.")


# foo()


# def add(a, b):
#     return a + b


# result = add(3, 4)
# print(result)


# # Classes (OOP)
# # properties (variables)
# # constructor
# # methods (functions)
# class MyClass:
#     def __init__(self, name):
#         self.name = name

#     def greet(self):
#         print(f"Hello, {self.name}!")


# # Create an instance of MyClass
# my_instance = MyClass("Bella")
# my_instance.greet()
# my_instance2 = MyClass("Charlie")
# my_instance2.greet()

import mediapipe as mp
import cv2
from mediapipe.framework.formats import landmark_pb2

# Helper Variables
POSE_FACE_IDX = set(range(1, 11))
NOSE_IDX = 0
LEFT_EYE_IDX = 2
RIGHT_EYE_IDX = 5
LEFT_EAR_IDX = 7
RIGHT_EAR_IDX = 8

# videoPath = "videos/IMG_8404.mp4"
videoPath = "videos/IMG_8407.mp4"
cartoon_face = "images/stitch face.png"

# Load the cartoon face
overlay_img = None
if cartoon_face:
    overlay_img = cv2.imread(cartoon_face, cv2.IMREAD_UNCHANGED)  # BGRA
    if overlay_img is not None:
        print("Cartoon face image loaded successfully.")
    else:
        print("Error loading cartoon face image.")

# Setup Mediapipe
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles


# Helper Functions
def get_head_anchor_and_angle(landmarks, image_width, image_height):
    nose = landmarks[NOSE_IDX]
    left_eye = landmarks[LEFT_EYE_IDX]
    right_eye = landmarks[RIGHT_EYE_IDX]
    left_ear = landmarks[LEFT_EAR_IDX]
    right_ear = landmarks[RIGHT_EAR_IDX]

    anchor_x = int(nose.x * image_width)
    anchor_y = int(nose.y * image_height)

    # Calculate the angle
    if (left_eye.visibility > 0.7 and right_eye.visibility > 0.7):
        left_x = left_eye.x * image_width
        left_y = left_eye.y * image_height
        right_x = right_eye.x * image_width
        right_y = right_eye.y * image_height
    elif (left_ear.visibility > 0.7 and right_ear.visibility > 0.7):
        left_x = left_ear.x * image_width
        left_y = left_ear.y * image_height
        right_x = right_ear.x * image_width
        right_y = right_ear.y * image_height

    # positive y is downwards so a positive angle is counterclockwise
    angle = cv2.fastAtan2(left_y - right_y, left_x - right_x)


# Video Input Capture
cap = cv2.VideoCapture(videoPath)  # 0 for webcam

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        print("Ignoring empty camera frame.")
        break

    # Convert the BGR image to RGB.
    image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = pose.process(image)

    if results.pose_landmarks:
        landmarks = results.pose_landmarks.landmark
        drawn_landmarks = []
        for idx, landmark in enumerate(landmarks):
            if idx in POSE_FACE_IDX:  # don't draw face landmarks
                modified_landmark = landmark_pb2.NormalizedLandmark(
                    x=landmark.x, y=landmark.y, z=landmark.z, visibility=0.0)
            else:  # draw other landmarks
                modified_landmark = landmark
            drawn_landmarks.append(modified_landmark)

        modified_landmarks = landmark_pb2.NormalizedLandmarkList(
            landmark=drawn_landmarks)

        # Draw the pose annoptation on the image.
        mp_drawing.draw_landmarks(
            frame, modified_landmarks, mp_pose.POSE_CONNECTIONS)

        if overlay_img is not None:
            pass

    cv2.imshow('MediaPipe Pose', frame)
    # press 'q' to quit
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
