-- 1.08.2014 initial release for Fusion 7 by Sven Neve (House of Secrets) http://www.svenneve.com/?p=922
-- updates by Alex Bogomolov (mail@abogomolov.com):
    -- 22.02.2019 fix some compatibility issues
    -- 15.05.2019 fix slow copy/paste in Fusion 9
comp = fu:GetCurrentComp()
local originalToolList = comp:GetToolList(true)
flow = comp.CurrentFrame.FlowView
comp:Copy(originalToolList)
flow:Select()
comp:StartUndo("Duplicate Tool")
comp:Paste()
duplicateToolList = comp:GetToolList(true)

if #duplicateToolList > 0 then
    for i, tool in pairs(originalToolList) do
        for j, originalInput in pairs(tool:GetInputList()) do
            if originalInput:GetAttrs().INPB_Connected then
                duplicateInput = duplicateToolList[i]:GetInputList()[j]
                if duplicateInput and not duplicateInput:GetAttrs().INPB_Connected then
                    duplicateInput:ConnectTo(originalInput:GetConnectedOutput())
                end
            end
        end
    end
else print("cannot create duplicate")
end
composition:EndUndo("Duplicate")
