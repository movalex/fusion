function has_key(tab, key)
    for k,v in ipairs(tab) do
        if k == key then
            return true
        end
    end
    return false
end

tool = comp.ActiveTool or comp:GetToolList(true)[1] 

if not tool then
    print ('no tool selected')
    return
end

data = comp:GetData("ContextTool.contexts")

if not CONTEXT then
    for i = 1, 10 do
        if data and has_key(data, i) then
            CONTEXT = i + 1
        else
            CONTEXT = 1
        end
    end
end

if data then
    local dataToolName = data[CONTEXT]
    local findToolFromData = comp:FindTool(dataToolName)
    if findToolFromData and findToolFromData ~= tool then
        findToolFromData.Comments[fu.TIME_UNDEFINED] = ""
    end
    for i, name in ipairs(data) do
        if name == tool.Name and i ~= CONTEXT then
            table.remove(data, i)
        end
    end
else
    data = {}
end

data[CONTEXT] = tool.Name
comp:SetData("ContextTool.contexts", data)
-- dump(comp:GetData("ContextTool.contexts"))

print(tool.Name ..' is set as context view #'..CONTEXT)
tool.Comments = 'Context ' .. CONTEXT
