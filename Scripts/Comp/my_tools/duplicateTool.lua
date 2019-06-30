-- 22.02.2019 fix compatibility with Fusion 9
-- 15.05.2019 fix slow copy/paste issue

local originalToolList = comp:GetToolList(true)
flow = comp.CurrentFrame.FlowView
composition:StartUndo("Duplicate")
comp:Copy(originalToolList)
flow:Select()
comp:SetActiveTool()
comp:Paste()

if #originalToolList == 1 then
    local x, y = flow:GetPos(originalToolList[1])
    local newTool = comp.ActiveTool
    flow:SetPos(newTool, x+1, y)
end

local duplicateToolList = comp:GetToolList(true)

for i, tool in pairs(originalToolList) do
	for j, input in pairs(tool:GetInputList()) do
		if input:GetAttrs().INPB_Connected then
			-- if duplicateToolList[i]:GetInputList()[j] ~= nil then
            if not duplicateToolList[i]:GetInputList()[j]:GetAttrs().INPB_Connected then
                duplicateToolList[i]:GetInputList()[j]:ConnectTo(input:GetConnectedOutput())
            end
			-- else
				-- print("----ERROR : Input mismatch, nil value found")
			-- end			
		end
	end
end
composition:EndUndo("Duplicate")
