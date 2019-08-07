import sys
import os

sys.path.append(os.path.expanduser("~/Downloads/import_file/pymodules"))

try:
    from fu9import import remote_task as rts
except ImportError:
    print('no module imported')

test = rts(os.path.expanduser("~/Downloads/import_file/test1.comp"))
if test:
    print("\nLoaded comp: {}".format(test.GetAttrs()["COMPS_FileName"]))
