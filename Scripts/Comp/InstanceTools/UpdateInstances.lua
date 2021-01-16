comp = fu:GetCurrentComp()
compName = comp:GetAttrs().COMPS_FileName

function main()
    sourceCompData = fu:GetData("SourceComp")
    if not sourceCompData then
        return
    end
    sourceComp = fu:LoadComp(sourceCompData, true) 
    settingsTable = {}

    for i, tool in ipairs(sourceComp:GetToolList(false)) do
        if tool:GetData("Instanced") then
            settingsTable[tool.Name] = sourceComp:CopySettings(tool)
        end
    end

    comp = fu:LoadComp(compName, true)
    local counter = 0

    for toolName, setting in pairs(settingsTable) do
        tool = comp:FindTool(toolName)
        if tool then
            tool:LoadSettings(setting)
            counter = counter + 1
        end
    end

    if counter > 0 then
        local multiple = ""
        if counter > 1 then
            multiple = "s"
        end
        print('Updated '.. counter .. ' instanced tool'..multiple)
    end
end

main()
