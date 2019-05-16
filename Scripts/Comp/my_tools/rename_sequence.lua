-- this script will rename selected nodes sequentially
tools = comp:GetToolList(true)
if next(tools) == nil then
    print('Select tools to rename')
else
    comp:StartUndo("batch rename")
    comp:Lock()
    for num, tool in ipairs(tools) do
        print('setting name ' ..tool.Name)
        tool:SetAttrs({TOOLS_Name = tool.ID .. '_' .. string.format("%03d",num)})
    end
    comp:Unlock()
    comp:EndUndo()
end