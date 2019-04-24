--stx_kissConnect
--v1.2
-- disabled cmp locking, caused some issues

-- lock cmp
-- cmp:Lock()

-- get selection 
cmp = fu:GetCurrentComp()
-- selectedNodes = cmp:GetToolList(true)
selectedNodes = cmp:GetToolList(true)
allNodes = cmp:GetToolList(false)

flow = cmp.CurrentFrame.FlowView
data = {}

selX, selY = flow:GetPos(selectedNodes[1])

distances = {}
for i, n in pairs(allNodes) do
	--print(flow:GetPos(allNodes[i]))
	tempX, tempY = flow:GetPos(n)
    if tempX and tempY then
        local tempDist = math.sqrt((selX-tempX)*(selX-tempX)+(selY-tempY)*(selY-tempY))
        table.insert(distances,{n, tempDist})
    end
	--print(tempDist)
end

table.sort(distances, function(b, a) return a[2] > b[2] end)

-- for k,v in ipairs(distances) do
--     print(v[1].Name, ' == ', v[2])
-- end

selectedNodes[1]:ConnectInput("Input", distances[2][1])
selectedNodes[1]:ConnectInput("Background", distances[2][1])
selectedNodes[1]:ConnectInput("MaterialInput", distances[2][1])
selectedNodes[1]:ConnectInput("SceneInput", distances[2][1])
selectedNodes[1]:ConnectInput("SceneInput1", distances[2][1])

--cmp:Unlock()
