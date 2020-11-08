_author = "Alexey Bogomolov <mail@abogomolov.com>"
_date = "2020-11-08"
_VERSION = "1.1"

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 460, 300

if not comp then comp = fu:GetCurrentComp() end


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
    Geometry = {800, 500, width, height},
    Spacing = 0,

    ui:VGroup{
        ID = 'root',
        ui:HGroup{
            Weight = 0,
            ui.LineEdit {ID = 'Line', Text = '', Weight = 0.5, Events = {ReturnPressed = true}},
            ui.Button {ID = 'SetCommentButton', Text = 'Set or Replace comment', Weight = .4},
            ui.Button {ID = 'Exit', Text = 'Exit', Weight = .1},
        },
        ui:HGroup{
            Weight = 1,
            ui:Tree{
                Alignment = {AlignHCenter = true, AlignBottom = true},
                ID = 'Tree',
                SortingEnabled = true,
                Events = {ItemClicked = true, ItemDoubleClicked = true}
            }
        },
        ui:HGroup{
            Weight = 0,
            ui:Button{ID = 'Disable', Text = 'Disable'},
            ui:Button{ID = 'Enable', Text = 'Enable'},
            ui:Button{ID = 'Toggle', Text = 'Toggle'},
            ui:Button{ID = 'Select', Text = 'Select'},
            ui:Button{ID = 'Refresh', Text = 'Refresh'},
        },
    }
})

itm = win:GetItems()

local function GetTreeItems(tree)
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

-- Add a header row.
hdr = itm.Tree:NewItem()

function SetHeader(count)
    if count == 0 then
        hdr.Text[0] = 'Select multiple tools and set comments'
    else
        hdr.Text[0] = 'Select a comment from a list below to manage tools'
    end
end

-- countItems = #GetTreeItems(itm.Tree) 

-- SetHeader(countItems)


itm.Line:SetClearButtonEnabled(true)
-- Get all nodes
local tools = comp:GetToolList(false)

-- Gets all items (useful for getting all items in a nested tree without traversing the tree)

function SetComment(comp)
    sel_tools = comp:GetToolList(true)
    if #sel_tools == 0 then
    	return
    end
    if itm.Line.Text == "" then
        print("Clearing comments for selected tools")
        for _, tool in pairs(sel_tools) do
            tool.Comments = ""
        end
        RefreshTable()
        return
    end
    new_comment = "%"..itm.Line.Text
    print("new comment [" .. new_comment:sub(2) .."] is set")
    for _, tool in pairs(sel_tools) do
    	tool.Comments = new_comment
    end
    RefreshTable()
end

-- Add an new row entries to the list
function RefreshTable()
    comp = fu:GetCurrentComp()
	itm.Tree:Clear()
    local tools = comp:GetToolList(false)
    for i, tool in ipairs(tools) do
        if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
            local comment = tool.Comments[fu.TIME_UNDEFINED]
            if comment ~= "" and comment:sub(1,1) == "%" then
                comment = comment:sub(2)
                local alreadyAdded = false
                for i, treeItem in ipairs(GetTreeItems(itm.Tree)) do
                    if treeItem.Text[0] == comment then
                        alreadyAdded = true
                        break
                    end
                end

                if alreadyAdded == false then
                    itRow = itm.Tree:NewItem();
                    itRow.Text[0] = comment
                    itm.Tree:AddTopLevelItem(itRow)
                    itm.Line.Text = comment
                end
            end
        end
    end
    local treeItems = GetTreeItems(itm.Tree)
    SetHeader(#treeItems)
end

-- A Tree view row was clicked on
function win.On.Tree.ItemClicked(ev)
	itm['Line'].Text = ev.item.Text[0]
end

function win.On.Refresh.Clicked(ev)
    print('[Refreshing comment tree]')
    RefreshTable()
end

function win.On.Exit.Clicked(ev)
    disp:ExitLoop()
end

function win.On.Line.ReturnPressed(ev)
    local comp = fu:GetCurrentComp()
    SetComment(comp)
end

function win.On.Tree.ItemDoubleClicked(ev)
    print('[Refreshing comment tree]')
    RefreshTable()
end

function win.On.Select.Clicked(ev)
    local comp = fu:GetCurrentComp()
    flow = comp.CurrentFrame.FlowView
    local tools = comp:GetToolList(false)
    flow:Select()
    comment = itm['Line'].Text
    for i, tool in pairs(tools) do
    	if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
	        if tool.Comments[fu.TIME_UNDEFINED]:sub(2) == comment then
	            flow:Select(tool)
	        end
        end
    end
end

function win.On.SetCommentButton.Clicked(ev)
    local comp = fu:GetCurrentComp()
    SetComment(comp)
end

function win.On.Toggle.Clicked(ev)
    local comp = fu:GetCurrentComp()
    comment = itm.Line.Text
    tools = comp:GetToolList(false)
    count = 0

    comp:StartUndo("Toggling all commented tools " .. comment)

    for _, tool in pairs(tools) do
    	if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
	        if tool.Comments[fu.TIME_UNDEFINED]:sub(2) == comment then
	            count = count + 1
	            if tool:GetAttrs().TOOLB_PassThrough == true then
	                tool:SetAttrs({TOOLB_PassThrough = false})
	            else
	                tool:SetAttrs({TOOLB_PassThrough = true})
	            end
	        end
        end
    end

    comp:EndUndo(true)

    if count == 0 then print('no tools with chosen comment in the comp') end
end

function win.On.Manage.Close(ev)
    disp:ExitLoop()
end

function doPassThrough(operation, report)
    local comp = fu:GetCurrentComp()

    local allTools = comp:GetToolList(false, tool)
    count = 0
    comment = itm['Line'].Text

    comp:StartUndo("Setting " .. comment .. " to " .. report)

    for _, curTool in pairs(allTools) do
    	if curTool:GetAttrs().TOOLB_Visible == true and curTool:GetAttrs().TOOLS_RegID ~= "Note" then
	        if curTool.Comments[fu.TIME_UNDEFINED]:sub(2) == comment then
	            curTool:SetAttrs({TOOLB_PassThrough = operation})
	            count = count + 1
	        end
        end
    end

    comp:EndUndo(true)

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

RefreshTable(tools)
itm.Tree:SetHeaderItem(hdr)

win:Show()
disp:RunLoop()
win:Hide()
