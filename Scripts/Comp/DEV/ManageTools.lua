
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 330,140
checked_state = comp:GetData('use_comments')

function fetch_data(cmp)
    last_tool = cmp:GetData('tool_id')
    if last_tool then
        return last_tool
    else 
        return nil
    end
end

function get_selected_tool()
    cmp = fu:GetCurrentComp()
    active = cmp.ActiveTool
    if not active then
        selected_nodes = cmp:GetToolList(true)
        if #selected_nodes == 0 then
            print('select or activate node')
            return None
        end
        return selected_nodes[1].ID
    end
    return active.ID
end

function print_label()
    local cmp = fu:GetCurrentComp()    
    local tool = fetch_data(cmp)
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
      ui:Button{ID = 'Select', Text = 'select'}
      ui:Button{ID = 'Enable', Text = 'Enable',},
    },
    ui.HGroup{
        ui:Label{ID = 'L', Weight = .6, Text = print_label(), 
                Alignment = {AlignLeft = true,  AlignVCenter = true},},
        ui:CheckBox{ID = 'checkbox', Weight = .1, Text = 'with comment:',
                    Alignment = {AlignLeft = true,  AlignVCenter = true},
                    Checked = checked_state or false},
        ui.LineEdit{ID = 'Line', Weight = .2, 
                    Text = comp:GetData('comment') or '1',
                    Events = {ReturnPressed = true}},
        }, 
        ui:VGroup{
            ui.Button{ID = 'SetComment',  Text = 'Set/Replace comment'},
            ui.Button{ID = 'Toggle', Text = 'Toggle all tools with comment'},
        },
    },
})

itm = win:GetItems()

function win.On.SetComment.Clicked(ev)
    local cmp = fu:GetCurrentComp()
    sel_tools = cmp:GetToolList(true)
    if #sel_tools == 0 then
        return false
    end
    new_comment = itm['Line'].Text
    for _, tool in pairs(sel_tools) do
        tool.Comments = new_comment
    end
    cmp:SetData('comment', new_comment)
end


function win.On.Toggle.Clicked(ev)
    local cmp = fu:GetCurrentComp()
    itm['checkbox'].Checked = true
    local comment = itm['Line'].Text
    local tools = cmp:GetToolList(false)
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
    local cmp = fu:GetCurrentComp()
    cmp:SetData('use_comments', itm['checkbox'].Checked)
    disp:ExitLoop()
end


function win.On.Line.ReturnPressed(ev)
    local cmp = fu:GetCurrentComp()
    cmp:SetData('comment', itm['Line'].Text)
    print('now searching for comment "'..cmp:GetData('comment')..'"')
end


function operate(operation, report)
    cmp = fu:GetCurrentComp()
    if cmp:GetData('tool_id') == nil and cmp:GetData('use_comment') == nil then
        print('select any tool to manage')
    end
    if #cmp:GetToolList(true) == 0 then
        tool = fetch_data(cmp)
    else    
        tool = get_selected_tool()
    end
    if tool then
        cmp:SetData('tool_id', tool)
        print('currently managing ', cmp:GetData('tool_id'), 'tools')
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

