local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 270,160
if not comp then
    comp = fu:GetCurrentComp()
end
checked_state = comp:GetData('MT.use_comments')
flow = comp.CurrentFrame.FlowView

-- disable jit since Fusion has a Lua bug on a Mac with 16.2 
if fu.Version == 16.2 and FuPLATFORM_MAC == true then
    print('JIT disabled for v16.2 on macOS')
    jit.off()
end


function fetch_data(comp)
    last_tool = comp:GetData('MT.tool_id') or get_selected_tool()
    if last_tool then
        return last_tool
    else 
        return nil
    end
end

function get_selected_tool()
    comp = fu:GetCurrentComp()
    active = comp.ActiveTool
    if not active then
        selected_nodes = comp:GetToolList(true)
        if #selected_nodes > 0 then
            return selected_nodes[1].ID
        else
            local data_id = comp:GetData('MT.tool_id') or nil
            return data_id
        end
    end
    return active.ID
end

function print_label()
    local comp = fu:GetCurrentComp()    
    local tool = fetch_data(comp)
    if tool then
        return 'tool: '..tool
    else return 'no tool selected'
    end
end

-- local x = fu:GetMousePos()[1]
-- local y = fu:GetMousePos()[2]
-- if y < 90 then
--     y = 130
-- end
win = disp:AddWindow({
  ID = 'Manage',
  TargetID = 'Manage',
  WindowTitle = 'Manage Tools',
  Geometry = {500, 500, width, height},
  Spacing = 0,
  
  ui:VGroup{
    ID = 'root',
    ui:HGroup {
        ui:Button{ID = 'Disable', Text = 'Disable'},
        ui:Button{ID = 'Enable', Text = 'Enable'},
        ui:Button{ID = 'Select', Text = 'Select'},
    },
    ui:HGroup {
        ui:Label{ID = 'Label', Weight = .6, Text = print_label()},

        -- ui:Button{ID = 'Find', Text = 'Find', Weight=0.1,MinimumSize = {30,16}, 
        -- Alignment = {AlignRight = true}},
            },
    ui:HGroup {

        ui:CheckBox{ID = 'checkbox', Weight = .1, Text = 'with comment:',
                    Alignment = {AlignLeft = true,  AlignVCenter = true},
                    Checked = checked_state or false},
        ui.LineEdit{ID = 'Line', Weight = .2, 
                    Text = comp:GetData('MT.comment') or '1',
                    Events = {ReturnPressed = true}},
        },
        ui:VGroup{
            ui.Button{ID = 'SetComment',  Text = 'Set or Replace comment'},
            ui.Button{ID = 'Toggle', Text = 'Toggle all tools with comment'},
        },
    },
})

itm = win:GetItems()


function win.On.Select.Clicked(ev)
    local comp = fu:GetCurrentComp()
    selectedID = get_selected_tool()
    if not selectedID then
        print('no tool is selected')
        return
    end
    if selectedID ~= comp:GetData('MT.tool_id') then
        comp:SetData('MT.tool_id', selectedID)
        itm['Label'].Text = 'tool: '.. selectedID
    end
    local tools = comp:GetToolList(false, selectedID)
    flow:Select()
    if itm.checkbox.Checked then
        comment = itm['Line'].Text
        for i, tool in pairs(tools) do 
            if tool.Comments[fu.TIME_UNDEFINED] == comment then
                flow:Select(tool)
            end
        end
    else
        for i, tool in pairs(tools) do
            flow:Select(tool) 
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
    comp:SetData('MT.comment', new_comment)
end


function win.On.Toggle.Clicked(ev)
    local comp = fu:GetCurrentComp()
    itm['checkbox'].Checked = true
    comment = itm['Line'].Text
    tools = comp:GetToolList(false)
    count = 0
    for _, tool in pairs(tools) do
        if tool.Comments[fu.TIME_UNDEFINED] == comment then
            count = count + 1
            if tool:GetAttrs().TOOLB_PassThrough == true then
                tool:SetAttrs( {TOOLB_PassThrough = false} )
            else
                tool:SetAttrs( {TOOLB_PassThrough = true} )
            end
        end
    end
    if count == 0 then
        print('no tools with chosen comment in the comp')
    end
end


function win.On.Manage.Close(ev)
    local comp = fu:GetCurrentComp()
    comp:SetData('MT.use_comments', itm['checkbox'].Checked)
    disp:ExitLoop()
end


function win.On.Line.ReturnPressed(ev)
    local comp = fu:GetCurrentComp()
    comp:SetData('MT.comment', itm['Line'].Text)
    print('now searching for comment "'..comp:GetData('MT.comment')..'"')
end


function doPassThrough(operation, report)
    local comp = fu:GetCurrentComp()
    if comp:GetData('MT.tool_id') == nil and comp:GetData('MT.use_comment') == nil then
        print('select any tool to manage')
    end
    if #comp:GetToolList(true) == 0 then
        tool = fetch_data(comp)
    else    
        tool = get_selected_tool()
    end
    if tool then
        if tool.ID ~= comp.GetData('MT.tool_id') then
            print('currently managing ' .. comp:GetData('MT.tool_id') .. '\'s')
        end
        comp:SetData('MT.tool_id', tool)
        itm['Label'].Text = 'tool:  '.. tool
        local allTools = comp:GetToolList(false, tool)
        count = 0
        if itm.checkbox.Checked then
            comment = itm['Line'].Text
            for _, curTool in pairs(allTools) do
                if curTool.Comments[fu.TIME_UNDEFINED] == comment then
                    curTool:SetAttrs( { TOOLB_PassThrough = operation } )
                    count = count + 1
                end
            end
        else
            for _, curTool in pairs(allTools) do
                curTool:SetAttrs( { TOOLB_PassThrough = operation } )
                count = count + 1
            end
        end
        if count == 0 then
            print('did not find any tools with comment "' .. comment..'"')
            return
        elseif count == 1 then
            multiple_tool = ' tool'
            print(report .. count .. multiple_tool)
        else
            multiple_tool = ' tools'
            print(report .. count .. multiple_tool)
        end
    end
end


function win.On.Disable.Clicked(ev)
    doPassThrough(true, 'disabled ')
end


function win.On.Enable.Clicked(ev)
    doPassThrough(false, 'enabled ')
end

app:AddConfig("Manage",
{
    Target  {ID = "Manage"},
    Hotkeys {Target = "Manage",
             Defaults = true,
             ESCAPE = "Execute{cmd = [[app.UIManager:QueueEvent(obj, 'Close', {})]]}" }
})

win:Show()
disp:RunLoop()
win:Hide()
