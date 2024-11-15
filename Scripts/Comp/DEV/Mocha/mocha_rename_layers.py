from mocha.project import get_current_project
proj = get_current_project()

prepend = "mask_"

for layer in proj.layers:
    if layer.selected and not layer.name.startswith(prepend):
        layer.name = prepend + layer.name
#        layer.name = layer.name.replace(prepend, "")

