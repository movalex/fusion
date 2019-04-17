
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 330,110
checked_state = comp:GetData('check_enabled')

function fetch_data()
    last_tool = comp:GetData('tool_id')
    if last_tool then
        return last_tool
    else 
        return nil
    end
end

function get_selected_tool()
    active = comp.ActiveTool
    if not active then
        selected_nodes = comp:GetToolList(true)
        if #selected_nodes == 0 then
            print('select or activate node')
            return None
        end
        return selected_nodes[1].ID
    end
    return active.ID
end

function print_label()
    local tool = fetch_data()
    -- print('tool is '.. tool)
    if tool then
        return 'last used: '..tool
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
    ui:HGroup{
      ui:Button{ID = 'Disable', Text = 'Disable',},
      ui:Button{ID = 'Enable', Text = 'Enable',},
    },
    ui.HGroup{
        ui:Label{ID = 'L', Weight = .7, Text = print_label(), 
                Alignment = {AlignLeft = true,  AlignVCenter = true},},
        ui:CheckBox{ID = 'checkbox', Weight = .1, Text = 'use comment:',
                    Alignment = {AlignLeft = true,  AlignVCenter = true},
                    Checked = checked_state or false},
        ui.LineEdit{ID = 'Line', Weight = .2, 
                    Text = comp:GetData('comment') or '1',
                    Events = {ReturnPressed = true}}
    }, 
    ui:HGroup{
        ui.Button{ID = 'Toggle', Text = 'Toggle All Tools with Comment'},
    }
    
  },
})


itm = win:GetItems()


function win.On.Toggle.Clicked(ev)
    local comment = itm['Line'].Text
    local tools = comp:GetToolList(false)
    count = 0
    for _, tool in pairs(tools) do
        if tool.Comments[fu.TIME_UNDEFINED] == comment then
            count = count + 1
            if tool:GetAttrs().TOOLB_PassThrough == true then
                tool:SetAttrs( { TOOLB_PassThrough = false } )
            else
                tool:SetAttrs( { TOOLB_PassThrough = true } )
            end
        end
    end
    if count == 0 then
        print('no tools with chosen comment in the comp')
    end
end


function win.On.Manage.Close(ev)
    comp:SetData('check_enabled', itm['checkbox'].Checked)
    disp:ExitLoop()
end

-- function win.On.checkbox.Clicked(ev)
--     print('clicked')
-- end

function win.On.Line.ReturnPressed(ev)
    comp:SetData('comment', itm['Line'].Text)
    print('now searching for comment "'..comp:GetData('comment')..'"')
end


function check_selected(tool)
    return tool:GetAttrs('TOOLB_Selected')
end

function check_enabled(tool)
    return tool:GetAttrs('TOOLB_PassThrough')
end


function operate(operation, report)
    cmp = fu:GetCurrentComp()
    if #cmp:GetToolList(true) == 0 then
        tool = fetch_data()
    else    
        tool = get_selected_tool()
    end

    if tool then
        cmp:SetData('tool_id', tool)
        print(cmp:GetData('tool_id'))
        itm['L'].Text = 'tool:  '.. tool
        local allTools = cmp:GetToolList(false, tool)
        count = 0
        for _, curTool in pairs(allTools) do
            if itm.checkbox.Checked then
                comment = itm['Line'].Text
                if curTool.Comments[fu.TIME_UNDEFINED] == comment then
                    curTool:SetAttrs( { TOOLB_PassThrough = operation } )
                    count = count + 1
                end
            else
                curTool:SetAttrs( { TOOLB_PassThrough = operation } )
                count = count + 1
            end
        end
        if count and count == 0 then
            print('did not find any tools with comment "' .. comment..'"')
        else print(report ..count.. ' tools')
        end
    end
end


function win.On.Disable.Clicked(ev)
operate(true, 'disabled ')
end


function win.On.Enable.Clicked(ev)
    operate(false, 'enabled ')
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

