# Variables and types
var1 = 10  # Integer variable
var2 = 20.5  # Float variable
var3 = "Hello, World!"  # String variable
var4 = False  # Boolean variable

# Data Structures
myList = [1, 2, 3, 4, 5]  # List
myTuple = (10, 20, 30)  # Tuple
mySet = {1, 2, 3}  # Set
myDict = {"key1": "value1", "key2": "value2"}  # Dictionary

# Conditionals
if var1 < var2:
    print(f"{var1} is less than {var2}")
elif var1 > var2:
    print(f"{var1} is greater than {var2}")
else:
    print(f"{var1} is equal to {var2}")

# - or and not operators
if var1 < var2 and var3 == "Hello, World!":
    print("Both conditions are true")
if var1 < var2 or var3 == "Goodbye!":
    print("At least one condition is true")
if not var4:
    print("var4 is False")


# Loops
for i in myList:
    print(f"List item: {i}")

for i in range(5):
    print(f"Range item: {myList[i]}")

while var1 < 15:
    print(f"var1 is {var1}, incrementing by 1")
    var1 += 1


# Functions


# Classes
