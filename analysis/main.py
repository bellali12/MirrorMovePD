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

videoPath = "IMG_8404.mov"

# Setup Mediapipe
mp_pose = mp.solutions.pose
pose = mp_pose.Pose()
mp_drawing = mp.solutions.drawing_utils

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
        # Draw the pose annoptation on the image.
        mp_drawing.draw_landmarks(
            frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
