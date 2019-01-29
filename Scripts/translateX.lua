-- get all selected Merge nodes
tools = comp:GetToolList(true, 'Merge')
-- set default X offset 
centerX = 0.5
-- offset Merges
for num, tool in ipairs(tools) do
    centerX = centerX + 1
    print('Setting offset to ' ..tool.Name)
    tool.Center = {centerX, 0.5} 
end