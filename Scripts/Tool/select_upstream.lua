-- https://www.steakunderwater.com/wesuckless/viewtopic.php?p=9319#p9319

local flow = comp.CurrentFrame.FlowView
 
function recurseSelect(t)
    -- if the current tool has image inputs, select them, otherwise return nil
    flow:Select(t)
   
    for i, inp in pairs(t:GetInputList()) do
 
        if valid_types[inp:GetAttrs().INPS_DataType] then
            local output = inp:GetConnectedOutput()
            if output then
                recurseSelect(output:GetTool())
            end
        end
    end
   
end
 
valid_types = {
    Image = true,
    Particles = true,
    Mask = true,
    DataType3D = true,
    }
 
flow:Select() -- clear current selections
 
recurseSelect(tool)
