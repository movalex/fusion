-- 1.08.2014 release of initial script for Fusion 7 by House of Secrets
-- 22.02.2019 script simplification, fix compatibility with Fusion 9
-- 15.05.2019 fix slow copy/paste issue
comp = fu:GetCurrentComp()
local originalToolList = comp:GetToolList(true)
flow = comp.CurrentFrame.FlowView
composition:StartUndo("Duplicate")
comp:Copy(originalToolList)
<<<<<<< HEAD
comp:SetActiveTool()
=======
>>>>>>> 7a858b0924060beeccc907c221962934df4e8bcd
flow:Select()
comp:Paste()

local duplicateToolList = comp:GetToolList(true)

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
