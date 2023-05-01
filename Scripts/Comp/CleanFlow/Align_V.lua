-- The script to align nodes vertically
-- Based on original script by DC Turner LineSelectedTools.lua
-- Updates by Alex Bogomolov (mail@abogomolov.com):
--  code refactoring
--  floor node positioning for Fusion 16 and 17 due to the node positioning bug
--  configuration file to launch the script with ALT+V

-- Known issue: if the Node is set to Arrange to grid, and Y pos is less then 0, aligned position will shift to 1 on Y axis


flow = comp.CurrentFrame.FlowView
DEBUG = false

comp:StartUndo("Align Tools Vertically")
selected_tools = comp:GetToolList(true)
active_tool = comp.ActiveTool

if active_tool == nil then
    active_tool = selected_tools[1]
end

active_X, active_Y = flow:GetPos(active_tool)
if DEBUG then
    print(active_X.." - ".. active_Y)
end

if fu.Version >= 16 and fu.Version <= 17 then
    -- floor position coordinnates for older versions
    active_X = math.floor(active_X)
    flow:SetPos(active_tool, active_X, active_Y)
end

for num, tool in pairs(selected_tools) do
    TEMP_Y = flow:GetPos(tool)[2]
    if tool ~= active_tool then
        -- check if nodes have the same Y value
        -- floor the values to switch between horizonal and vertical allignments
        if math.floor(TEMP_Y) == math.floor(active_Y) then 
            newpos = TEMP_Y + (num-1)
        else
            newpos = TEMP_Y
        end
        flow:SetPos(tool, active_X, newpos)
    end
end
comp:EndUndo()
