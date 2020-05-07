_author = "Alexey Bogomolov <mail@abogomolov.com>"
_date = "2020-04-11"
_VERSION = "1.0"

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 300, 300

if not comp then comp = fu:GetCurrentComp() end

flow = comp.CurrentFrame.FlowView

-- disable jit since Fusion has a Lua bug on a Mac with 16.2 
if fu.Version == 16.2 and FuPLATFORM_MAC == true then
    print('JIT disabled for v16.2 on macOS')
    jit.off()
end

app:AddConfig("Manage", {
    Target {ID = "Manage"}, Hotkeys {
        Target = "Manage",
        Defaults = true,
        ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}"
    }
})

mainWin = ui:FindWindow("Manage")
if mainWin then
    mainWin:Raise()
    mainWin:ActivateWindow()
    return
end

win = disp:AddWindow({
    ID = 'Manage',
    TargetID = 'Manage',
    WindowTitle = 'Tool Manager',
    -- Geometry = {0, 500, width, height},
    Spacing = 0,

    ui:VGroup{
        ID = 'root',
        ui:HGroup{
            Weight = 1,
            ui:Tree{
                Alignment = {AlignHCenter = true, AlignBottom = true},
                ID = 'Tree',
                SortingEnabled = true,
                Events = {ItemClicked = true,}
            }
        },
        ui:HGroup{Weight = 0, ui.LineEdit {ID = 'Line', Text = ''}},
        ui:HGroup{
            Weight = 0,
            ui:Button{ID = 'Disable', Text = 'Disable'},
            ui:Button{ID = 'Enable', Text = 'Enable'},
            ui:Button{ID = 'Toggle', Text = 'Toggle'},
            ui:Button{ID = 'Select', Text = 'Select'}
        },
        ui:VGroup{
            Weight = 0,
            ui.Button {ID = 'SetComment', Text = 'Set or Replace comment'},
        }
    }
})

itm = win:GetItems()

-- Add a header row.
hdr = itm.Tree:NewItem()
hdr.Text[0] = 'Comments'
itm.Tree:SetHeaderItem(hdr)

-- Get all underlays in scene
local tools = comp:GetToolList(false)

-- Gets all items (useful for getting all items in a nested tree without traversing the tree)
local function get_all_items(tree)
	return tree:FindItems("*",
	{
		MatchExactly = false,
		MatchFixedString = false,
		MatchContains = false,
		MatchStartsWith = false,
		MatchEndsWith = false,
		MatchCaseSensitive = false,
		MatchRegExp = false,
		MatchWildcard = true,
		MatchWrap = false,
		MatchRecursive = true,
	}, 0)
end

-- Add an new row entries to the list
for i, tool in ipairs(tools) do
	if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
		local comment = tool.Comments[fu.TIME_UNDEFINED]
	    if comment ~= "" then
	    	local alreadyAdded = false
	    	for i,treeItem in ipairs(get_all_items(itm.Tree)) do
	    		if treeItem.Text[0] == comment then
	    			alreadyAdded = true
	    			break;
				end
	    	end

	    	if alreadyAdded == false then
		        itRow = itm.Tree:NewItem();

			    itRow.Text[0] = comment

			    itm.Tree:AddTopLevelItem(itRow)

			    itm['Line'].Text = comment
		    end
	    end
    end
end

-- A Tree view row was clicked on
function win.On.Tree.ItemClicked(ev)
	itm['Line'].Text = ev.item.Text[0]
end

function win.On.Select.Clicked(ev)
    local comp = fu:GetCurrentComp()
    local tools = comp:GetToolList(false)
    flow:Select()
    comment = itm['Line'].Text
    for i, tool in pairs(tools) do
    	if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
	        if tool.Comments[fu.TIME_UNDEFINED] == comment then
	            flow:Select(tool)
	        end
        end
    end
end

function win.On.SetComment.Clicked(ev)
    local comp = fu:GetCurrentComp()
    sel_tools = comp:GetToolList(true)
    if #sel_tools == 0 then
    	return false
    end
    new_comment = itm['Line'].Text
    for _, tool in pairs(sel_tools) do
    	tool.Comments = new_comment
    end
end

function win.On.Toggle.Clicked(ev)
    local comp = fu:GetCurrentComp()
    comment = itm['Line'].Text
    tools = comp:GetToolList(false)
    count = 0

    composition:StartUndo("Toggeling " .. comment)

    for _, tool in pairs(tools) do
    	if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
	        if tool.Comments[fu.TIME_UNDEFINED] == comment then
	            count = count + 1
	            if tool:GetAttrs().TOOLB_PassThrough == true then
	                tool:SetAttrs({TOOLB_PassThrough = false})
	            else
	                tool:SetAttrs({TOOLB_PassThrough = true})
	            end
	        end
        end
    end

    composition:EndUndo(true)

    if count == 0 then print('no tools with chosen comment in the comp') end
end

function win.On.Manage.Close(ev)
    local comp = fu:GetCurrentComp()
    disp:ExitLoop()
end

function doPassThrough(operation, report)
    local comp = fu:GetCurrentComp()

    local allTools = comp:GetToolList(false, tool)
    count = 0
    comment = itm['Line'].Text

    composition:StartUndo("Setting " .. comment .. " to " .. report)

    for _, curTool in pairs(allTools) do
    	if curTool:GetAttrs().TOOLB_Visible == true and curTool:GetAttrs().TOOLS_RegID ~= "Note" then
	        if curTool.Comments[fu.TIME_UNDEFINED] == comment then
	            curTool:SetAttrs({TOOLB_PassThrough = operation})
	            count = count + 1
	        end
        end
    end

    composition:EndUndo(true)

    if count == 0 then
        print('did not find any tools with comment "' .. comment .. '"')
        return
    elseif count == 1 then
        multiple_tool = ' tool'
        print(report .. count .. multiple_tool)
    else
        multiple_tool = ' tools'
        print(report .. count .. multiple_tool)
    end
end

function win.On.Disable.Clicked(ev) doPassThrough(true, 'disabled ') end

function win.On.Enable.Clicked(ev) doPassThrough(false, 'enabled ') end

win:Show()
disp:RunLoop()
win:Hide()
