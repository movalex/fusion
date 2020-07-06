import BlackmagicFusion as bmd
fusion = bmd.scriptapp('Fusion', 'localhost')
comp = fusion.GetCurrentComp()
print(comp.GetAttrs()['COMPS_FileName'])

# comp.RunScript(r"Scripts:Comp/DEV/IncrementSave.py")
