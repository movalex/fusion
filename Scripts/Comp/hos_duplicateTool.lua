-- 22.02.2019 fix compatibility with Fusion 9

local originalToolList = composition:GetToolList(true)
composition:StartUndo("Duplicate")
comp:Copy()
comp:SetActiveTool()
comp:Paste()
local duplicateToolList = composition:GetToolList(true)

for i, tool in ipairs(originalToolList) do
	print(tool.Name)
	for j, input in ipairs(tool:GetInputList()) do
		if input:GetAttrs().INPB_Connected then
			if duplicateToolList[i]:GetInputList()[j] ~= nil then
				if duplicateToolList[i]:GetInputList()[j]:GetAttrs().INPB_Connected then
					print("    " .. input.Name .. " input : both connected")
				else
					print("    " .. input:GetConnectedOutput():GetTool().Name .. "." .. input:GetConnectedOutput().Name .. " only connected to original " .. input.Name .. " input, trying to connect")
					duplicateToolList[i]:GetInputList()[j]:ConnectTo(input:GetConnectedOutput())
					if(duplicateToolList[i]:GetInputList()[j]:GetAttrs().INPB_Connected) then
						print("    connection successful")
					end
				end
			else
				print("----ERROR : Input mismatch, nil value found")
			end			
		end
	end
end
composition:EndUndo("Duplicate")
