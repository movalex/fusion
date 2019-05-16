import sys
import BlackmagicFusion as bmd
print(sys.path)
from fu9import import importNodeTreeTemplate as imp
# sys.path.append(r'/Users/videopro/Documents/pymodules')
# print(bmd)
fusion = bmd.scriptapp("Fusion")
print(fusion)
# print(bmd.scriptapp("Fusion"))
comp = fusion.GetCurrentComp()
print(comp.GetAttrs())


test = imp(r'/Users/videopro/Downloads/test.comp')
print('\nLoaded comp: {}'.format(test.GetAttrs()['COMPS_FileName']))
