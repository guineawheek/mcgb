m1 = peripheral.wrap("monitor_0")
m2 = peripheral.wrap("monitor_1")
m1.setTextScale(0.5)
m2.setTextScale(0.5)
canvas = multipaint({{m1, {0, 159}, {0,80}}, {m2, {0, 159}, {81, 143}}})
-- facing positive z and x
UP = {0, 1, 1}
DOWN = {0, 1, -1}
LEFT = {-1, 1, 0}
RIGHT = {1, 1, 0}

START = {4, 1, -1}
SELECT = {3, 1, -1}
BUTTONB = {6, 1, -1}
BUTTONA = {7, 1, 0}

