_author = "Alexey Bogomolov <mail@abogomolov.com>"
_date = "2020-11-08"
_VERSION = "1.1"

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 360, 360

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
            ui:Button{ID = 'Disable', Text = 'Disable'},
            ui:Button{ID = 'Enable', Text = 'Enable'},
            ui:Button{ID = 'Toggle', Text = 'Toggle'},
        },
        ui:HGroup{
            Weight = 0,
            ui:Button{ID = 'Select', Text = 'Select'},
            ui:Button{ID = 'Lock', Text = 'Lock'},
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
            ui.LineEdit {ID = 'Line', Text = '', Weight = 0.7, Events = {ReturnPressed = true}},
            ui.Button {ID = 'SetCommentButton', Text = 'Set or Replace comment', Weight = .3},
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

-- Add clear button
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
	itm.Line.Text = ev.item.Text[0]
end

function win.On.Refresh.Clicked(ev)
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
    RefreshTable()
end

function win.On.Select.Clicked(ev)
    local comp = fu:GetCurrentComp()
    flow = comp.CurrentFrame.FlowView
    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    flow:Select()
    comment = itm.Line.Text

    if comment == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            flow:Select(tool)
        end
        return
    end

    for i, tool in pairs(allTools) do
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

function ToggleLock(tool)
    if tool:GetAttrs().TOOLB_Locked == true then
        tool:SetAttrs({TOOLB_Locked = false})
    else
        tool:SetAttrs({TOOLB_Locked = true})
    end
end

function TogglePassThrough(tool)
    if tool:GetAttrs().TOOLB_PassThrough == true then
        tool:SetAttrs({TOOLB_PassThrough = false})
    else
        tool:SetAttrs({TOOLB_PassThrough = true})
    end
end

function win.On.Toggle.Clicked(ev)
    local comp = fu:GetCurrentComp()
    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    local comment = itm.Line.Text

    if comment == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            TogglePassThrough(tool)
        end
        return
    end
    
    for _, tool in pairs(allTools) do
        if tool.Comments then
            if tool.Comments[fu.TIME_UNDEFINED]:sub(2) == comment then
                TogglePassThrough(tool)
            end
        end
    end
end

function win.On.Lock.Clicked(ev)
    local comp = fu:GetCurrentComp()
    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    local comment = itm.Line.Text

    if comment == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            ToggleLock(tool)
        end
        return
    end
    
    for _, tool in pairs(allTools) do
        if tool.Comments then
            if tool.Comments[fu.TIME_UNDEFINED]:sub(2) == comment then
                ToggleLock(tool)
            end
        end
    end
end

function win.On.Manage.Close(ev)
    disp:ExitLoop()
end

function doPassThrough(operation, report)
    local comp = fu:GetCurrentComp()

    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    count = 0
    comment = itm['Line'].Text

    comp:StartUndo(report .. ' tools')

    if comment == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            tool:SetAttrs({TOOLB_PassThrough = operation})
        end
        comp:EndUndo()
        return
    end
    for _, tool in pairs(allTools) do
    	if tool:GetAttrs().TOOLB_Visible == true and tool:GetAttrs().TOOLS_RegID ~= "Note" then
            if tool.Comments[fu.TIME_UNDEFINED]:sub(2) == comment then
	            tool:SetAttrs({TOOLB_PassThrough = operation})
	            count = count + 1
	        end
        end
    end

    comp:EndUndo(true)

    if count == 0 then
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
