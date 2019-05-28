--stx_kissConnect
--v1.2

function get_tool()
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

function main(tool)
    cmp = fu:GetCurrentComp()
    allNodes = cmp:GetToolList(false)
    flow = cmp.CurrentFrame.FlowView
    data = {}
    selX, selY = flow:GetPos(tool)
    distances = {}
        

    for i, n in pairs(allNodes) do
        tempX, tempY = flow:GetPos(n)
        if tempX and tempY then
            local tempDist = math.sqrt((selX-tempX)*(selX-tempX)+(selY-tempY)*(selY-tempY))
            table.insert(distances,{n, tempDist})
        end
    end

    table.sort(distances, function(b, a) return a[2] > b[2] end)

    -- for k,v in ipairs(distances) do
    --     print(v[1].Name, ' == ', v[2])
    -- end

    tool:ConnectInput("Input", distances[2][1])
    tool:ConnectInput("Background", distances[2][1])
    tool:ConnectInput("MaterialInput", distances[2][1])
    tool:ConnectInput("SceneInput", distances[2][1])
    tool:ConnectInput("SceneInput1", distances[2][1])
    tool:ConnectInput("ProjectiveImage", distances[2][1])
end

tool = get_tool()
if tool then
   main(tool)
end
