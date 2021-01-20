local destComp = fu:GetCurrentComp()
compName = destComp:GetAttrs().COMPS_FileName

function hasKey(tab, value)
    for key, val in pairs(tab) do
        if key == value then
            return key
        end
    end
    return false
end

function hasValue(tab, value) 
    for key, val in pairs(tab) do
        if val == value then
            return true
        end
    end
    return false
end

function getOutputs(tool)
    inputList = {}
    index = 1
    for i, inp in ipairs(tool:GetInputList()) do
        if inp:GetAttrs().INPB_Connected then
            return inp:GetConnectedOutput()
        end
    end
end

function getInputs(tool)
    outputList = {}

    index = 1
    while true do
        out = tool:FindMainOutput(index)
        if out == nil then
            break
        end
        ins = out:GetConnectedInputs()
        if ins then
            return ins
        end
        index = index + 1
    end
    return outputList
end

function deleteAndGetPositions(comp)
    destTools = {}
    inps = {}
    outs = {}
    -- delete old tools and save position data
    for i, tool in ipairs(destComp:GetToolList(false)) do
        if tool:GetData("Instanced") then
            posX, posY = flow:GetPos(tool)
            destTools[tool.Name] = {tool, {posX, posY}}
            inps[tool.Name] = getInputs(tool)
            outs[tool.Name] = getOutputs(tool)
            tool:Delete()
        end
    end
    dump(inps)
    dump(outs)
    return {destTools, inps, outs}
end

function process()
    sourceCompData = fu:GetData("SourceComp")
    if not sourceCompData then
        return
    end
    local sourceComp = fu:LoadComp(sourceCompData, true) 
    flow = sourceComp.CurrentFrame.FlowView
 
    for i, tool in ipairs(sourceComp:GetToolList(false)) do
        if tool:GetData("Instanced") then
            flow:Select(tool)
        end
    end
    
    sourceComp:Copy()
    -- optionally close source comp
    -- sourceComp:Close() 

    -- load destination comp
    destComp = fu:LoadComp(compName, true)

    destTools, inps, outs = unpack(deleteAndGetPositions(destComp))
    -- paste source tools 
    destComp:Paste()
    
    destflow = destComp.CurrentFrame.FlowView
    

    for i, tool in ipairs(destComp:GetToolList(true)) do
        sourceTool = hasKey(destTools, tool.Name)
        -- fix position approximately
        if sourceTool ~= nil then
            pos = destTools[tool.Name][2]
            destflow:SetPos(tool, pos[1],pos[2])
        end
        local input = tool:FindMainInput(1)
        input:ConnectTo(outs[tool.Name])
        for i, inp in pairs(inps[tool.Name]) do
            local out = tool:FindMainOutput(1)
            inp:ConnectTo(out)
        end
    end
end

process()
