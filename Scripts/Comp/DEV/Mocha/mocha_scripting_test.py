from mocha.project import get_current_project
import mocha.project
import sys
from pathlib import Path

#print(sys.version)


for path in sys.path:
    print(Path(path).parent)

proj = get_current_project()

#mocha = mocha.project
#print(dir(mocha))

prepend = "roto_"

for layer in proj.layers:
    if layer.selected:
        layer.name = prepend + layer.name
#        layer.name = layer.name.replace(prepend, "")

