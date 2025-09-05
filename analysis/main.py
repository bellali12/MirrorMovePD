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
    return (anchor_x, anchor_y), angle


def calculate_angle(p1, p2, p3):
    a = ((p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2) ** 0.5
    b = ((p2.x - p3.x) ** 2 + (p2.y - p3.y) ** 2) ** 0.5
    c = ((p3.x - p1.x) ** 2 + (p3.y - p1.y) ** 2) ** 0.5
    if a * b == 0:
        return 0.0
    angle = cv2.acos((a * a + b * b - c * c) / (2 * a * b))
    return angle * 180.0 / 3.141592653589793


def get_pose_distance(reference_landmarks, current_landmarks):
    """
    To account for the potential size differences of the person in both sources, we need to do the following:
    1. get the nose to knee distance in both sources
    2. calculate the scale factor between both distances
    3. multiply the reference landmarks by the scale factor
    4. to also account for position offset, we will also get the average of the shoulder and hip positions in both sources
    5. calculate the offset between both averages
    6. add the offset to the reference landmarks
    """
    comparison_scale = 1.0
    offset_x = 0.0
    offset_y = 0.0

    if (reference_landmarks and current_landmarks):
        # Get the nose to knee distance in both sources
        ref_nose = reference_landmarks[0]
        ref_left_knee = reference_landmarks[25]
        ref_right_knee = reference_landmarks[26]
        ref_knee = landmark_pb2.NormalizedLandmark(
            x=(ref_left_knee.x + ref_right_knee.x) / 2,
            y=(ref_left_knee.y + ref_right_knee.y) / 2,
            z=(ref_left_knee.z + ref_right_knee.z) / 2,
            visibility=(ref_left_knee.visibility +
                        ref_right_knee.visibility) / 2,
        )
        ref_nose_to_knee = ((ref_nose.x - ref_knee.x) **
                            2 + (ref_nose.y - ref_knee.y) ** 2) ** 0.5
        curr_nose = current_landmarks[0]
        curr_left_knee = current_landmarks[25]
        curr_right_knee = current_landmarks[26]
        curr_knee = landmark_pb2.NormalizedLandmark(
            x=(curr_left_knee.x + curr_right_knee.x) / 2,
            y=(curr_left_knee.y + curr_right_knee.y) / 2,
            z=(curr_left_knee.z + curr_right_knee.z) / 2,
            visibility=(curr_left_knee.visibility +
                        curr_right_knee.visibility) / 2,
        )
        curr_nose_to_knee = ((curr_nose.x - curr_knee.x) **
                             2 + (curr_nose.y - curr_knee.y) ** 2) ** 0.5

        if ref_nose_to_knee > 0:
            comparison_scale = curr_nose_to_knee / ref_nose_to_knee
        else:
            pass  # TODO: consider a higher scope variable

        # Get the average of the torso in both sources
        ref_left_shoulder = reference_landmarks[11]
        ref_right_shoulder = reference_landmarks[12]
        ref_left_hip = reference_landmarks[23]
        ref_right_hip = reference_landmarks[24]
        ref_torso = landmark_pb2.NormalizedLandmark(
            x=(ref_left_shoulder.x + ref_right_shoulder.x +
               ref_left_hip.x + ref_right_hip.x) / 4,
            y=(ref_left_shoulder.y + ref_right_shoulder.y +
               ref_left_hip.y + ref_right_hip.y) / 4,
            z=(ref_left_shoulder.z + ref_right_shoulder.z +
               ref_left_hip.z + ref_right_hip.z) / 4,
            visibility=(ref_left_shoulder.visibility + ref_right_shoulder.visibility +
                        ref_left_hip.visibility + ref_right_hip.visibility) / 4,
        )
        curr_left_shoulder = current_landmarks[11]
        curr_right_shoulder = current_landmarks[12]
        curr_left_hip = current_landmarks[23]
        curr_right_hip = current_landmarks[24]
        curr_torso = landmark_pb2.NormalizedLandmark(
            x=(curr_left_shoulder.x + curr_right_shoulder.x +
               curr_left_hip.x + curr_right_hip.x) / 4,
            y=(curr_left_shoulder.y + curr_right_shoulder.y +
               curr_left_hip.y + curr_right_hip.y) / 4,
            z=(curr_left_shoulder.z + curr_right_shoulder.z +
               curr_left_hip.z + curr_right_hip.z) / 4,
            visibility=(curr_left_shoulder.visibility + curr_right_shoulder.visibility +
                        curr_left_hip.visibility + curr_right_hip.visibility) / 4,
        )
        offset_x = curr_torso.x - ref_torso.x
        offset_y = curr_torso.y - ref_torso.y

        # Calculate the landmarks distance
        distance = 0.0
        for ref_lm, curr_lm in zip(reference_landmarks, current_landmarks):
            adjusted_ref_x = ref_lm.x * comparison_scale + offset_x
            adjusted_ref_y = ref_lm.y * comparison_scale + offset_y
            distance += ((adjusted_ref_x - curr_lm.x) ** 2 +
                         (adjusted_ref_y - curr_lm.y) ** 2) ** 0.5
        distance /= len(reference_landmarks)
        return distance


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
