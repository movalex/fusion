--stx_kissConnect
--v1.2

function GetTool()
    active = comp.ActiveTool
    if not active then
        selected_node = comp:GetToolList(true)[1]
        if not selected_node then
            print('select or activate node')
            return None
        end
        return selected_node
    end
    return active
end

function KissConnect(tool)
    cmp = fu:GetCurrentComp()
    allNodes = cmp:GetToolList(false)
    flow = cmp.CurrentFrame.FlowView
    data = {}
    selX, selY = flow:GetPos(tool)
    distances = {}
        

    for i, node in pairs(allNodes) do
        tempX, tempY = flow:GetPos(node)
        if tempX and tempY then
            local tempDist = math.sqrt((selX-tempX)*(selX-tempX)+(selY-tempY)*(selY-tempY))
            table.insert(distances,{node, tempDist})
        end
    end

    table.sort(distances, function(b, a) return a[2] > b[2] end)
    -- dump(distances)

    -- for k,v in ipairs(distances) do
    --     print(v[1].Name, ' == ', v[2])
    -- end

    tool:ConnectInput("Input", distances[2][1])
    tool:ConnectInput("Background", distances[2][1])
    tool:ConnectInput("MaterialInput", distances[2][1])
    tool:ConnectInput("SceneInput", distances[2][1])
    tool:ConnectInput("SceneInput1", distances[2][1])
    tool:ConnectInput("ProjectiveImage", distances[2][1])
    if tool.ID == "Background" or tool:GetAttrs().TOOLI_Number_o_Inputs == 0 then
        tool:ConnectInput("EffectMask", distances[2][1])
    end
end

tool = GetTool()
if tool then
    KissConnect(tool)
end
