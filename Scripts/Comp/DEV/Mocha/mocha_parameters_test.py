from mocha.project import get_current_project
proj = get_current_project()

prepend = "roto_"

all_layers = proj.layers


def test_layers(layers):
    for layer in layers:
        lps = layer.parameter_set()
        traverse(lps)
        if layer.selected and not layer.name.startswith(prepend):
            layer.name = prepend + layer.name


def enable_motion_blur(layers):
    for layer in layers:
        print(dir(layer))


# enable_motion_blur(all_layers)



def traverse(ps):
    for param in ps.parameters:
        # print(dir(param))
        print(param.full_path, param.value)
#    for paramSet in ps.subsets:
 #       sub = traverse(paramSet)



# traverse(proj.parameter_set())
test_layers(all_layers)