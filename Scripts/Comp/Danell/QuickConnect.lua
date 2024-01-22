--[[

* UI with 4 buttons. Connect up, down, left, right.
* Only connect if the nodes align exactly horizontally or vertically
* Loop through all connected nodes. Index them in columns/rows
- Loop through the index and each row/column. See if any node is below, find the closest one and then connect to it.

]] --

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 400, 200

win =
    disp:AddWindow(
    {
        ID = "MyWin",
        WindowTitle = "QuickConnect",
        Geometry = {100, 100, width, height},
        Spacing = 10,
        ui:VGroup {
            ID = "root",
            -- Add your GUI elements here:
            ui:HGroup {
                ui:Button {
                    ID = "Up",
                    Text = "Up"
                }
            },
            ui:HGroup {
                ui:Button {
                    ID = "Left",
                    Text = "Left"
                },
                ui:Button {
                    ID = "Right",
                    Text = "Right"
                }
            },
            ui:HGroup {
                ui:Button {
                    ID = "Down",
                    Text = "Down"
                }
            }
        }
    }
)

-- The window was closed
function win.On.MyWin.Close(ev)
    disp:ExitLoop()
end

-- Add your GUI element based event functions here:
itm = win:GetItems()

function win.On.Up.Clicked(ev)
    connect("up")
end

function win.On.Left.Clicked(ev)
    connect("left")
end

function win.On.Right.Clicked(ev)
    connect("right")
end

function win.On.Down.Clicked(ev)
    connect("down")
end

function connect(direction)
    local selected_tools = comp:GetToolList(true)
    if (#selected_tools) < 2 then
        print("Select at least two nodes")
    else
        local flow = comp.CurrentFrame.FlowView
        local active_X, active_Y  -- = flow:GetPos(active_tool)
        local index = {}

        -- De-select org tool
        flow:Select()

        for num, tool in ipairs(selected_tools) do
            --print(tool.Name)
            local X, Y = flow:GetPos(tool)
            local col
            local pos
            if direction == "up" or direction == "down" then
                col = X
                pos = Y
            else
                col = Y
                pos = X
            end

            if index[1] == nil then
                index[1] = {}
                table.insert(index[1], {tool, col, pos})
            else
            	local unique = true
            	-- Loop through all indexed ones
                for i, v in ipairs(index) do
                	-- Check if the column in the same
                	if col == index[i][1][2] then
                		-- Check if tool is already added
                		local uniqueTool = true
                		for j,v2 in ipairs(index[i]) do
		                    if tool == index[i][1][1] then
		                    	uniqueTool = false
	                        end
                		end

                		-- If tool isn't added, add it now
                		if uniqueTool == true then
                    		table.insert(index[i], {tool, col, pos})
                    		unique = false
                		end
                    end
                end
                if unique == true then
                	-- If no column/row was found, make a new one
                	table.insert(index, {{tool, col, pos}})
            	end
            end
        end


        comp:StartUndo("Quick Connect")
        comp:Lock()
        closestTool = nil
        -- Loop through each group
        for i, group in ipairs(index) do
            -- Loop through each node in the group
            for j, mainTool in ipairs(group) do
                -- Loop through each node in the group to check the position compared to our main tool
                for k, checkTool in ipairs(group) do
                    if direction == "down" or direction == "right" then
                    	-- Check if tool is below/right of maintool
                        if checkTool[3] > mainTool[3] then
                            -- If no tool has bin found, add this one
                            if closestTool == nil then
                                closestTool = checkTool
                            else
                                -- If current node is closer to our main tool, use this one instead
                                if checkTool[3] < closestTool[3] then
                                    closestTool = checkTool
                                end
                            end
                        end
                    else
                        if checkTool[3] < mainTool[3] then
                            -- If no tool has bin found, add this one
                            if closestTool == nil then
                                closestTool = checkTool
                            else
                                -- If current node is closer to our main tool, use this one instead
                                if checkTool[3] > closestTool[3] then
                                    closestTool = checkTool
                                end
                            end
                        end
                    end
                end
                if closestTool ~= nil then
                	closestTool[1]:FindMainInput(1):ConnectTo(mainTool[1]:FindMainOutput(1))
                	closestTool = nil
                end
            end
        end
        comp:Unlock()
		comp:EndUndo()

    	--disp:ExitLoop()
    end
end

win:Show()
disp:RunLoop()
win:Hide()
