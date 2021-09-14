myInputs = {}
for i, inp in ipairs( comp.ActiveTool:GetInputList() ) do 
    myInputs[i] = inp:GetConnectedOutput()    --for each input, get the output connected to it
end

comp.ActiveTool:SetData( "connectedOutputs" , myInputs ) --store the table in the tool's CustomData
comp:Copy( comp.ActiveTool ) -- put the tool on the clipboard