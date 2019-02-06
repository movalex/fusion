--[[ 
FusionScript Help Browser - v1.0 2017-09-25 4.05 PM
By Andrew Hazelden with *major* assistance from Peter Loveday

# Overview #

The FusionScript Help Browser allows you to view every single class and member that is present in Fusion. This browser tool is the fastest way for a Fusion based compositing technical director or Fusion plugin developer to find out information about the Fusion session that might not be covered in the existing Fusion reference material.

Besides listing Fusion's build-in class and member details, you can also see results from 3rd party plug-ins and Fuses that are loaded.As you to scroll through the Fusion Class and Member items the available help data will be displayed automatically.

The script works with Fusion 9.0.1 and uses the UI Manager GUI system to display the results.

Note: Not all Fusion classes/Members have online help entries so only the available data can be displayed.

# Installation #

Copy the "FusionScript Help Browser.lua" script into your Fusion user preferences "Scripts/Comp/" folder.

# Usage #

Step 1. In Fusion you can run the script by selecting the "Script > FusionScript Help Browser" menu item.

Step 2. A "FusionScript Help Browser" window will be displayed. This interface is used to scroll through the available Fusion help data..

Step 3. Use the scroll wheel to browse quickly through the top "Class" ComboBox list of items. Once the "Member" area ComboBox is populated you can navigate through that section of the UI as well.

]]

local ui = app.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 800,600

win = disp:AddWindow({
  ID = 'HelpBrowser',
  WindowTitle = 'FusionScript Help Browser',
  Geometry = {100, 100, width, height},

  ui:VGroup
  {
    ID = 'root',
    -- Add your GUI elements here:
    
    -- Description
    ui:TextEdit{
      ID='DescriptionTextEdit', 
      Weight = 2,
      Text = [[The FusionScript Help Browser allows you to view every single class and member that is present in Fusion. This browser tool is the fastest way for a Fusion based compositing technical director or Fusion plugin developer to find out information about the Fusion session that might not be covered in the existing Fusion reference material.

Besides listing Fusion's build-in class and member details, you can also see results from 3rd party plug-ins and Fuses that are loaded. As you to scroll through the Fusion Class and Member items the available help data will be displayed automatically.]],
      ReadOnly = true,
      Font = ui:Font{
        Family = 'Droid Sans Mono',
        -- Family = 'Tahoma',
        StyleName = 'Regular',
        PixelSize = 14,
        MonoSpaced = true,
        StyleStrategy = {ForceIntegerMetrics = true},
      },
    },
  
    -- Fusion Class
    ui:Label{
      ID = 'ClassLabel',
      Weight = 0,
      Text = 'Class:', 
      Alignment = {AlignHCenter = true, AlignTop = true},
    },
    ui:ComboBox{
      ID = 'Class',
      Weight = 0
    },
    ui:TextEdit{
    Weight = 1,
    ID = 'ClassHelp',
    ReadOnly = true,
    Font = ui:Font{
      Family = 'Droid Sans Mono',
      -- Family = 'Tahoma',
      StyleName = 'Regular',
      PixelSize = 12,
      MonoSpaced = true,
      StyleStrategy = {ForceIntegerMetrics = true},
      },
    },

    -- Fusion Member
    ui:Label{
      ID = 'MemberLabel',
      Weight = 0,
      Text = 'Member:',
      Alignment = {AlignHCenter = true, AlignTop = true},
    },
    ui:ComboBox{
      ID = 'Member',
      Weight = 0
    },
    ui:TextEdit{
      Weight = 3,
      ID = 'MemberHelp',
      ReadOnly = true,
      Font = ui:Font{
        Family = 'Droid Sans Mono',
        -- Family = 'Tahoma',
        StyleName = 'Regular',
        PixelSize = 12,
        MonoSpaced = true,
        StyleStrategy = {ForceIntegerMetrics = true},
      },
    },
  },
})

-- Add your GUI element based event functions here:
itm = win:GetItems()

-- The window was closed
function win.On.HelpBrowser.Close(ev)
   disp:ExitLoop()
end

-- The "class" ComboBox value has changed
function win.On.Class.CurrentIndexChanged(ev)
   local clname = itm.Class.CurrentText
   local help = app:GetHelpRaw(clname)
   local parent = (help.Parent and #help.Parent > 0) and help.Parent or 'None'

   table.sort(help.Members)
   itm.Member:Clear()
   itm.Member:AddItems(help.Members)

   local str = ''
   str = str .. 'Class: ' .. clname
   str = str .. '\nParent: ' .. parent

   if help.ShortHelp ~= nil then
      str = str .. '\n' .. help.ShortHelp
   end

   if help.LongHelp ~= nil then
      str = str .. '\n' .. help.LongHelp
   end

   itm.ClassHelp.Text = str
end


-- The "Member" ComboBox value has changed
function win.On.Member.CurrentIndexChanged(ev)
  local clname = itm.Class.CurrentText
  local memname = itm.Member.CurrentText
  local help = app:GetHelpRaw(clname, memname)

  local str = ''
  if help ~= nil then
    if help.ShortHelp ~= nil then
      str = str .. '\n' .. help.ShortHelp
    end

    if help.LongHelp ~= nil then
      str = str .. '\n' .. help.LongHelp
    end
  end
  itm.MemberHelp.Text = str
end

local classes = app:GetHelpRaw()

table.sort(classes)
itm.Class:AddItems(classes)

-- Update the window title caption with the filename
itm.HelpBrowser.WindowTitle = 'FusionScript Help Browser: ' .. table.getn(classes) .. ' Classes Found'

win:Show()
disp:RunLoop()
win:Hide()
