import sys
import imp
path = "C:\\Program Files\\Blackmagic Design\\Fusion 17\\"
fu_mod = imp.load_dynamic("fusionscript", path + "fusionscript.dll")
sys.modules["BlackmagicFusion"] = fu_mod
import BlackmagicFusion as bmd
fu = bmd.scriptapp("Fusion")
print(fu.GetCurrentComp().GetAttrs()['COMPS_Name'])
