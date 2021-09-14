import os
import sys
# import imp
from importlib._bootstrap import _load
from importlib import machinery, util
path = "C:\\Program Files\\Blackmagic Design\\Fusion 17\\"
name = "fusionscript.dll"


# fu_mod = imp.load_dynamic("fusionscript", os.path.join(path, "fusionscript.dll"))
def alternative_load_dynamic(name, path, file=None):
    spec = util.spec_from_file_location(name, path + "fusionscript.dll")
    print(spec)
    if spec:
        module = util.module_from_spec(spec)
        sys.modules[name] = module
    # spec.loader.exec_module(module)
        return sys.modules[name]

# print(sys.modules)
# script_module = alternative_load_dynamic(name, path)
# print(sys.modules)

import importlib
import sys

# For illustrative purposes.
# import tokenize
# path = tokenize.__file__
# name = tokenize.__name__

spec = importlib.util.spec_from_file_location(name, path)
print(spec)
module = importlib.util.module_from_spec(spec)
sys.modules[module_name] = module
spec.loader.exec_module(module)



def load_module_new(name, path):
    loader = machinery.ExtensionFileLoader(name, os.path.join(path, name + "dll"))

    # Issue #24748: Skip the sys.modules check in _load_module_shim;
    # always load new extension
    spec = machinery.ModuleSpec(
        name=name, loader=loader, origin=path)
    return _load(spec)



# loader = machinery.SourceFileLoader("fusionscript", os.path.join(path, "fusionscript.dll"))
# print(loader)
# module = loader.load_module("fusionscript")
# print(module)
# module = loader.load_module("fusionscript", path)
# print(module)
# l = machinery.FileFinder(path+"fusionsystem.dll")
# print(dir(loader))
# print(loader.get_filename())
# spec = util.spec_from_loader(loader.name, loader)
# module = util.module_from_spec(spec)
# print("MODULE: ", dir(module))
# print(module.__file__)
# b = loader.exec_module()
# loader.exec_module(mod)
# print(loader.name)
# fu_mod = loader.exec_module()
# sys.modules["BlackmagicFusion"] = b
# import BlackmagicFusion as bmd
# print(dir(bmd))
# fu = bmd.scriptapp("Fusion")
# print(fu.GetCurrentComp().GetAttrs()['COMPS_Name'])
