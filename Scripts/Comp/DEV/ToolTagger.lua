_author = "Alexey Bogomolov <mail@abogomolov.com>"
_date = "2020-12-08"
_VERSION = "1.0"

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width, height = 360, 360

if not comp then comp = fu:GetCurrentComp() end


-- disable jit since Fusion has a Lua bug on a Mac with 16.2 
if fu.Version == 16.2 and FuPLATFORM_MAC == true then
    print('JIT disabled for v16.2 on macOS')
    jit.off()
end

app:AddConfig("Tagger", {
    Target {ID = "Tagger"}, Hotkeys {
        Target = "Tagger",
        Defaults = true,
        ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}"
    }
})

mainWin = ui:FindWindow("Tagger")
if mainWin then
    mainWin:Raise()
    mainWin:ActivateWindow()
    return
end

win = disp:AddWindow({
    ID = 'Tagger',
    TargetID = 'Tagger',
    WindowTitle = 'Tool Tagger',
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
        ui:VGroup{
            Weight = 0,
            ui.LineEdit {ID = 'Line', Text = '', Events = {ReturnPressed = true}},
            ui:HGroup {
                ui.Button { ID = 'SetTagButton', Text = 'Set Tag', Weight = .3 },
                ui.Button { ID = 'DeleteTagButton', Text = 'Delete Tag', Weight = .3 },
            }
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
        hdr.Text[0] = 'Select tools and add tags'
    else
        hdr.Text[0] = 'Select a tag from a list below to manage tools'
    end
end

-- Add clear button
itm.Line:SetClearButtonEnabled(true)

-- Gets all items (useful for getting all items in a nested tree without traversing the tree)

function SetTag(comp)
    sel_tools = comp:GetToolList(true)
    tag = tostring(itm.Line.Text)
    if #sel_tools == 0 then
    	return
    end
    if tag == "" then
        print("choose the tag from the list or assign new tag")
        for _, tool in pairs(sel_tools) do
            comp:SetData("ToolManager")
        end
        return
    end
    data = comp:GetData("ToolManager."..tag) or {}
    for _, tool in pairs(sel_tools) do
        table.insert(data, tool.Name)
    end
    comp:SetData("ToolManager."..tag, data)

    print("new tag [ "..tag.." ] is set")

    RefreshTable()
end


function RefreshTable()
    local currentTag = itm.Line.Text
    comp = fu:GetCurrentComp()
	itm.Tree:Clear()
    local data = comp:GetData("ToolManager")
    if data then
        for tag, tools in pairs(data) do
            local alreadyAdded = false
            for _, treeItem in ipairs(GetTreeItems(itm.Tree)) do
                if treeItem.Text[0] == tostring(tag) then
                    alreadyAdded = true
                    break
                end
            end
            if alreadyAdded == false then
                itRow = itm.Tree:NewItem();
                itRow.Text[0] = tostring(tag)
                itm.Tree:AddTopLevelItem(itRow)
                itm.Line.Text = tostring(tag)
            end
        end
    end
    local treeItems = GetTreeItems(itm.Tree)
    SetHeader(#treeItems)
    itm.Line.Text = currentTag

end

-- A Tree view row was clicked on

function win.On.DeleteTagButton.Clicked(ev)
    local currentTag = itm.Line.Text
    comp:SetData("ToolManager."..currentTag)
    RefreshTable()
end

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
    SetTag(comp)
end

function win.On.Tree.ItemDoubleClicked(ev)
    --RefreshTable()
end

function win.On.SetTagButton.Clicked(ev)
    local comp = fu:GetCurrentComp()
    SetTag(comp)
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

function win.On.Tagger.Close(ev)
    disp:ExitLoop()
end

function win.On.Select.Clicked(ev)
    local comp = fu:GetCurrentComp()
    flow = comp.CurrentFrame.FlowView
    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    flow:Select()
    local tagSearch = itm.Line.Text

    if tagSearch == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            flow:Select(tool)
        end
    else
        local data = comp:GetData("ToolManager")
        for tag, tools in pairs(data) do
            if tostring(tag) == tagSearch then
                for _, tool in ipairs(tools) do
                    flow:Select(comp:FindTool(tool))
                end
            end
        end
    end
end

function win.On.Toggle.Clicked(ev)
    local comp = fu:GetCurrentComp()
    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    local tagSearch = itm.Line.Text

    if tagSearch == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            TogglePassThrough(tool)
        end
    else
         local data = comp:GetData("ToolManager")
         for tag, tools in pairs(data) do
            if tostring(tag) == tagSearch then
                for _, tool in ipairs(tools) do
                    TogglePassThrough(comp:FindTool(tool))
                end
            end
        end
    end
end

function win.On.Lock.Clicked(ev)
    local comp = fu:GetCurrentComp()
    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    local tagSearch = itm.Line.Text

    if tagSearch == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            ToggleLock(tool)
        end
    else
        local data = comp:GetData("ToolManager")
        for tag, tools in pairs(data) do
            if tostring(tag) == tagSearch then
                for _, tool in ipairs(tools) do
                    ToggleLock(comp:FindTool(tool))
                end
            end
        end
    end
end


function doPassThrough(operation, report)
    local comp = fu:GetCurrentComp()

    local allTools = comp:GetToolList(false)
    local selectedTools = comp:GetToolList(true)
    count = 0
    local tagSearch = itm['Line'].Text

    comp:StartUndo(report .. ' tools')

    if tagSearch == "" then
        if #selectedTools == 0 then
            return
        end
        selectedToolId = selectedTools[1].ID
        for i, tool in ipairs(comp:GetToolList(false, selectedToolId)) do
            tool:SetAttrs({TOOLB_PassThrough = operation})
        end
        comp:EndUndo()
    else
        local data = comp:GetData("ToolManager")
        for tag, tools in pairs(data) do
            if tostring(tag) == tagSearch then
                for _, tool in ipairs(tools) do
                    tool = comp:FindTool(tool)
                    if tool then
                        tool:SetAttrs({TOOLB_PassThrough = operation})
                    end
                    count = count + 1
                end
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


-- Get all nodes
local allTools = comp:GetToolList(false)
RefreshTable(allTools)
itm.Tree:SetHeaderItem(hdr)

win:Show()
disp:RunLoop()
win:Hide()
