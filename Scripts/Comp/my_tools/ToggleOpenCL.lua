-- OpenCL Control Script for Fusion 9.0.1 2017-11-03
-- Created By Andrew Hazelden <andrew@andrewhazelden.com>

-- Installation:
-- Place this script in the Fusion user preferences "Scripts:/Comp/" folder.

-- Disable OpenCL on the following nodes:
OpenCLNodeList = {
  'ColorCorrector',
  'GamutConvert',
  'MatteControl',
}

-- Show the UI Manager based Window:
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 400,235

win = disp:AddWindow({
  ID = 'OpenCLControlWin',
  TargetID = 'OpenCLControlWin',
  WindowTitle = 'OpenCL Control v1.0',
  Geometry = {100, 100, width, height},
  Spacing = 10,

  ui:VGroup{
    ID = 'root',

    -- Add your GUI elements here:
    ui:TextEdit{
      Weight = 0,

      ID = 'AboutText',
      Alignment = {
        AlignHCenter = true, 
        AlignTop = true,
      },
      HTML = [[This GUI allows you to quickly disable the Fusion 9 OpenCL controls in your Fusion Preferences and per node in the comp.]],
      ReadOnly = true,
    },

    ui:VGroup{
      ui:Button{
        ID = 'ToggleOpenCLButton',
        Text = 'Disable OpenCL in Preferences',
      },

      ui:Button{
        ID = 'DisableOpenCLOnNodesButton',
        Text = 'Toggle OpenCL on Nodes',
      },
    }

  },
})

-- Add your GUI element based event functions here:
itm = win:GetItems()

-- The window was closed
function win.On.OpenCLControlWin.Close(ev)
  disp:ExitLoop()
end

-- 'Disable OpenCL in Preferences' Button Clicked
function win.On.ToggleOpenCLButton.Clicked(ev)
  comp:Print('\n\n-------------------------------------------\n\n')
  comp:Print('[Toggling OpenCL in Comp Preferences]\n\n')

  compList = fu:GetCompList()
  for i = 1, table.getn(compList) do
    -- Set cmp to the pointer of the current composite
    cmp = compList[i]

    -- Print out the active composite name
    comp:Print('\t[' .. cmp:GetAttrs()['COMPS_Name'] .. ']\n')
    comp:Print('\t\tSet OpenCL Preference "Comp.Tweaks.OpenCL.Enable" to OFF\n')

    -- Disable the comp specific OpenCL preference
    cmp:SetPrefs('Comp.Tweaks.OpenCL.Enable', 0)

    -- Add a spacer between each comp
    comp:Print('\n')
  end

  -- Disable the Fusion globals specific OpenCL preferences
  comp:Print('[Disabling OpenCL in Global Preferences]\n\n')
  
  comp:Print('\tSet OpenCL Preference "Comp.Tweaks.OpenCL.Enable" to OFF\n')
  fu:SetPrefs('Comp.Tweaks.OpenCL.Enable', 0)

  comp:Print('\tSet OpenCL Preference "Global.Tweaks.OpenCL.Device" to CPU\n')
  fu:SetPrefs('Global.Tweaks.OpenCL.Device', 'cpu')
  fu:SavePrefs()

  -- Add a spacer
  comp:Print('\n')

  comp:Print('[Done]\n')
end

-- 'Disable OpenCL on Nodes' Button Clicked
function win.On.DisableOpenCLOnNodesButton.Clicked(ev)
  comp:Print('\n\n-------------------------------------------\n\n')
  comp:Print('[Disabling OpenCL in the Open Fusion Comps]\n\n')
  -- Process each of the open Comps
  compList = fu:GetCompList()
  for i = 1, table.getn(compList) do
    -- Set cmp to the pointer of the current composite
    cmp = compList[i]

    -- Print out the active composite name
    comp:Print('\t[' .. cmp:GetAttrs()['COMPS_Name'] .. ']\n')

    -- Scan the active comp file for OpenCL nodes
    for _,id in ipairs(OpenCLNodeList) do
       local node = 0
       for _,t in pairs(cmp:GetToolList(false, id)) do
          t.UseOpenCL[0] = 0
          node = node + 1
       end

      -- List the nodes that wer edited
      comp:Print('\t\tDisabled OpenCL on ' .. node .. ' x ' .. id .. '\n')
    end

    -- Add a spacer between each comp
    comp:Print('\n')
  end
  
  comp:Print('[Done]\n')
end

-- The app:AddConfig() command that will capture the 'Control + W' or 'Control + F4' hotkeys so they will close the window instead of closing the foreground composite.
app:AddConfig('OpenCLControl', {
  Target {
    ID = 'OpenCLControlWin',
  },

  Hotkeys {
    Target = 'OpenCLControlWin',
    Defaults = true,

    CONTROL_W  = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
    CONTROL_F4 = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
  },
})

comp:Print('\n[OpenCL Control] v1.0\n')
comp:Print('[Created By] Andrew Hazelden <andrew@andrewhazelden.com>\n')

win:Show()
disp:RunLoop()
win:Hide()
app:RemoveConfig('OpenCLControl')
collectgarbage()
