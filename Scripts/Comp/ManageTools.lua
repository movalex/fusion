
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 330,70
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
  Spacing = 5,
  
  ui:VGroup{
    ID = 'root',
    -- Add your GUI elements here:
    ui:HGroup{
      ui:Button{ID = 'Disable', Text = 'Disable',},
      ui:Button{ID = 'Enable', Text = 'Enable',},

    },
    ui.HGroup{
        Margin = 3,
        ui:Label{ID = 'L', Weight = .7, Text = print_label(), Alignment = {AlignLeft = true,  AlignVCenter = true},},
        ui:CheckBox{ID = 'checkbox', Weight = .1, Text = 'use comment:', Alignment = {AlignLeft = true,  AlignVCenter = true}, Checked = checked_state or false},
        -- ui:Label{ID = 'comm', Weight = .2, Text = 'Use comment:', Alignment = {AlignRight = true, AlignVCenter = true},},
        ui.LineEdit{ID = 'Line', Weight = .2, Text = comp:GetData('comment') or '1', Events = {ReturnPressed = true}}
    }
  },
})


itm = win:GetItems()

function win.On.Manage.Close(ev)
    comp:SetData('check_enabled', itm['checkbox'].Checked)
    disp:ExitLoop()
end

-- function win.On.checkbox.Clicked(ev)
--     print('clicked')
-- end

function win.On.Line.ReturnPressed(ev)
    comp:SetData('comment', itm['Line'].Text)
    -- comp:SetData('comment','11')
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
-- function win.On.Disable.Clicked(ev)
--     local cmp = fu:GetCurrentComp()
--     if #cmp:GetToolList(true) == 0 then
--         tool = fetch_data()
--     else    
--         tool = get_selected_tool()
--     end

--     if tool then
--         itm['L'].Text = 'tool:  '.. tool
--         local allTools = cmp:GetToolList(false, tool)
--         cmp:SetData('tool_id', tool)
--         count = 0
--         for _, curTool in pairs(allTools) do
--             if itm.checkbox.Checked then
--                 comment = itm['Line'].Text
--                 if curTool.Comments[fu.TIME_UNDEFINED] == comment then
--                     curTool:SetAttrs( { TOOLB_PassThrough = true } )
--                     count = count + 1
--                 end
--             else
--                 curTool:SetAttrs( { TOOLB_PassThrough = true } )
--             end
--         end
--         if count and count == 0 then
--             print('did not find any tools with comment "' .. comment..'"')
--         else print('disabled ' ..count.. ' tools')
--         end
--     end

-- end


function win.On.Enable.Clicked(ev)
    operate(false, 'enabled ')
     -- tool = get_selected_tool()
    -- local allTools = comp:GetToolList(false, tool)
    -- if tool then
    --     for _, currentTool in pairs(allTools) do
    --         if itm.checkbox.Checked then
                
    --         else    
    --             currentTool:SetAttrs( { TOOLB_PassThrough = false } )
    --     end
    -- end
    -- comp:Lock()
    -- local allTools = comp:GetToolList(false, tool)
    --     for i, currentTool in pairs(allTools) do
    --         currentTool:SetAttrs( { TOOLB_PassThrough = false } )
    --     end
    -- comp:Unlock()
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

