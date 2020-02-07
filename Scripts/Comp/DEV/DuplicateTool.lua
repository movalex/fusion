-- 1.08.2014 initial release for Fusion 7 by Sven Neve (House of Secrets) http://www.svenneve.com/?p=922
-- 22.02.2019 fix compatibility issues with Fusion 9 by Alex Bogomolov (mail@abogomolov.com)
-- 15.05.2019 fix slow copy/paste issue
comp = fu:GetCurrentComp()
local originalToolList = comp:GetToolList(true)
flow = comp.CurrentFrame.FlowView
comp:Copy(originalToolList)
flow:Select()

comp:Paste()

duplicateToolList = comp:GetToolList(true)

function tableToDict(tab)
	dict = {}
	for i, k in pairs(tab) do
		dict[k.ID] = true
	end
	return dict
end

function fixNrOfInputs(target, current, tool, duplicate)
	toolIList = tableToDict(tool:GetInputList())
	duplIList = tableToDict(duplicate:GetInputList())
	for i, k in pairs(duplIList) do
		toolIList[i] = nil
	end
	local count = 0
	local workingOutput = nil
	while workingOutput == nil do
		count = count + 1
		workingOutput = tool
	end
end

composition:StartUndo("Duplicate")
if #duplicateToolList > 0 then
    for i, tool in pairs(originalToolList) do
        toolAttrs = tool:GetAttrs()
        duplicateAttrs = duplicateToolList[i]:GetAttrs()
        if toolAttrs.TOOLI_Number_o_Inputs ~= duplicateAttrs.TOOLI_Number_o_Inputs then
            fixNrOfInputs(toolAttrs.TOOLI_Number_o_Inputs, duplicateAttrs.TOOLI_Number_o_Inputs, tool, duplicateToolList[i])
        end
        for j, originalInput in pairs(tool:GetInputList()) do
            if originalInput:GetAttrs().INPB_Connected then
                duplicateInput = duplicateToolList[i]:GetInputList()[j]
                if duplicateInput and not duplicateInput:GetAttrs().INPB_Connected then
                    duplicateInput:ConnectTo(originalInput:GetConnectedOutput())
                end
            end
        end
    end
else print("Fusion did not select pasted tools, cannot check connections")
end
composition:EndUndo("Duplicate")
