-- 1.08.2014 initial release for Fusion 7 by Sven Neve (House of Secrets) http://www.svenneve.com/?p=922
-- 22.02.2019 general simplification, fix compatibility issues with Fusion 9 by Alex Bogomolov (mail@abogomolov.com)
-- 15.05.2019 fix slow copy/paste issue
comp = fu:GetCurrentComp()
local originalToolList = comp:GetToolList(true)
flow = comp.CurrentFrame.FlowView
comp:Copy(originalToolList)
flow:Select()
comp:Paste()

local duplicateToolList = comp:GetToolList(true)

composition:StartUndo("Duplicate")
for i, tool in ipairs(originalToolList) do
    for j, input in ipairs(tool:GetInputList()) do
        if input:GetAttrs().INPB_Connected then
            local currentInput = duplicateToolList[i]:GetInputList()[j]
            if not currentInput:GetAttrs().INPB_Connected then
                currentInput:ConnectTo(input:GetConnectedOutput())
            end
        end
    end
end
composition:EndUndo("Duplicate")
