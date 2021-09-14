comp:Paste()  -- Paste the tool from the clipboard
myInputs = comp.ActiveTool:GetData( "connectedOutputs" ) -- retrieve the list of connections
if myInputs then
    toolInputs = comp.ActiveTool:GetInputList()  -- retrieve a list of the tool's inputs
    for i, inp in pairs( myInputs ) do
        toolInputs[i]:ConnectTo( inp )
    end
end