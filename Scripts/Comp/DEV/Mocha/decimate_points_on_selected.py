import random
from mocha import project
from mocha.ui import get_widgets

REMOVE = 3

proj = get_current_project()

layers = proj.layers

def reduce_spline(selection, amount):
    print(len(selection))
    with proj.undo_group() as ug:
        count = 0
        for layer in selection:
            print(layer.name)
            print(layer.contours)
            contour = layer.contours[0]
            points = contour.control_points
            for point in points:
                count += 1
                if count == amount:
                    point.remove()
                    count = 0


# Get the selected layers
selected_layers = [layer for layer in layers if layer.selected]

reduce_spline(selected_layers, REMOVE)