step = comp:GetPrefs("Comp.Transport.FrameStep")
print('Current framestep is ', step)

FRAMESTEP = 10
DEFAULT = 1

if step == DEFAULT then
    comp:SetPrefs({["Comp.Transport.FrameStep"]=FRAMESTEP})
    print('Setting framestep to ', FRAMESTEP)
else 
    comp:SetPrefs({["Comp.Transport.FrameStep"]=DEFAULT})
    print('Setting framestep to ', DEFAULT)
end