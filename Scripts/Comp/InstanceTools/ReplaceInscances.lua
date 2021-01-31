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

function getOutputs(tool)
    local outs = {} 
    for i, inp in ipairs(tool:GetInputList()) do
        if inp:GetAttrs().INPB_Connected then
            local out = inp:GetConnectedOutput()
            if out then
                table.insert(outs, out)
            end
        end
    end
    return outs
end

function getInputs(tool)
    local index = 1
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
end

function deleteAndGetPositions(comp)
    destTools = {}
    local outs = {}
    local inps = {}
    -- delete old tools and save inputs, outputs and position data
    for i, tool in ipairs(destComp:GetToolList(false)) do
        if tool:GetData("Instanced") then
            posX, posY = flow:GetPos(tool)
            destTools[tool.Name] = {posX, posY}
            outs[tool.Name] = getOutputs(tool)
            inps[tool.Name] = getInputs(tool)
            tool:Delete()
        end
    end
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
    -- sourceComp:Close() -- optionally close source comp

    -- load destination comp
    destComp = fu:LoadComp(compName, true)
    destTools, inps, outs = unpack(deleteAndGetPositions(destComp))
    -- paste source tools 
    destComp:Paste()
    -- get destination comp flow
    destflow = destComp.CurrentFrame.FlowView

    for i, tool in ipairs(destComp:GetToolList(true)) do
        sourceTool = hasKey(destTools, tool.Name)
        -- fix position approximately
        if sourceTool ~= nil then
            pos = destTools[tool.Name]
            destflow:SetPos(tool, pos[1],pos[2])
        end
            
        -- reconnect inputs does not work
        -- local inp = tool:FindMainInput(1)
        -- for name, out in pairs(outs[tool.Name]) do
        --     inp:ConnectTo(out)
        --     print('connected ' ..tool.Name .. ' to output: '.. out:GetTool().Name)
        -- end

        -- this does not work either
        for i, inp in pairs(tool:GetInputList()) do
            if inp:GetAttrs().INPS_ID == "Input" or inp:GetAttrs().INPS_ID == "EffectMask" then
                for i, out in pairs(outs[tool.Name]) do
                    inp:ConnectTo(out)
                end
            end
        end

        -- reconnect outputs works
        local out = tool:FindMainOutput(1)
        if #out:GetConnectedInputs() == 0 then
            for i, inp in pairs(inps[tool.Name]) do
                inp:ConnectTo(out)
                print('connected ' ..tool.Name .. ' to input: '.. inp:GetTool().Name)
            end
        end
    end
end

process()
