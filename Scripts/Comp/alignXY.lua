tool = comp.ActiveTool

function launch_ui()
    d = {}
    d[1] = {"Pos", "Position", Name = "Pos"}
    d[2] = {"XY", "Dropdown", Options = {"X", "Y"}, Default = 1}
    x = comp:AskUser("Align XY", d)
    return x
end

function align(newpos)
    for i, c in ipairs(tool:GetInputList()) do
        if string.find(c.ID, 'Point') then
            xPos = c[1][1]
            yPos = c[1][2]
            print('XY: ', xPos.."  "..yPos)
            if x.XY == 1 then
                c[2] = {xPos, newpos}
            else
                c[2] = {newpos, yPos}
            end
        end
    end
end

if tool and tool.ID == 'PolylineMask' then
    x = launch_ui()
else print('no polygon found')
end

newPos = x.Pos[x.XY+1]
align(newPos)
