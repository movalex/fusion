
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 400,50

function showUI(tool)

  win = disp:AddWindow({
    ID = 'MyWin',
    WindowTitle = 'AngleSwitch',
    Geometry = {200, 300, width, height},
    Spacing = 1,
    ui:VGroup{
    -- VMargin = 10,
    ID = 'root',
    -- Add your GUI elements here:
    ui:ComboBox{ID = 'MyCombo', Text = 'Combo Menu',},
    },
  })

  -- The window was closed
  function win.On.MyWin.Close(ev)
  disp:ExitLoop()
  end

  -- Add your GUI element based event functions here:
  itm = win:GetItems()

  -- Add the items to the ComboBox menu
  itm.MyCombo:AddItem('Default')
  itm.MyCombo:AddItem('Bob')
  itm.MyCombo:AddItem('Jack')

  -- This function is run when a user picks a different setting in the ComboBox control
  function win.On.MyCombo.CurrentIndexChanged(ev)
    if itm.MyCombo.CurrentIndex == 0 then
        -- Default
        print('[' .. itm.MyCombo.CurrentText .. '] Lets make def not to turn.')
        print('setting angle for ' .. active_tool_id)
        active.Angle = 0
    elseif itm.MyCombo.CurrentIndex == 1 then
        -- Bob
        print('[' .. itm.MyCombo.CurrentText .. '] Lets make Bob to turn 25.')
        print('setting angle for ' .. active_tool_id)
        active.Angle = 25
    elseif itm.MyCombo.CurrentIndex == 2 then
        -- Jack
        print('[' .. itm.MyCombo.CurrentText .. '] Lets make Jack to turn 125.')
        print('setting angle for ' .. active_tool_id)
        active.Angle = 125
    end
  end


  win:Show()
  disp:RunLoop()
  win:Hide()
end


-- comp:Lock()
print('test')
composition:StartUndo("Change Angle")
active = comp.ActiveTool
if active and active:GetAttrs().TOOLS_RegID == 'Transform' then
    active_tool_id = active:GetAttrs().TOOLS_RegID
    print(active_tool_id .. 'is selected')
    showUI()
else
    print('Select Transform tool first')
end
composition:EndUndo(true)
-- comp:Unlock()
