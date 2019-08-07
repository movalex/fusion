--[[
-- Check trial period
d = 14
m = 10
y = 2019
reference = os.time{day=d, year=y, month=m}
daysfrom = os.difftime(os.time(), reference) / (24 * 60 * 60) -- seconds in a day
wholedays = math.floor(daysfrom)


if wholedays < 0 then -- Check trial period
  print('Trial days left: '..wholedays)
]]






local ui = fu.UIManager---
local disp = bmd.UIDispatcher(ui)

-- Track the Fusion selection changed events
notify = ui:AddNotify('Comp_Activate_Tool', comp)
notify2 = ui:AddNotify('Time_Set', comp) -- This is referenced in the FusionCompEvents.fu file in prefs config: folder
  -- Use UI action listener for the commands interact with UI





-- Create an "About Window" dialog
function AboutWindow()
  local URL = 'https://www.steakunderwater.com/Fusion/Fusion_KeyboardShortcuts.html'
    


  local platform = ''
    if string.find(comp:MapPath('Fusion:\\'), 'Program Files', 1) then
      -- Check if the OS is Windows by searching for the Program Files folder
      platform = 'Windows'
    elseif string.find(comp:MapPath('Fusion:\\'), 'PROGRA~1', 1) then
      -- Check if the OS is Windows by searching for the Program Files folder
      platform = 'Windows'
    elseif string.find(comp:MapPath('Fusion:\\'), 'Applications', 1) then
      -- Check if the OS is Mac by searching for the Applications folder
      platform = 'Mac'
    else
      platform = 'Linux'
  end

 
  -- Open a web browser window up with the help documentation
  function openBrowser()
  command = ''
  webpage = 'https://www.steakunderwater.com/Fusion/Fusion_KeyboardShortcuts.html'
  
  if platform == 'Windows' then
    -- Running on Windows
    command = 'explorer "' .. webpage .. '"'
  elseif platform == 'Mac' then
    -- Running on Mac
    command = 'open "' .. webpage .. '" &' 
  elseif platform == 'Linux' then
    -- Running on Linux
    command = 'xdg-open "' .. webpage .. '" &'
  end
  
  -- print('[Launch Command] ', command)
  os.execute(command)
end
  -- Add your GUI element based event functions here:
  itm = win:GetItems()

  -- The window was closed
  function win.On.AboutWin.Close(ev)
    disp:ExitLoop()
  end

  win:Show()
  disp:RunLoop()
  win:Hide()

  return win,win:GetItems()
end



--[[▄         ▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░▌       ▐░▌▐░░░░░░░░░░░▌
▐░▌       ▐░▌ ▀▀▀▀█░█▀▀▀▀ 
▐░▌       ▐░▌     ▐░▌     
▐░▌       ▐░▌     ▐░▌     
▐░▌       ▐░▌     ▐░▌     
▐░▌       ▐░▌     ▐░▌     
▐░▌       ▐░▌     ▐░▌     
▐░█▄▄▄▄▄▄▄█░▌ ▄▄▄▄█░█▄▄▄▄ 
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀ ]]
                          
-- All functions in resolve and fusion
--https://www.steakunderwater.com/wesuckless/viewtopic.php?f=35&t=2012&sid=784b17e3c2f6508d54b9f0b31e2bce00#p15952

--Resolve timeline functions
-- dump(timeline:GetHelp("Timeline"))

-- Check if Fusion Standalone or the Resolve Fusion page is active
host = fusion:MapPath('Fusion:/')
if string.lower(host):match('resolve') then
    print('[Host] Resolve')
else
    print('[Host] Fusion')
end


-- Create a window
function MainWindow()

                    -- Size of window
  local width,height = 367,600
  win = disp:AddWindow({
    ID = "MyWin",
    WindowTitle = 'FUGRAPH',

    

     --ui:Button{ID = 'logo',MaximumSize = {364,300}, IconSize = {200,300}, Flat = true, Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FUGRAPH_Header.png'},},


    --------- screen pos - size of window

    Geometry = {600, 1000, width, height},




    --Spacing = 1,
    Margin = 10,
    
    ui:VGroup{
      ID = 'root',

      ui:Button{ID = 'S1',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FUGRAPH_Header.png'}, Flat = true,IconSize = {350,65},MaximumSize = {350,65},MinimumSize = {350,65}},

      --ui:Button{ID = 'logo', IconSize = {350,170}, Flat = true, Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FUGRAPH_Header.png'},MaximumSize = {350,170},MinimumSize = {350,170}},

      --[[

      --ui:Button{ID = 'logo',MaximumSize = {364,60}, IconSize = {200,60}, Flat = true, Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FUGRAPH_Header.png'},},

      ui:Label{ID = 'curFrame',  
      --Events = { CurrentIndexChanged = true, Activated = true },
      Font = ui:Font{
          --Family = 'Droid Sans Mono',
          StyleName = 'Bold',
          PixelSize = 16,
          --MonoSpaced = true,
          StyleStrategy = {ForceIntegerMetrics = true},
      },
      Text = tostring("<font color='#D89696'><font size='+10'><center>")..tostring(comp:GetAttrs().COMPN_CurrentTime)},
      ui:Label{ID = 'curTime',  Text = tostring("<font color='#D89696'><font size='+2'><center>")..tostring(comp:GetAttrs().COMPN_CurrentTime/comp:GetPrefs("Comp.FrameFormat").Rate)},
      ui:Label{ 
        ID = 'NA', 
        Text = 
          tostring("<font color='#D89696'><center>")..
          --tostring(comp:GetAttrs().COMPS_Name)..' | '..
          tostring(math.abs(wholedays))..' trial days | '..
          tostring(comp:GetPrefs("Comp.FrameFormat").Width)..'x'..
          tostring(comp:GetPrefs("Comp.FrameFormat").Height)..'px'..' | '..
          tostring(comp:GetPrefs("Comp.FrameFormat").Rate)..'fps'..' | '..
          '[' .. tostring(comp:GetAttrs().COMPN_RenderStartTime) .. '-' .. tostring(comp:GetAttrs().COMPN_RenderEndTime) .. ']',
           Alignment = { AlignHCenter = true },
           MaximumSize = {364,20},
           --font color= {CB5757}
      },

]]

      ui:VGroup
      {
        ui:TabBar { Weight = 0.0, ID = "MyTabs" },
        ui:Stack
        {
            Weight = 1.0,
            ID = "MyStack",
            Flat = true,
            
            

            ui:VGroup -- FLOW --------------------------------------
            {
              ui:HGroup 
              {
                ui:Button{ID = 'S1',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C1.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S2',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C2.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S3',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C3.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S4',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C4.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S5',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C5.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },
              ui:HGroup 
              {
                ui:Button{ID = 'S6',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C6.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S7',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C7.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S8',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C8.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'S9',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C9.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'Acolor',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/CAUTO.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },
               ui:HGroup
            {
            ui:Button{ID = 'flexyRig',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FlexyRig.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}, ToolTip = 'help'},
            ui:Button{ID = 'trueIK',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TrueIK.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
            ui:Button{ID = 'IconButton1',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/POP.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'IconButton2',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Wave.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'FUglow',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FUglow.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},

            },
              ui:HGroup 
              {
                --ui:Button{ID = 'Align_H',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Align_H.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                --ui:Button{ID = 'Align_V',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Align_V.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                --ui:Button{ID = 'Flip_H',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Flip_H.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                --ui:Button{ID = 'Flip_V',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Flip_V.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'selectRGB',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/SelectRGB.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'selectText',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/SelectTEXT.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'axisC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/AxisC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},

                ui:Button{ID = 'RSCam',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/RSCam.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'OctCam',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/OctCam.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                
                          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },
              --[[ui:HGroup 
              {
                ui:Button{ID = 'ADIn',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/AD_OUT.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'ADOut',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/AD_IN_3.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'ADTrace',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/AD_Trace.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'APIn',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/AP_IN.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                
                
                          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },
              ]]
             
            

            ui:HGroup 
              {
                ui:Button{ID = 'text1',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Text1.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'text2',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Text2.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'text3',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Text3.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'text4',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Text4.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'text5',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Text5.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                
                          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },

              -------- TBC

              ui:HGroup 
              {
                ui:Button{ID = 'text1B',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/Text1B.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                
                          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },

              ui:HGroup 
              {
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                ui:Button{ID = 'TBC',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/TBC.png'}, Flat = true,IconSize = {65,65},MaximumSize = {65,65},MinimumSize = {65,65}},
                
                          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },


              ui:HGroup 
              {
                --ui:DoubleSpinBox{ID ='Scroll', SingleStep = 0.25,Alignment = { AlignHCenter = true }, Value = 1},
                
                --ui:Button{ID = 'IconButton6',Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/C5.png'}, Flat = true,IconSize = {64,64},MaximumSize = {64,64},MinimumSize = {64,64}},          
                --ui:Button { Text = "Button One", ID = "Button1" },
              },
            },
            --[[
            ui:HGroup -- MOTION ------------------------------------
            {
            --ui:HGap(1),
              ui:Button
              {
                ID = 'IconButton1', 
                Flat = true,
                IconSize = {64*2,64*2},
                BackgroundColor = { R = 35/255 , G = 31/255, B = 32/255},
                Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/ButtonPop.png'},
                

              },

              
              ui:Button
              {
                ID = 'IconButton2', 
                Flat = true,
                IconSize = {64*2,64*2},

                BackgroundColor = { R = 35/255 , G = 31/255, B = 32/255},
                Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/ButtonWaves.png'},
                
              },
              
          

        },
            
           
           ----- CAMERAS 

            ui:HGroup
            {
            --ui:HGap(1),
              ui:Button
              {
                ID = 'IconButton5', 
                Flat = true,
                IconSize = {64*2,64*2},
                --BackgroundColor = { R = 35/255 , G = 31/255, B = 32/255},
                Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/ButtonRSCamera.png'},
                --MinimumSize = {64,64},
                --MaximumSize = {64,64},

              },
            },
            ]]

            ---------------------------------------------- RIGGING 
            
            
            ui:VGroup
            {
          


            
          --[[
            ui:HGroup --- MULTITOOL -----------------------
        {
          ui:Button{ID = 'CL', Text = 'CL OFF',MaximumSize = {60,20},MinimumSize = {60,20},Checkable = true, Flat = true, Events = { Pressed = true, Released = true, Toggled = true}},
          ui:Button{ID = 'MB', Text = 'M/BLUR',MaximumSize = {80,20},MinimumSize = {80,20},Checkable = true, Flat = true, Events = { Pressed = true, Released = true, Toggled = true}},
          
        

        ui:Button{ID = 'WR', Text = 'Word Wrap',MaximumSize = {100,20},MinimumSize = {100,20},Checkable = true, Flat = true,Events = { Pressed = true, Released = true, Toggled = true}},
        ui:Slider{ID = 'TextWrap',Text = 'Word Wrap',MaximumSize = {80,20},MinimumSize = {80,20}},

        }, 





      ui:HGroup
        {
         
          ui:SpinBox{ID ='RGB_R', Value = 255,MaximumSize = {60,20},MinimumSize = {60,20}, Maximum = 255, Alignment = { AlignHCenter = true }},
          ui:SpinBox{ID ='RGB_G', Value = 111, MaximumSize = {60,20},MinimumSize = {60,20},Maximum = 255, Alignment = { AlignHCenter = true }},
          ui:SpinBox{ID ='RGB_B', Value = 105, MaximumSize = {60,20},MinimumSize = {60,20},Maximum = 255, Alignment = { AlignHCenter = true }},
          ui:Button{ID = 'RGBSwatch', Text ='RGB',MaximumSize = {30,20},MinimumSize = {30,20}},
          ui:Button{ID = 'SetBG', Text = 'SET BG',BackgroundColor = { R = 35/255 , G = 31/255, B = 32/255},MaximumSize = {52,20},MinimumSize = {52,20}}, 
          ui:Button{ID = 'SetTile', Text = 'SET TILE',BackgroundColor = { R = 35/255 , G = 31/255, B = 32/255},MaximumSize = {52,20},MinimumSize = {52,20}},
          



          
        },


        ui:VGap(5),
      



        
        Weight = 1,
        


         ui:HGroup
        {
          
          
          
          ui:SpinBox{ID='ValA', Value = 0,MaximumSize = {55,20},MinimumSize = {55,20}, Decimals = 0, SingleStep = 1, Alignment = { AlignHCenter = true }, Minimum = -1000},
          ui:SpinBox{ID='ValB', Value = 0,MaximumSize = {55,20},MinimumSize = {55,20}, Decimals = 1, SingleStep = 1, Alignment = { AlignHCenter = true },Minimum = -1000},
          ui:SpinBox{ID='ValC', Value = 0,MaximumSize = {55,20},MinimumSize = {55,20}, Decimals = 2, SingleStep = 1, Alignment = { AlignHCenter = true },Minimum = -1000},
          ui:SpinBox{ID='ValD', Value = 0,MaximumSize = {55,20},MinimumSize = {55,20}, Decimals = 3, SingleStep = 1, Alignment = { AlignHCenter = true },Minimum = -1000},
          ui:Button{ID = 'SetVal2', Text = "SET",MaximumSize = {48,20},MinimumSize = {48,20},Checkable = true, Flat = true},
          ui:Button{ID = 'KeyB', Text = "KEY",MaximumSize = {48,20},MinimumSize = {48,20}},
         
        },

        

        
        ]]
        

       
         ui:Tree{ID = 'Tree', Events = {ItemDoubleClicked=true, ItemClicked=true},MaximumSize = {338,300},MinimumSize = {344,470}},  
         -- ui:LineEdit{ID='attrib2', Text = '[ SINGLE VALUE ]', PlaceholderText = 'Control Name',Alignment = { AlignHCenter = true }},

          --[[    ui:Button
          {
          
            ID = 'OpenShortcuts', 
            --Flat = true,
            Color = { R = 230/255 , G = 100/255, B = 86/255},
            Text ='Keyboard Shortcuts',
            --MaximumSize = {300,20},
            --BackgroundColor = { R = 35/255 , G = 31/255, B = 32/255}, 
            MaximumSize = {364,20}, 
            
            --Checkable = true,
          },
          ]]
        

        },

        

      },
        --------------------------------

      --ui:VGap(0, 10),
    },

      

      

      ---- B



        
    },
  })


  -- Read the current noe selection
 -- selectedTool = tool or comp.ActiveTool

  -- Track the Fusion selection changed events


  -- Add your GUI element based event functions here:
  itm = win:GetItems()

itm.MyStack.CurrentIndex = 0
 
itm.MyTabs:AddTab("   FUgraph  ") 
--itm.MyTabs:AddTab("   Flow  ")
--itm.MyTabs:AddTab("   Motion  ")
--itm.MyTabs:AddTab("Cam")
--itm.MyTabs:AddTab("Rig")
itm.MyTabs:AddTab("   Multitool  ")




--[[
 ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀  ▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌░▌     ▐░▌▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌          ▐░▌       ▐░▌▐░▌▐░▌    ▐░▌▐░▌               ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌    ▐░▌▐░▌          
▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌▐░▌ ▐░▌   ▐░▌▐░▌               ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌ ▐░▌   ▐░▌▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌               ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀▀▀ ▐░▌       ▐░▌▐░▌   ▐░▌ ▐░▌▐░▌               ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌   ▐░▌ ▐░▌ ▀▀▀▀▀▀▀▀▀█░▌
▐░▌          ▐░▌       ▐░▌▐░▌    ▐░▌▐░▌▐░▌               ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌    ▐░▌▐░▌          ▐░▌
▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄▄▄      ▐░▌      ▄▄▄▄█░█▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌     ▐░▐░▌ ▄▄▄▄▄▄▄▄▄█░▌
▐░▌          ▐░░░░░░░░░░░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌
 ▀            ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀ 
]]                                                                                                                     
--[[
function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

itm.curFrame.Text = tostring("<font color='#CB5757'><font size='+10'><center>")..tostring(comp:GetAttrs().COMPN_CurrentTime)
  itm.curTime.Text = tostring("<font color='#D89696'><font size='+2'><center>")..tostring(round(comp:GetAttrs().COMPN_CurrentTime/comp:GetPrefs("Comp.FrameFormat").Rate,1).." Seconds")

function disp.On.Time_Set(ev) -- See Time_Set above
  itm.curFrame.Text = tostring("<font color='#CB5757'><font size='+10'><center>")..tostring(comp:GetAttrs().COMPN_CurrentTime)
  itm.curTime.Text = tostring("<font color='#D89696'><font size='+2'><center>")..tostring(round(comp:GetAttrs().COMPN_CurrentTime/comp:GetPrefs("Comp.FrameFormat").Rate,1).." Seconds")

  print('time changed')  
end
]]

function win.On.ADTrace.Clicked(ev)
--[[--
----------------------------------------------------------------------------
VectorSnapshot v1 2019-01-27
by Andrew Hazelden
www.andrewhazelden.com
andrew@andrewhazelden.com
----------------------------------------------------------------------------

## Overview ##

The VectorSnapshot script generates an SVG vector traced version of an image. This is handy if you want to convert a raster based rotoscoping mask back into a vector SVG image that you can import into Fusion.


## Install ##

Step 1. Use the WSL Reactor package manager to add the "Scripts/Comp/VectorSnapshot" atom.

## Usage ##

Step 1. Load a node into the Fusion's left image viewer.

Step 2. Select the "Script > Andrew Hazelden > VectorSnapshot" menu item.

Step 3. Open the SVG image that was exported to the "Temp:/Fusion/" PathMap folder.


## POTRACE CLI OPTIONS ##

You can fully customize the potrace CLI commands used to vectorize the output by editing the line of Lua code that starts with:

potraceOptions = '--group --invert'


Usage: potrace [options] [filename...]
General options:
 -h, --help                 - print this help message and exit
 -v, --version              - print version info and exit
 -l, --license              - print license info and exit
File selection:
 <filename>                 - an input file
 -o, --output <filename>    - write all output to this file
 --                         - end of options; 0 or more input filenames follow
Backend selection:
 -b, --backend <name>       - select backend by name
 -b svg, -s, --svg          - SVG backend (scalable vector graphics)
 -b pdf                     - PDF backend (portable document format)
 -b pdfpage                 - fixed page-size PDF backend
 -b eps, -e, --eps          - EPS backend (encapsulated PostScript) (default)
 -b ps, -p, --postscript    - PostScript backend
 -b pgm, -g, --pgm          - PGM backend (portable greymap)
 -b dxf                     - DXF backend (drawing interchange format)
 -b geojson                 - GeoJSON backend
 -b gimppath                - Gimppath backend (GNU Gimp)
 -b xfig                    - XFig backend
Algorithm options:
 -z, --turnpolicy <policy>  - how to resolve ambiguities in path decomposition
 -t, --turdsize <n>         - suppress speckles of up to this size (default 2)
 -a, --alphamax <n>         - corner threshold parameter (default 1)
 -n, --longcurve            - turn off curve optimization
 -O, --opttolerance <n>     - curve optimization tolerance (default 0.2)
 -u, --unit <n>             - quantize output to 1/unit pixels (default 10)
 -d, --debug <n>            - produce debugging output of type n (n=1,2,3)
Scaling and placement options:
 -P, --pagesize <format>    - page size (default is letter)
 -W, --width <dim>          - width of output image
 -H, --height <dim>         - height of output image
 -r, --resolution <n>[x<n>] - resolution (in dpi) (dimension-based backends)
 -x, --scale <n>[x<n>]      - scaling factor (pixel-based backends)
 -S, --stretch <n>          - yresolution/xresolution
 -A, --rotate <angle>       - rotate counterclockwise by angle
 -M, --margin <dim>         - margin
 -L, --leftmargin <dim>     - left margin
 -R, --rightmargin <dim>    - right margin
 -T, --topmargin <dim>      - top margin
 -B, --bottommargin <dim>   - bottom margin
 --tight                    - remove whitespace around the input image
Color options, supported by some backends:
 -C, --color #rrggbb        - set foreground color (default black)
 --fillcolor #rrggbb        - set fill color (default transparent)
 --opaque                   - make white shapes opaque
SVG options:
 --group                    - group related paths together
 --flat                     - whole image as a single path
Postscript/EPS/PDF options:
 -c, --cleartext            - do not compress the output
 -2, --level2               - use postscript level 2 compression (default)
 -3, --level3               - use postscript level 3 compression
 -q, --longcoding           - do not optimize for file size
PGM options:
 -G, --gamma <n>            - gamma value for anti-aliasing (default 2.2)
Frontend options:
 -k, --blacklevel <n>       - black/white cutoff in input file (default 0.5)
 -i, --invert               - invert bitmap
Progress bar options:
 --progress                 - show progress bar
 --tty <mode>               - progress bar rendering: vt100 or dumb

Dimensions can have optional units, e.g. 6.5in, 15cm, 100pt.
Default is inches (or pixels for pgm, dxf, and gimppath backends).
Possible input file formats are: pnm (pbm, pgm, ppm), bmp.
Backends are: svg, pdf, pdfpage, eps, postscript, ps, dxf, geojson, pgm,
gimppath, xfig.

--]]--


-- Find out if we are running Fusion 7, 8, 9, or 15
local fu_major_version = math.floor(tonumber(eyeon._VERSION))

-- Find out the current operating system platform. The platform local variable should be set to either "Windows", "Mac", or "Linux".
local platform = (FuPLATFORM_WINDOWS and 'Windows') or (FuPLATFORM_MAC and 'Mac') or (FuPLATFORM_LINUX and 'Linux')

-- Add the platform specific folder slash character
osSeparator = package.config:sub(1,1)

-- Get the file extension from a filepath
function getExtension(mediaDirName)
  local extension = ''
  if mediaDirName then
    extension = string.match(mediaDirName, '(%..+)$')
  end
  
  return extension or ''
end

-- Get the base filename from a filepath
function getFilename(mediaDirName)
  local path, basename = ''
  if mediaDirName then
    path, basename = string.match(mediaDirName, '^(.+[/\\])(.+)')
  end
  
  return basename or ''
end

-- Get the base filename without the file extension or frame number from a filepath
function getFilenameNoExt(mediaDirName)
  local path, basename,name, extension, barename, sequence = ''
  if mediaDirName then
  path, basename = string.match(mediaDirName, '^(.+[/\\])(.+)')
    if basename then
      name, extension = string.match(basename, '^(.+)(%..+)$')
      if name then
        barename, sequence = string.match(name, '^(.-)(%d+)$')
      end
    end
  end
  
  return barename or ''
end

-- Get the base filename with the frame number left intact
function getBasename(mediaDirName)
  local path, basename,name, extension, barename, sequence = ''
  if mediaDirName then
    path, basename = string.match(mediaDirName, '^(.+[/\\])(.+)')
    if basename then
      name, extension = string.match(basename, '^(.+)(%..+)$')
      if name then
        barename, sequence = string.match(name, '^(.-)(%d+)$')
      end
    end
  end
  
  return name or ''
end

-- Get the file path
function getPath(mediaDirName)
  local path, basename
  if mediaDirName then
    path, basename = string.match(mediaDirName, '^(.+[/\\])(.+)')
  end
  
  return path or ''
end

-- Remove the trailing file extension off a filepath
function trimExtension(mediaDirName)
  local path, basename
  if mediaDirName then
    path, basename = string.match(mediaDirName, '^(.+[/\\])(.+)')
  end
  return path or '' .. basename or ''
end

-- Find out the current directory from a file path
-- Example: print(dirname("/Users/Shared/file.txt"))
function dirname(mediaDirName)
  return mediaDirName:match('(.*' .. osSeparator .. ')')
end

-- Open a folder window up using your desktop file browser
function openDirectory(mediaDirName)
  command = nil
  dir = dirname(mediaDirName)
  
  if platform == 'Windows' then
    -- Running on Windows
    command = 'explorer "' .. dir .. '"'
    
    print('[Launch Command] ', command)
    os.execute(command)
  elseif platform == 'Mac' then
    -- Running on Mac
    command = 'open "' .. dir .. '" &'
    
    print('[Launch Command] ', command)
    os.execute(command)
  elseif platform == 'Linux' then
    -- Running on Linux
    command = 'nautilus "' .. dir .. '" &'
    
    print('[Launch Command] ', command)
    os.execute(command)
  else
    print('[Platform] ', platform)
    print('There is an invalid platform defined in the local platform variable at the top of the code.')
  end
end

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
print('[VectorSnapshot]')

-- Four digit frame padding
padding = '%04d'

-- Lock the comp flow area
comp:Lock()

-- List the selected Node in Fusion 
if not tool then
  tool = comp.ActiveTool
end

local selectedNode = tool
if selectedNode then
  toolAttrs = selectedNode:GetAttrs()
  
  -- Write out a temporary viewer snapshot so the script can send any kind of node to the viewer tool
  viewportSnapshotImageFormat = 'bmp'
  
  -- Get the timeline frame
  currentFrame = comp:GetAttrs().COMPN_CurrentTime
  
  -- Image name with extension.
  imageFilename = 'vector_export_' .. selectedNode.Name .. '.' .. string.format(padding, currentFrame) .. '.' .. viewportSnapshotImageFormat
  
  -- Find out the Fusion temporary directory path
  -- dirName = comp:MapPath('Comp:/SVG/')
  dirName = comp:MapPath('Temp:/Fusion/')
  
  -- Create the temporary directory
  os.execute('mkdir "' .. dirName .. '"')
  
  -- Create the image filepath for the temporary view snapshot
  localFilepath = dirName .. imageFilename
  
  if fu_major_version >= 15 then
    -- Resolve 15 workflow for saving an image
    comp:GetPreviewList().LeftView.View.CurrentViewer:SaveFile(localFilepath)
  elseif fu_major_version >= 8 then
    -- Fusion 8 workflow for saving an image
    comp:GetPreviewList().Left.View.CurrentViewer:SaveFile(localFilepath)
  else
    -- Fusion 7 workflow for saving an image
    -- Save the image in the Viewer A buffer
    comp.CurrentFrame.LeftView.CurrentViewer:SaveFile(localFilepath)
  end
  
  -- Everything worked fine and an image was saved
  print('[Saved Image] ', localFilepath ,' [Selected Node] ', selectedNode.Name)
  
  -- This is the image on disk
  imageFilename = localFilepath

  -- Output filename
  vectorFilename = getPath(imageFilename) .. getBasename(imageFilename) .. '.svg'


  

  


  -- Verify the file exists
  if eyeon.fileexists(imageFilename) then
    -- potrace CLI Executable path
    potracePath = ''
    potraceOptions = ''
    if platform == 'Windows' then
      potracePath = 'start "" "' ..  app:MapPath('Reactor:/Deploy/Bin/potrace/bin/potrace.exe') .. '" '

    else
      potracePath = '"' .. app:MapPath('Reactor:/Deploy/Bin/potrace/bin/potrace') .. '" '
    end
    
    -- Group the output and invert the black and white regions
    potraceOptions = '--group --invert'
    
    potraceCommand = potracePath .. ' --debug 3 --tty dumb ' .. potraceOptions .. ' -b svg "' .. imageFilename .. '" --output "' .. vectorFilename .. '"'
    
    print('[Launch Command] ' .. potraceCommand)
    os.execute(potraceCommand)

  else
    print('[Viewport Exported File Missing] ', imageFilename)
  end
  
  --[[
  -- Open the output folder
  if fu_major_version >= 8 then
    -- The script is running on Fusion 8+ so we will use the fileexists command
    if eyeon.fileexists(dirName) then
      openDirectory(dirName)
    else
      print('[Temporary Directory Missing] ', dirName)
      err = true
    end
  else
    -- The script is running on Fusion 6/7 so we will use the direxists command
    if eyeon.direxists(dirName) then
      openDirectory(dirName)
    else
      print('[Temporary Directory Missing] ', dirName)
      err = true
    end
  end]]
end

-- Unlock the comp flow area


-- Loop until svg is created then load into Designer
local i = 1
while i == 1 or a < 5000 do
  print('while')
  if eyeon.fileexists(vectorFilename) then
      path2 = vectorFilename
      print(path)
      bmd.openfileexternal('Open', path2)
      i = 0
  else 
    i = 1 
  end

end


comp:Unlock()


-- OPEN SVG FILE IN DESIGNER

-- Verify the file exists

end


--- ======================= END TRACE ==================================


function win.On.selectRGB.Clicked(ev)
  fusion = Fusion()
  cmp = fusion:GetCurrentComp()
  flow = cmp.CurrentFrame.FlowView
   
  if tool ~= nil then
      -- This script is running as a tool script
      currentclass = tool:GetAttrs().TOOLS_RegID
  elseif cmp.ActiveTool ~= nil then
      -- This script is running as a Comp script
      currentclass = cmp.ActiveTool:GetAttrs().TOOLS_RegID
  else
      cmp:Print("[Error] Please select a node in the flow area\n")
      return
  end
   
  selectionList = ""
  for i, v in ipairs(cmp:GetToolList((Selected == 1))) do
      id = v:GetAttrs().TOOLS_RegID
      if id == currentclass then -- Select if same class of tool
          flow:Select(v, true)
          selectionList = selectionList .. "\t" .. tostring(v.Name) .. "\n"
          -- Deselect again if not same colour
          if comp.ActiveTool.TopLeftRed[comp.CurrentTime] == v.TopLeftRed[comp.CurrentTime] and comp.ActiveTool.TopLeftGreen[comp.CurrentTime] == v.TopLeftGreen[comp.CurrentTime] and comp.ActiveTool.TopLeftBlue[comp.CurrentTime] == v.TopLeftBlue[comp.CurrentTime] then
        print('Found')
        else flow:Select(v, false)

      end
    end
end
 
cmp:Print("\n[" .. tostring(currentclass) .. " Node Selection]\n")
cmp:Print(selectionList)
end

function win.On.selectText.Clicked(ev)
  fusion = Fusion()
  cmp = fusion:GetCurrentComp()
  flow = cmp.CurrentFrame.FlowView
   
  if tool ~= nil then
      -- This script is running as a tool script
      currentclass = tool:GetAttrs().TOOLS_RegID
  elseif cmp.ActiveTool ~= nil then
      -- This script is running as a Comp script
      currentclass = cmp.ActiveTool:GetAttrs().TOOLS_RegID
  else
      cmp:Print("[Error] Please select a node in the flow area\n")
      return
  end
   
  selectionList = ""
  for i, v in ipairs(cmp:GetToolList((Selected == 1))) do
      id = v:GetAttrs().TOOLS_RegID
      if id == currentclass then -- Select if same class of tool
          flow:Select(v, true)
          selectionList = selectionList .. "\t" .. tostring(v.Name) .. "\n"
          -- Deselect again if not same colour
          if comp.ActiveTool.Red1[comp.CurrentTime] == v.Red1[comp.CurrentTime] and comp.ActiveTool.Green1[comp.CurrentTime] == v.Green1[comp.CurrentTime] and comp.ActiveTool.Blue1[comp.CurrentTime] == v.Blue1[comp.CurrentTime] then
        print('Found')
        else flow:Select(v, false)

      end
    end
end
 
cmp:Print("\n[" .. tostring(currentclass) .. " Node Selection]\n")
cmp:Print(selectionList)
end


function win.On.ADIn.Clicked(ev)
  path = comp:MapPath('Scripts:/Comp/Fugraph/AD/AD_temp.afdesign')
  print(path)
  bmd.openfileexternal('Open', path)
end

function win.On.ADOut.Clicked(ev)
  fu:ToggleUtility('SVGImport')
end

function win.On.APIn.Clicked(ev)

  loaderPath = comp.ActiveTool.Clip[comp.CurrentTime] 

  path = comp:MapPath(loaderPath)
  print(path)
  bmd.openfileexternal('Open', path)
end

---- SCROLL ZOOM MOUSE

function win.On.Scroll.ValueChanged(ev)
  --comp.CurrentFrame.FlowView:FrameAll()
  comp.CurrentFrame.FlowView:SetScale(itm.Scroll.Value)
  comp.CurrentFrame.L_view.View.SetScale(itm.Scroll.Value)
  
  --comp.CurrentFrame.ImageView:SetScale(itm.Scroll.Value)

end


function win.On.MyTabs.CurrentChanged(ev)
    itm.MyStack.CurrentIndex = ev.Index
end

function win.On.ButtonA.Clicked(ev)
    itm.MyTabs.TabText[0] = "A"
end
 
function win.On.ButtonB.Clicked(ev)
    itm.MyTabs.TabText[1] = "B"
end
 
function win.On.ButtonC.Clicked(ev)
    itm.MyTabs.TabText[2] = "C"
end



--- ARRANGING THE FLOW ----------------------

function win.On.Flip_V.Clicked(ev)
    local tools = comp:GetToolList(true)
    local offsetX, offsetY = comp.CurrentFrame.FlowView:GetPos(tools[1])
    for i, tool in ipairs(tools) do
        local x, y = comp.CurrentFrame.FlowView:GetPos(tool)
        y = (y - offsetY) * -1 + offsetY
        comp.CurrentFrame.FlowView:SetPos(tool, x, y)
    end
end

function win.On.Flip_H.Clicked(ev)
    local tools = comp:GetToolList(true)
    local offsetX, offsetY = comp.CurrentFrame.FlowView:GetPos(tools[1])
    for i, tool in ipairs(tools) do
        local x, y = comp.CurrentFrame.FlowView:GetPos(tool)
        x = (x - offsetX) * -1 + offsetX
        comp.CurrentFrame.FlowView:SetPos(tool, x, y)
    end
end

--[[
  function win.On.Align_H.Clicked(ev)
    local tools = comp:GetToolList(true)
    local offsetX, offsetY = comp.CurrentFrame.FlowView:GetPos(tools[1]) -- first
        for i, tool in ipairs(tools) do
          local x, y = comp.CurrentFrame.FlowView:GetPos(tool) -- current
          local touchX, touchY = comp.CurrentFrame.FlowView:GetPos(tools[i-1])
          
        
          for a=1,20 do
            if x < offsetX and math.abs(touchX - x) > 2 then
              x = math.abs(offsetX-x)*0.05+x
              print('Left')
            end
            if x > offsetX and math.abs(touchX - x) > 2 then
              x = x - math.abs(offsetX-x)*0.05
              print('Right')
            end

            if i > 1 then
              comp.CurrentFrame.FlowView:SetPos(tool, x, offsetY) 
            end
          end
            
        end
    
  end
  ]]

    function win.On.Align_H.Clicked(ev)
    local tools = comp:GetToolList(true)
    local offsetX, offsetY = comp.CurrentFrame.FlowView:GetPos(tools[1]) -- first
        for i, tool in ipairs(tools) do
          local x, y = comp.CurrentFrame.FlowView:GetPos(tool) -- current
          local touchX, touchY = comp.CurrentFrame.FlowView:GetPos(tools[i-1])
          
        
          
            if x < offsetX and math.abs(touchX - x) > 2 then
              x = math.abs(offsetX-x)*0.05+x
              print('Left')
            end
            if x > offsetX and math.abs(touchX - x) > 2 then
              x = x - math.abs(offsetX-x)*0.05
              print('Right')
            end

            if i > 1 then
              comp.CurrentFrame.FlowView:SetPos(tool, x, offsetY) 
            end
          
            
        end
    
  end


  function win.On.Align_V.Clicked(ev)
    local tools = comp:GetToolList(true)
    local offsetX, offsetY = comp.CurrentFrame.FlowView:GetPos(tools[1]) -- first
        for i, tool in ipairs(tools) do
          local x, y = comp.CurrentFrame.FlowView:GetPos(tool) -- current
          local touchX, touchY = comp.CurrentFrame.FlowView:GetPos(tools[i-1])
          
          for a=1,20 do
            if y < offsetY and math.abs(touchY - y) > 1 then
              y = math.abs(offsetY-y)*0.05+y
              print('Up')
            end
            if y > offsetY and math.abs(touchY - y) > 1 then
              y = y - math.abs(offsetY-y)*0.05
              print('Down')
            end

            if i > 1 then
              
              comp.CurrentFrame.FlowView:SetPos(tool, offsetX, y) 
            end
          end      
            
        end
        


    
  end

--[[
  function win.On.Align_V.Clicked(ev)
    local tools = comp:GetToolList(true)
    local offsetX, offsetY = comp.CurrentFrame.FlowView:GetPos(tools[1])
        for i, tool in ipairs(tools) do
          if i > 1 then
            comp.CurrentFrame.FlowView:SetPos(tool, offsetX, offsetY+i-1) 
          end
            
        end
    
  end
  ]]

 

  --- UPDATE LOADER

  function win.On.UpdateLoaders.Toggled(ev)
    if itm.UpdateLoaders.Checked == true then
      for _,tool in ipairs(composition:GetToolList(true)) do 
        --tool.PassThrough[CurrentTime] = false
        tool.PassThrough[CurrentTime] = true
      end
    elseif itm.UpdateLoaders.Checked == false then
      for _,tool in ipairs(composition:GetToolList(true)) do 
        --tool.PassThrough[CurrentTime] = false
        tool.PassThrough[CurrentTime] = false 
      end
    end
  end

    --- TOGGLE OPEN CL

  function win.On.CL.Toggled(ev)
    if itm.CL.Checked == true then
      for _,tool in ipairs(composition:GetToolList(true)) do 
        --tool.PassThrough[CurrentTime] = false
        tool.UseOpenCL[0] = 0 
      end
    elseif itm.CL.Checked == false then
      for _,tool in ipairs(composition:GetToolList(true)) do 
        --tool.PassThrough[CurrentTime] = false
        tool.UseOpenCL[0] = 1 
      end
    end
  end

    --- TOGGLE OPEN MOTION BLUR

  function win.On.MB.Toggled(ev)
    if itm.MB.Checked == true then
      for _,tool in ipairs(composition:GetToolList(true)) do 
        --tool.PassThrough[CurrentTime] = false
        tool.MotionBlur = 1 
      end
    elseif itm.MB.Checked == false then
      for _,tool in ipairs(composition:GetToolList(true)) do 
        --tool.PassThrough[CurrentTime] = false
        tool.MotionBlur = 0 
      end
    end
  end

  
  
  --------------------------------- SLIDER FOR THE SWATCH COLOR

  function win.On.MySlider.ValueChanged(ev)
      if itm.MySlider.Value < 25 then
        itm.RGBSwatch.BackgroundColor = 
        {
          R = ev.Value/100, 
          G = ev.Value/100, 
          B = ev.Value/100,
        }
      elseif itm.MySlider.Value > 25 then
        itm.swatch.BackgroundColor = 
        {
          R = 1, 
          G = 0, 
          B = 0,
        }
      end
    
    print(ev.Value)
  end
 


  -- The window was closed
  function win.On.MainWin.Close(ev)
    disp:ExitLoop()
  end
  
  -- The "Show the About Dialog" button was clicked
  function win.On.Help.Clicked(ev)
    -- Close the current main window
    --win:Hide()
    
    -- Display an "About dialog" window
    AboutWindow()
  end

  

    --- SET BACKGROUND SIZE
  function win.On.update.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.Width = tonumber(itm.BgSizeW.Text);   tool.Height = tonumber(itm.BgSizeH.Text);  
    end
  end



   --- COLOR FROM SWATCH
  function win.On.swatch.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
     
      tool.TileColor = { R = red, G = green , B = blue };
      print(tool.TileColor);
      print(tool.TopLeftRed);
    end

  end

  --- RGB REF RED UPDATE
  function win.On.RGB_R.ValueChanged(ev)
    itm.RGBSwatch.BackgroundColor = 
    {
      R = ev.Value/255,
      G = itm.RGB_G.Value/255,
      B = itm.RGB_B.Value/255,
    }
    
  end

   --- RGB REF GREEN UPDATE
  function win.On.RGB_G.ValueChanged(ev)
    itm.RGBSwatch.BackgroundColor = 
    {
      R = itm.RGB_R.Value/255,
      G = ev.Value/255,
      B = itm.RGB_B.Value/255,
    }
    
  end

   --- RGB REF BLUE UPDATE
  function win.On.RGB_B.ValueChanged(ev)
    itm.RGBSwatch.BackgroundColor = 
    {
      R = itm.RGB_R.Value/255,
      G = itm.RGB_G.Value/255,
      B = ev.Value/255,
    }
   
  end

  

   --- SET COLOR FOR BACKGROUNDS
  function win.On.SetBG.Clicked(ev)              -- Finds just the Background tools
    for _,tool in ipairs(composition:GetToolList(true,"Background")) do 
      
      
      tool.TopLeftRed =  itm.RGB_R.Value/255
      tool.TopLeftGreen = itm.RGB_G.Value/255
      tool.TopLeftBlue = itm.RGB_B.Value/255
      
    end

  end


   --- AUTO COLOR FROM BACKGROUNDS
  function win.On.Acolor.Clicked(ev)              -- Finds just the Background tools
    for _,tool in ipairs(composition:GetToolList(true,"Background")) do 
      
      
      tool.TextColor = { 

        R = math.floor(1-tool.TopLeftRed[comp.CurrentTime]+0.5), 
        G = math.floor(1-tool.TopLeftRed[comp.CurrentTime]+0.5),
        B = math.floor(1-tool.TopLeftRed[comp.CurrentTime]+0.5) 
        };

      tool.TileColor = { R = tool.TopLeftRed[comp.CurrentTime], G = tool.TopLeftGreen[comp.CurrentTime] , B = tool.TopLeftBlue[comp.CurrentTime] };
      print(tool.TextColor)
      
    end

  end

  print(TopLeftBlue)

  --- SET NODE COLOUR RGB
  function win.On.SetTile.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      
      tool.TileColor = { R = itm.RGB_R.Value/255, G = itm.RGB_G.Value/255, B = itm.RGB_B.Value/255};  
    end
  end

  --- SET NODE COLOUR SWATCH 01
  function win.On.S1.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 113/255 , G = 171/255, B = 221/255}; 
      print("test01")
    end
  end

  --- SET NODE COLOUR SWATCH 02
  function win.On.S2.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 107/255 , G = 202/255, B = 222/255}
      print("test02")
    end
  end

  --- SET NODE COLOUR SWATCH 03
  function win.On.S3.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor =  { R = 130/255 , G = 204/255, B = 181/255}
    end
  end

  --- SET NODE COLOUR SWATCH 04
  function win.On.S4.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 182/255 , G = 216/255, B = 132/255}
    end
  end

   --- SET NODE COLOUR SWATCH 05
  function win.On.S5.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 255/255 , G = 246/255, B = 143/255}
    end
  end

    --- SET NODE COLOUR SWATCH 06
  function win.On.S6.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 253/255 , G = 205/255, B = 121/255}
    end
  end

     --- SET NODE COLOUR SWATCH 07
  function win.On.S7.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 249/255 , G = 180/255, B = 138/255}
    end
  end

     --- SET NODE COLOUR SWATCH 08
  function win.On.S8.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 221/255 , G = 134/255, B = 185/255}
    end
  end

     --- SET NODE COLOUR SWATCH 09
  function win.On.S9.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TextColor = { R = 0 , G = 0, B = 0};
      tool.TileColor = { R = 153/255 , G = 119/255, B = 180/255}
    end
  end








  --- SET BACKGROUND COLOUR
  function win.On.BGcolor.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      tool.TopLeftRed = itm.Color.Color.R;
      tool.TopLeftGreen = itm.Color.Color.G; 
      tool.TopLeftBlue = itm.Color.Color.B;  
      print(itm.TopLeftRed)
    end
  end
  


------ SET VALUES SINGLE A

function win.On.ValA.ValueChanged(ev)
  if itm.SetVal2.Checked == true then
    for _,tool in ipairs(composition:GetToolList(true)) do 
      

        tool[itm.attrib2.Text][comp.CurrentTime] = itm.ValA.Value + itm.ValB.Value/10 + itm.ValC.Value/100 + itm.ValD.Value/1000
      
    end
  end
end

------ SET VALUES SINGLE B

function win.On.ValB.ValueChanged(ev)
  if itm.SetVal2.Checked == true then
    for _,tool in ipairs(composition:GetToolList(true)) do 
      

        tool[itm.attrib2.Text][comp.CurrentTime] = itm.ValA.Value + itm.ValB.Value/10 + itm.ValC.Value/100 + itm.ValD.Value/1000

      
    end
  end
end

------ SET VALUES SINGLE C

function win.On.ValC.ValueChanged(ev)
  if itm.SetVal2.Checked == true then
    for _,tool in ipairs(composition:GetToolList(true)) do 
      

        tool[itm.attrib2.Text][comp.CurrentTime] = itm.ValA.Value + itm.ValB.Value/10 + itm.ValC.Value/100 + itm.ValD.Value/1000

      
    end
  end
end

------ SET VALUES SINGLE D

function win.On.ValD.ValueChanged(ev)
  if itm.SetVal2.Checked == true then
    for _,tool in ipairs(composition:GetToolList(true)) do 
      

        tool[itm.attrib2.Text][comp.CurrentTime] = itm.ValA.Value + itm.ValB.Value/10 + itm.ValC.Value/100 + itm.ValD.Value/1000

      
    end
  end
end

------ SET VALUES on X FIRST

function win.On.ValX.ValueChanged(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      


        V = {itm.ValX.Value,itm.ValY.Value}

        tool[itm.attrib.Text][comp.CurrentTime] = V


      
    end
end



------ SET VALUES on Y SECOND

function win.On.ValY.ValueChanged(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      

      

        V = {itm.ValX.Value,itm.ValY.Value}

        tool[itm.attrib.Text][comp.CurrentTime] = V

      
    end
end

function win.On.Key.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      

        tool[itm.attrib.Text] = XYPath();
        XYPath1.X = BezierSpline();
        XYPath1.Y = BezierSpline()

      
    end
end

function win.On.KeyB.Clicked(ev)
    for _,tool in ipairs(composition:GetToolList(true)) do 
      
        S = comp.BezierSpline()    
        tool[itm.attrib2.Text] = S

      
    end
end



  
  
-------------------------------------------------------------------------------------------------
function win.On.Pos.Clicked(ev)
  if itm.MyCombo.CurrentIndex == 0 then
      
    for _,tool in ipairs(composition:GetToolList(true)) do 

      tool.Center = BezierSpline()
      tool.Center[CurrentTime] = 0 -- Add keyframe at frame 1
      tool.Center[CurrentTime+itm.PosOff.Value] = 1 -- Add keyframe at frame 50
      --print(Composition.CurrentFrame – (10))
      print(time)
    end
  
    -- Center
    
  		
    
    

    print('[' .. itm.MyCombo.CurrentText .. '] ')
  elseif itm.MyCombo.CurrentIndex == 1 then

    print('[' .. itm.MyCombo.CurrentText .. '] ')
  elseif itm.MyCombo.CurrentIndex == 2 then

    print('[' .. itm.MyCombo.CurrentText .. '] ')
  elseif itm.MyCombo.CurrentIndex == 3 then

    print('[' .. itm.MyCombo.CurrentText .. '] ')
  elseif itm.MyCombo.CurrentIndex == 4 then

    print('[' .. itm.MyCombo.CurrentText .. '] ')
  elseif itm.MyCombo.CurrentIndex == 5 then

    print('[' .. itm.MyCombo.CurrentText .. '] ')
  end
end
  

-------------- INSERT NODES



  





function win.On.IconButton1.Clicked(ev)
    local defaultNodeText = SampleNodeBlock1()
    comp:Paste(bmd.readstring(defaultNodeText))
end

function win.On.IconButton2.Clicked(ev)
    local defaultNodeText = SampleNodeBlock2()
    comp:Paste(bmd.readstring(defaultNodeText))
end

function win.On.flexyRig.Clicked(ev)
    local defaultNodeText = SampleNodeBlock3()
    comp:Paste(bmd.readstring(defaultNodeText))
    print('flexrig')
end

function win.On.trueIK.Clicked(ev)
    local defaultNodeText = SampleNodeBlock4()
    comp:Paste(bmd.readstring(defaultNodeText))
    print('trueik')
end


function win.On.RSCam.Clicked(ev)
    local defaultNodeText = SampleNodeBlock7()
    comp:Paste(bmd.readstring(defaultNodeText))
    print('trueik')
end

function win.On.FUglow.Clicked(ev)
    local defaultNodeText = SampleNodeBlock6()
    comp:Paste(bmd.readstring(defaultNodeText))
    --print('trueik')
end









function win.On.OpenShortcuts.Clicked(ev)
  openBrowser1()
 
end

function win.On.logo.Clicked(ev)
  openBrowser2()
 
end

--[[
local platform = ''
if string.find(comp:MapPath('Fusion:\\'), 'Program Files', 1) then
  -- Check if the OS is Windows by searching for the Program Files folder
  platform = 'Windows'
elseif string.find(comp:MapPath('Fusion:\\'), 'PROGRA~1', 1) then
  -- Check if the OS is Windows by searching for the Program Files folder
  platform = 'Windows'
elseif string.find(comp:MapPath('Fusion:\\'), 'Applications', 1) then
  -- Check if the OS is Mac by searching for the Applications folder
  platform = 'Mac'
else
  platform = 'Linux'
end
]]
-- Open a web browser window up with the help documentation
function openBrowser1()
  command = ''
  webpage = 'https://www.steakunderwater.com/Fusion/Fusion_KeyboardShortcuts.html'
  
  if platform == 'Windows' then
    -- Running on Windows
    command = 'explorer "' .. webpage .. '"'
  elseif platform == 'Mac' then
    -- Running on Mac
    command = 'open "' .. webpage .. '" &' 
  elseif platform == 'Linux' then
    -- Running on Linux
    command = 'xdg-open "' .. webpage .. '" &'
  end
  
  -- print('[Launch Command] ', command)
  os.execute(command)
end

function openBrowser2()
  command = ''
  webpage = 'https://vimeo.com/307993744/1a209cf94b'
  
  if platform == 'Windows' then
    -- Running on Windows
    command = 'explorer "' .. webpage .. '"'
  elseif platform == 'Mac' then
    -- Running on Mac
    command = 'open "' .. webpage .. '" &' 
  elseif platform == 'Linux' then
    -- Running on Linux
    command = 'xdg-open "' .. webpage .. '" &'
  end
  
  -- print('[Launch Command] ', command)
  os.execute(command)
end


itm = win:GetItems()

-- Handle Window Events

---------- WRAPPER TEXT+



function win.On.CL.Toggled(ev)
    if itm.CL.Checked == true then
      for _,tool in ipairs(composition:GetToolList(true)) do 
  
        tool.UseOpenCL[0] = 0 
      end
    elseif itm.CL.Checked == false then
      for _,tool in ipairs(composition:GetToolList(true)) do 
       
        tool.UseOpenCL[0] = 1 
      end
    end
  end

TextWrap = 100
function win.On.text2.Clicked(ev)
  TextWrap = TextWrap - 10
  TextWrapUpdate(TextWrap)
  print(TextWrap)
end

function win.On.text3.Clicked(ev)
  TextWrap = TextWrap + 10
  TextWrapUpdate(TextWrap)
  print(TextWrap)
end

function win.On.text4.Clicked(ev)
  TextWrap = TextWrap - 1
  TextWrapUpdate(TextWrap)
  print(TextWrap)
end

function win.On.text5.Clicked(ev)
  TextWrap = TextWrap + 1
  TextWrapUpdate(TextWrap)
  print(TextWrap)
end

function win.On.text1.Clicked(ev) -- to upper case text
  for _,tool in ipairs(composition:GetToolList(true)) do
    
      local txt = tool.StyledText[comp.CurrentTime]
      print(txt)
      txt = string.upper(txt)
      tool.StyledText = txt
      Print(txt)
    
    
  end
end

function win.On.text1B.Clicked(ev) -- to upper case text
  for _,tool in ipairs(composition:GetToolList(true)) do
    
      local txt = tool.StyledText[comp.CurrentTime]
      print(txt)
      txt = string.lower(txt)
      tool.StyledText = txt
      Print(txt)
    
    
  end
end

function TextWrapUpdate(ev)
  print('changed')
  --if itm.WR.Checked == true then
    for _,tool in ipairs(composition:GetToolList(true)) do
      --itm.TextWrap.Minimum = 0
      --itm.TextWrap.Maximum = 300
      function splittokens(s)
          local res = {}
          for w in s:gmatch("%S+") do
              res[#res+1] = w
          end
          return res
      end
       
      function textwrap(text, linewidth)
          if not linewidth then
              linewidth = ev
          end
       
          local spaceleft = linewidth
          local res = {}
          local line = {}
       
          for _, word in ipairs(splittokens(text)) do
              if #word + 1 > spaceleft then
                  table.insert(res, table.concat(line, ' '))
                  line = {word}
                  spaceleft = linewidth - #word
              else
                  table.insert(line, word)
                  spaceleft = spaceleft - (#word + 1)
              end
          end
       
          table.insert(res, table.concat(line, ' '))      
          return table.concat(res, '\n')
      end
       
      local example1 = tool.StyledText[comp.CurrentTime]--[[
      example
      ]]
       
      print(textwrap(example1))
      print()
      print(textwrap(example1, 60))
      tool.StyledText = textwrap(example1)

    end


  --end
end







------  TREE INPUT LIST



-- Read the current noe selection
--selectedTool = tool or comp.ActiveTool



-- Add your GUI element based event functions here:
itm = win:GetItems()

-- Handle the notification
function disp.On.Comp_Activate_Tool(ev)
  -- dump(ev.Args)

  prevTool = ev.Args.prev
  selectedTool = ev.Args.tool
  print('[Active tool] ', selectedTool, ' [Previous Tool] ', prevTool)
  UpdateTree()


end

-- The window was closed
function win.On.MyWin.Close(ev)
    disp:ExitLoop()
end

-- Copy the expression name to the clipboard when a Tree view row is clicked on
function win.On.Tree.ItemDoubleClicked(ev)
  if selectedTool ~= nil then
    x = selectedTool:GetInputList()
    nodeName = selectedTool:GetAttrs().TOOLS_Name

   -- itRow.Text[1] = 'UPDATED'
    -- Copy the "Node.InputName" value to the clipboard
    inputName = ev.item.Text[0]
    --itm.attrib2.Text = inputName..' SYNCED'

    for _,tool in ipairs(composition:GetToolList(true)) do 

      tool[inputName][comp.CurrentTime] = comp.ActiveTool[inputName][comp.CurrentTime]
    end



  end
end


-- Update the contents of the tree view
function UpdateTree()
  -- Clean out the previous entries in the Tree view
  itm.Tree:Clear()
  
  -- Add a header row
  hdr = itm.Tree:NewItem()
  hdr.Text[0] = selectedTool:GetAttrs().TOOLS_Name
  hdr.Text[1] = '   INPUT TYPE'

  itm.Tree:SetHeaderItem(hdr)

  -- Number of columns in the Tree list
  itm.Tree.ColumnCount = 2

  -- Resize the Columns
  itm.Tree.ColumnWidth[0] = 230
  itm.Tree.ColumnWidth[1] = 90 -- Updated

   
  

  -- Make sure a node is selected
  if selectedTool ~= nil then
    x = selectedTool:GetInputList()
    nodeName = selectedTool:GetAttrs().TOOLS_Name
    
    -- Update the window title to track the current node name
    --itm.MyWin.WindowTitle = 'Input Controls: ' .. nodeName
    --print('Input Controls: ' .. nodeName)

    -- Add an new row entries to the list
    for i, inp in pairs(x) do
      itRow = itm.Tree:NewItem(); 
      
      itRow.Text[0] = inp:GetAttrs().INPS_ID

      
      itRow.Text[1] = inp:GetAttrs().INPS_DataType

      if i % 2 == 0 then
        itRow.BackgroundColor[0] = {R = 203/255, G = 87/255, B = 87/255, A = 0.8}
      else
        itRow.BackgroundColor[0] = {R = 203/255, G = 87/255, B = 87/255, A = 1}
      end

      
      

      if itRow.Text[0] == 'TopLeftRed' then
         itRow.BackgroundColor[0] = {R = 203/255, G = 87/255, B = 87/255, A = 0.4}
         itRow.TextColor[0] =  {R = 1, G = 0.5, B = 0.5, A = 1}-- flood background color
      elseif itRow.Text[0] == 'TopLeftGreen' then
         itRow.BackgroundColor[0] = {R = 203/255, G = 87/255, B = 87/255, A = 0.4}
         itRow.TextColor[0] =  {R = 0.3, G = 1, B = 0.3, A = 1}-- flood background color
      elseif itRow.Text[0] == 'TopLeftBlue' then
        itRow.BackgroundColor[0] = {R = 203/255, G = 87/255, B = 87/255, A = 0.4}
         itRow.TextColor[0] =  {R = 0.5, G = 0.5, B = 1, A = 1}-- flood background color
      elseif itRow.Text[0] == 'Width' or itRow.Text[0] == 'Height' or itRow.Text[0] == 'Motion Blur' or itRow.Text[0] == 'Motion Blur' then

         --itRow.BackgroundColor[0] =   {R = 0.1, G = 0.1, B = 0.1, A = 1}
         --itRow.Text[0].Alignment = { AlignHCenter = true }
         --itRow.Text[0] = '        '..itRow.Text[0]
         itRow.TextColor[0] =  {R = 255/255, G = 255/255, B = 255/255, A = 1}-- flood background color
         itRow.BackgroundColor[0] = {R = 203/255, G = 87/255, B = 87/255, A = 0.4}
         itRow.BackgroundColor[1] = {R = 203/255, G = 87/255, B = 87/255, A = 0.4}

      else
        --itRow.BackgroundColor[0] =   {R = 203/255, G = 87/255, B = 87/255, A = 1}
        itRow.TextColor[0] =  {R = 241/255, G = 220/255, B = 220/255, A = 1}-- flood background color
      end
      
      
      

      itm.Tree:AddTopLevelItem(itRow)
    end
    
    print('[Done]')
  else
    -- Nothing was selected in the flow
    itRow = itm.Tree:NewItem(); 
    itRow.Text[0] = 'Please select a node in the flow area.'
    itm.Tree:AddTopLevelItem(itRow)
    
    print('Please select a node in the flow area.')
  end
end


-- Copy text to the operating system's clipboard
-- Example: CopyToClipboard('Hello World!')
function CopyToClipboard(textString)
  -- The system temporary directory path (Example: $TEMP/Fusion/)
  outputDirectory = comp:MapPath('Temp:\\Fusion\\')
  clipboardTempFile = outputDirectory .. 'ClipboardText.txt'

  -- Create the temp folder if required
  os.execute('mkdir "' .. outputDirectory .. '"')

  -- Open up the file pointer for the output textfile
  outClipFile, err = io.open(clipboardTempFile,'w')
  if err then
    print("[Error Opening Clipboard Temporary File for Writing]")
    return
  end

  outClipFile:write(textString)
  -- outClipFile:write(textString,'\n')

  -- Close the file pointer on the output textfile
  outClipFile:close()
  command = ''
  if platform == 'Windows' then
    -- The Windows copy to clipboard command is "clip"
    command = 'clip < "' .. clipboardTempFile .. '"'
  elseif platform == 'Mac' then
    -- The Mac copy to clipboard command is "pbcopy"
    command = 'pbcopy < "' .. clipboardTempFile .. '"'
  elseif platform == 'Linux' then
    -- The Linux copy to clipboard command is "xclip"
    -- This requires a custom xclip tool install on Linux:
 
    -- Debian/Ubuntu:
    -- sudo apt-get install xclip
 
    -- Redhat/Centos/Fedora:
    -- yum install xclip
    command = 'cat "' .. clipboardTempFile .. '" | xclip -selection clipboard &'
  end

  print('[Copy to Clipboard] ' .. textString)
  -- print('[Command] ' .. command)
  os.execute(command)
end

function win.On.axisC.Clicked(ev)

--[[
KNOWN ISSUES:
  Polylinestrokes must be added manually to paint tool before running this script
  all values currently hardcoded
  currently ALL tools in the comp are evaluated. 
    Make sure that there's only one paint tool and all polymasks should be animated.
    Other polymasks or paints should be set to passthrough
  Order of strokes appearing is completely random 
  Normalize needs more coding to get startpoints right

--]]

-- fixed values
--ct = comp.CurrentTime
--tools = comp:GetToolList()

for _,tool in ipairs(composition:GetToolList(true,"PolylineMask")) do 

-- LOOP OVER SELECTED TOOL TABLE, ONLY INSERT POLYLINEMASKS AND PASSTHROUGH DESELECTED








function getAxis()
  maskTool = comp:CopySettings(tool)
  maskPoly = tool.Polyline:GetConnectedOutput():GetTool()
  polyName = maskPoly:GetAttrs().TOOLS_Name

  minKey = math.huge
  for k in pairs(maskTool.Tools[polyName].KeyFrames) do
    minKey = math.min(k, minKey)
  end

  polyPoints = maskTool.Tools[polyName].KeyFrames[minKey].Value.Points

  --pathLength = 0
  averageX = 0
  averageY = 0
  Xtotal = 0
  Ytotal = 0
  a = 0
  for n, point in pairs(polyPoints) do -- Add all X,Y points together
    a = a + 1
    
    --Print('point found \n')
    --Print(point['X']+tool.Center[CurrentTime][1]..' '..point['Y']+tool.Center[CurrentTime][2]..'\n') -- Make absolute positions
    Xtotal = point['X'] + tool.Center[CurrentTime][1] + Xtotal -- Make absolute positions
    Ytotal = point['Y'] + tool.Center[CurrentTime][2] + Ytotal

  end
  averageX = Xtotal/a -- Gets average
  averageY = Ytotal/a

  distMovedX = averageX - tool.Center[CurrentTime][1]
  distMovedY = averageX - tool.Center[CurrentTime][2]

  mcOld = {tool.Center[CurrentTime][1],tool.Center[CurrentTime][2]} -- OLD MIddle pos
  

  --print('\n AVERAGE'..averageX)
  --print(averageY)

  tool.Center[CurrentTime] = {averageX,averageY}

  mcNew = {tool.Center[CurrentTime][1],tool.Center[CurrentTime][2]} -- New Middle Pos



  
end



getAxis() ---
    --table.insert(masks, {tool, pathLength})









------------------------------------------------------------------


-- fixed values
flow = comp.CurrentFrame.FlowView
ct = comp.CurrentTime
tools = comp:GetToolList(true) -- only selected tools!
masks = {} -- CREATE EMPTY TABLE
oldCons = {} -- CREATE EMPTY TABLE

function modifyPoints(mask)
  maskTool = comp:CopySettings(tool) -- COPYS A LIST OF TOOLS TO A SETTINGS TABLE, BUT IN THIS CASE JUST "mask"
  maskPoly = tool.Polyline:GetConnectedOutput():GetTool()
  polyName = maskPoly:GetAttrs().TOOLS_Name


  minKey = math.huge -- a very large number to comapre to
  for k in pairs(maskTool.Tools[polyName].KeyFrames) do -- iterate over keyframes
    minKey = math.min(k, minKey) -- Returns the lowest number returned to it "k or minKey"
  end
  polyPoints = maskTool.Tools[polyName].KeyFrames[minKey].Value.Points -- Assigns the correct keyframe time value


  --polyPoints = maskTool.Tools[polyName].KeyFrames[0].Value.Points

-- Long form
--                     all tool settings  |                       correct tool by name                          | reading Keyframes table at time 0 . All sub tables . Points Table(example below)
--polypoints = comp:CopySettings(mask).Tools[mask.Polyline:GetConnectedOutput():GetTool():GetAttrs().TOOLS_Name].KeyFrames[0].Value.Points

--[[Points = {
              { Linear = true, X = -0.180412366986275, Y = 0.0203145481646061, LX = 0.110456551114718, LY = -0.019222367554903, RX = 0.0770741272379384, RY = 0.106596767038185 },
              { Linear = true, X = 0.0508100129663944, Y = 0.340104848146439, LX = -0.0770741272379384, LY = -0.106596767038185, RX = 0.0333824257220511, RY = -0.125819134615873 },
              { Linear = true, X = 0.15095728635788, Y = -0.037352554500103, LX = -0.0333824257220511, LY = 0.125819134615873, RX = -0.110456551114718, RY = 0.019222367554903 }
}]]
  for n, point in pairs(polyPoints) do  -- LOOPS OVER A TABLE OF POINTS
                    -- Absolute pos
                  -- original pos + center vector moved
      point['X'] =  point['X'] + (mcOld[1]-mcNew[1])    
      point['Y'] =  point['Y'] + (mcOld[2]-mcNew[2])
    -- WRITING THE NEW X AND Y POSITIONS

  end
  return(maskTool)
end




--for n, mask in pairs(masks) do
  mask_name = tool:GetAttrs().TOOLS_Name
  
  -- STORE THE CONNECTED NODES INPUTS IN A TABLE TO RECONNECT LATER
  for _, connection in pairs(tool.Mask:GetConnectedInputs()) do
    contool = connection:GetTool()
    table.insert(oldCons, contool) -- NEW OLD CONNECTIONS TABLE
    --print('store connection')
    --print(mask_name)
    --print(contool:GetAttrs().TOOLS_Name)
    --print(contool)

  end


--[[
  -- STORE THE CONNECTED NODES OUTPUTS IN A TABLE TO RECONNECT LATER
  for _, connection2 in pairs(mask.Mask:GetConnectedOutput()) do
    conOuttool = connection2:GetTool()
    table.insert(oldOutCons, conOuttool) -- NEW OLD CONNECTIONS TABLE
    print(conOuttool)

  end
]]

  
  newTool = modifyPoints(tool) -- CALL TO FUNCTION ABOVE TO MANIPULATE THE POINT DATA PASSING THE CURRENTLY SELECTED MASK
  local x, y =  comp.CurrentFrame.FlowView:GetPos(tool)
  tool:Delete() -- DELETES THE OLD TOOL
  comp:Paste(newTool) -- PASTES IN THE NEW TOOL
  


  
  newMask = comp:FindTool(mask_name) -- establish a handle to the newly pasted mask
  comp.CurrentFrame.FlowView:SetPos(newMask, x, y) -- SETS THE POSITION OF THE NEW PASTED TOOL TO THE OLD ONE


  --========== CONNECT IO TOOLS ============

  -- connect the previous input tools up again
  for _, oldCon in pairs(oldCons) do
    --dump(oldCon)
    


  
      oldCon.EffectMask =  newMask -- INPUT TRIANGLE TO OUTPUT SQUARE CONNENCTION LINE
    



      print(newMask:GetAttrs().TOOLS_Name)
      print('--->')
      print(oldCon:GetAttrs().TOOLS_Name)
      print('\n')
    
  end



--end
end


end

--[[
 ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄         ▄  ▄▄        ▄  ▄            ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄  
▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░▌      ▐░▌▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ 
▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌▐░▌░▌     ▐░▌▐░▌          ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌▐░▌    ▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌   ▄   ▐░▌▐░▌ ▐░▌   ▐░▌▐░▌          ▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌  ▐░▌  ▐░▌▐░▌          ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌ ▐░▌░▌ ▐░▌▐░▌   ▐░▌ ▐░▌▐░▌          ▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌
▐░▌       ▐░▌▐░▌       ▐░▌▐░▌▐░▌ ▐░▌▐░▌▐░▌    ▐░▌▐░▌▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌
▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌░▌   ▐░▐░▌▐░▌     ▐░▐░▌▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌
▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░▌     ▐░░▌▐░▌      ▐░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░░░░░░░░░░▌ 
 ▀▀▀▀▀▀▀▀▀▀   ▀▀▀▀▀▀▀▀▀▀▀  ▀▀       ▀▀  ▀        ▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀  
                                                                                                        
]]

-- The URL for the cURL based download:



function download(url,folder,filename)
  -- The URL for the cURL based download:
local sourceURL = url  

-- The filepath for saving the downloaded asset 
local fuDestFile = comp:MapPath(folder) .. filename

-- Set up cURL to work with Fusion 9.0.1
ffi = require "ffi"
curl = require "lj2curl"
ezreq = require "lj2curl.CRLEasyRequest"
local req = ezreq(sourceURL)
local body = {}
req:setOption(curl.CURLOPT_SSL_VERIFYPEER, 0)
req:setOption(curl.CURLOPT_WRITEFUNCTION, ffi.cast("curl_write_callback",
 function(buffer, size, nitems, userdata) 
  table.insert(body, ffi.string(buffer, size*nitems))
  return nitems
 end))

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)


-- Create an "About Window" dialog
function AboutWindow()
  local URL = 'http://www.andrewhazelden.com/blog/'
    
  local width,height = 490,200
  win = disp:AddWindow({
    ID = "AboutWin",
    WindowTitle = 'Download Complete',
    WindowFlags = {Window = true, WindowStaysOnTopHint = true,},
    Geometry = {fu:GetMousePos()[1], fu:GetMousePos()[2], width, height},


    ui:VGroup{
      ID = 'root',
      
      -- Add your GUI elements here:

      ui:TextEdit{ID = 'AboutText', ReadOnly = true, Alignment = {AlignHCenter = true, AlignTop = true}, HTML = '<h1> █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ █ \n<p>Update Complete | '..filename..'</h1>\n<p>Version 1.0 </p>\n<p>Use this button again to automatically update to the latest version of the Fuse<p>\n<p>Copyright &copy; 2018 FIFTY.</p>'},
      --ui:TextEdit{ID = 'AboutText2', ReadOnly = true, Alignment = {AlignHCenter = true, AlignTop = true}, HTML = fuDestFile}
      
      },
    
  })

  -- Add your GUI element based event functions here:
  itm = win:GetItems()

  -- The window was closed
  function win.On.AboutWin.Close(ev)
    disp:ExitLoop()
  end

  win:Show()
  disp:RunLoop()
  win:Hide()

  return win,win:GetItems()
end

-- Download the file from the "sourceURL" address
print('[Downloading] ' .. sourceURL)
ok, err = req:perform()
if ok then
  -- Write the file to disk  
  local file = io.open(fuDestFile, "w")
  file:write(table.concat(body));
  file:close();
  
  -- Show the file we just downloaded in the default HTML viewer on your system:

  AboutWindow()

  --print('[Opening File] ' .. fuDestFile)
  --bmd.openfileexternal('Open', fuDestFile)
end
end

---- replace this part of the DB link to make it perminent:     dl.dropboxusercontent.com

function win.On.update.Clicked(ev)                                                                                         -- change ?dl=0 to ?raw=1 > paste link to browser >    then copy the new long dropbox link here  * use gitlab raw format much better
  download([[https://dl.dropboxusercontent.com/s/ln6p9ga68enfji4/FlexyRig.fuse?dl=0]],"Fuses:/","FlexyRig.fuse")
  download([[https://dl.dropboxusercontent.com/s/6wora34h7nsk4vm/True_IK.fuse?dl=0]],"Fuses:/","True_IK.fuse")
  download([[https://dl.dropboxusercontent.com/s/fc8uigy0dwz4f4w/Fugraph.lua?dl=0]],"Scripts:/Comp/Fugraph/","Fugraph.lua")
  --download([[https://www.dropbox.com/s/lzbamznbxhjxu9g/Fugraph.lua?dl=0]],"Scripts:/Comp/Fugraph/","Fugraph_v1.10.lua")
end


function win.On.OpenShortcuts.Clicked(ev)
  openBrowser1()
end



--[[ ▄▄▄▄▄▄▄▄▄▄▄  ▄            ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄  
▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ 
▐░█▀▀▀▀▀▀▀▀▀ ▐░▌           ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀▀▀▀█░▌
▐░▌          ▐░▌               ▐░▌     ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌
▐░▌          ▐░▌               ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌
▐░▌          ▐░▌               ▐░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░▌ ▐░▌       ▐░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌
▐░▌          ▐░▌               ▐░▌     ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌       ▐░▌▐░█▀▀▀▀▀▀▀█░▌▐░█▀▀▀▀█░█▀▀ ▐░▌       ▐░▌
▐░▌          ▐░▌               ▐░▌     ▐░▌          ▐░▌       ▐░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░▌     ▐░▌  ▐░▌       ▐░▌
▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄  ▄▄▄▄█░█▄▄▄▄ ▐░▌          ▐░█▄▄▄▄▄▄▄█░▌▐░█▄▄▄▄▄▄▄█░▌▐░▌       ▐░▌▐░▌      ▐░▌ ▐░█▄▄▄▄▄▄▄█░▌
▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌          ▐░░░░░░░░░░▌ ▐░░░░░░░░░░░▌▐░▌       ▐░▌▐░▌       ▐░▌▐░░░░░░░░░░▌ 
 ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀            ▀▀▀▀▀▀▀▀▀▀   ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀  ▀         ▀  ▀▀▀▀▀▀▀▀▀▀  ]]                                                                                                                                                                                 


function SampleNodeBlock1() --- POP
  return [[{
  Tools = ordered() {
    Duplicate1 = Fuse.Duplicate {
      Inputs = {
        Copies = Input { Value = 10, },
        Angle = Input {
          Value = 36,
          Expression = "360/Copies",
        },
        RandomSeed = Input { Value = 26024, },
        Background = Input {
          SourceOp = "Background1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { -327, 115 } },
    },
    Background1 = Background {
      CtrlWZoom = false,
      Inputs = {
        Width = Input { Value = 1920, },
        Height = Input { Value = 1080, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
        TopLeftRed = Input { Value = 203/255, },
        TopLeftGreen = Input { Value = 87/255, },
        TopLeftBlue = Input { Value = 87/255, },
        EffectMask = Input {
          SourceOp = "Rectangle1",
          Source = "Mask",
        }
      },
      ViewInfo = OperatorInfo { Pos = { -327, 61 } },
    },
    Rectangle1 = RectangleMask {
      Inputs = {
        MaskWidth = Input { Value = 1920, },
        MaskHeight = Input { Value = 1080, },
        PixelAspect = Input { Value = { 1, 1 }, },
        ClippingMode = Input { Value = FuID { "None" }, },
        Center = Input {
          SourceOp = "Path1",
          Source = "Position",
        },
        Width = Input { Value = 0.00624999999999963, },
        Height = Input {
          SourceOp = "Rectangle1Height",
          Source = "Value",
        },
      },
      ViewInfo = OperatorInfo { Pos = { -327, 28 } },
    },
    Path1 = PolyPath {
      DrawMode = "InsertAndModify",
      Inputs = {
        Displacement = Input {
          SourceOp = "Path1Displacement",
          Source = "Value",
        },
        PolyLine = Input {
          Value = Polyline {
            Points = {
              { Linear = true, LockY = true, X = 0, Y = 0.0842592592592594, RX = 0, RY = 0.0537037037037037 },
              { Linear = true, LockY = true, X = 0, Y = 0.24537037037037, LX = 0, LY = -0.0537037037037037 }
            }
          },
        },
      },
    },
    Path1Displacement = BezierSpline {
      SplineColor = { Red = 255, Green = 0, Blue = 255 },
      NameSet = true,
      KeyFrames = {
        []]..comp.CurrentTime..[[] = { 0, RH = { 6.66666666666667, 0.333333333333333 }, Flags = { Linear = true, LockedY = true } },
        []]..(comp.CurrentTime+20)..[[] = { 1, LH = { 13.3333333333333, 0.666666666666667 }, Flags = { Linear = true, LockedY = true } }
      }
    },
    Rectangle1Height = BezierSpline {
      SplineColor = { Red = 0, Green = 255, Blue = 255 },
      NameSet = true,
      KeyFrames = {
        []]..comp.CurrentTime..[[] = { 0, RH = { 3.33333333333333, 0.037037037037037 }, Flags = { Linear = true } },
        []]..(comp.CurrentTime+10)..[[] = { 0.111111111111111, LH = { 6.66666666666667, 0.0740740740740741 }, RH = { 13.3333333333333, 0.0740740740740741 }, Flags = { Linear = true } },
        []]..(comp.CurrentTime+20)..[[] = { 0, LH = { 16.6666666666667, 0.0370370370370371 }, Flags = { Linear = true } }
      }
    }
  }
}
]]

end  


function SampleNodeBlock2() -- wave
  return [[
    {
  Tools = ordered() {
    Background1 = Background {
      CtrlWZoom = false,
      Inputs = { 
        Width = Input { Value = 1920, },
        Height = Input { Value = 1080, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
        TopLeftRed = Input { Value = 203/255, },
        TopLeftGreen = Input { Value = 87/255, },
        TopLeftBlue = Input { Value = 87/255, },
        EffectMask = Input {
          SourceOp = "Ellipse1",
          Source = "Mask",
        }
      },
      ViewInfo = OperatorInfo { Pos = { -363, 98 } },
    },
    Ellipse1 = EllipseMask {
      Inputs = {
        BorderWidth = Input {
          SourceOp = "Ellipse1BorderWidth",
          Source = "Value",
        },
        Solid = Input { Value = 0, },
        MaskWidth = Input { Value = 1920, },
        MaskHeight = Input { Value = 1080, },
        PixelAspect = Input { Value = { 1, 1 }, },
        ClippingMode = Input { Value = FuID { "None" }, },
        Width = Input {
          SourceOp = "Ellipse1Width",
          Source = "Value",
        },
        Height = Input {
          Value = 0.0178054387825843,
          Expression = "Width",
        },
      },
      ViewInfo = OperatorInfo { Pos = { -363, 65 } },
    },
    Ellipse1BorderWidth = BezierSpline {
      SplineColor = { Red = 16, Green = 35, Blue = 248 },
      NameSet = true,
      KeyFrames = {
        []]..comp.CurrentTime..[[] = { 0, RH = { 5, 0.00226666666666667 }, Flags = { Linear = true } },
        []]..(comp.CurrentTime+15)..[[] = { 0.0068, LH = { 10, 0.00453333333333333 }, RH = { 20, 0.00453333333333333 }, Flags = { Linear = true } },
        []]..(comp.CurrentTime+30)..[[] = { 0, LH = { 25, 0.00226666666666667 }, Flags = { Linear = true } }
      }
    },
    Ellipse1Width = BezierSpline {
      SplineColor = { Red = 225, Green = 255, Blue = 0 },
      NameSet = true,
      KeyFrames = {
        []]..comp.CurrentTime..[[] = { 0, RH = { ]]..(comp.CurrentTime+15.6)..[[, 0.021 }, Flags = { Linear = true } },
        []]..(comp.CurrentTime+30)..[[] = { 0.205567578946411, LH = { ]]..(comp.CurrentTime+15)..[[, 0.189 } }
      }
    },
    Duplicate1 = Fuse.Duplicate {
      Inputs = {
        TimeOffset = Input { Value = -3.077, },
        RandomSeed = Input { Value = 26024, },
        Background = Input {
          SourceOp = "Background1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { -362, 142 } },
    }
  }
}
]]

end
                                                                                                                                                             

function SampleNodeBlock3() --- flexy
  return [[

{
  Tools = ordered() {
    FlexyRig1 = Fuse.FlexyRig {
      CtrlWZoom = false,
      Inputs = {
        StartPos1 = Input { Value = { 0.265625, 0.507407407407407 }, },
        EndPos1 = Input { Value = { 0.7359375, 0.5 }, },
        BendDirection = Input { Value = 0.205, },
        LineStyle = Input { Value = 1, },
        Thickness = Input { Value = 0.0402, },
        Red = Input { Value = 0.796078431372549, },
        Green = Input { Value = 0.341176470588235, },
        Blue = Input { Value = 0.341176470588235, },
        OnBlack = Input { Value = 1, },
        Input = Input {
          SourceOp = "Background1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1352, 261 } },
    },
    Background1 = Background {
      Inputs = {
        Width = Input { Value = 1920, },
        Height = Input { Value = 1920, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
      },
      ViewInfo = OperatorInfo { Pos = { 1242, 261 } },
    }
  }
}


]]
end

function SampleNodeBlock4() --- true ik
  return [[

{
  Tools = ordered() {
    Merge4 = Merge {
      Inputs = {
        Background = Input {
          SourceOp = "Merge3",
          Source = "Output",
        },
        Foreground = Input {
          SourceOp = "True_IK1",
          Source = "Output",
        },
        PerformDepthMerge = Input { Value = 0, },
      },
      ViewInfo = OperatorInfo { Pos = { 1415, 440 } },
    },
    Transform4 = Transform {
      Inputs = {
        Center = Input { Value = { 0.717807835494571, 0.763223679634304 }, },
        Pivot = Input { Value = { 0.287695724660527, -0.0358133527504727 }, },
        Size = Input { Value = 0.444, },
        Input = Input {
          SourceOp = "Transform1_1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1148, 357 } },
    },
    Transform3 = Transform {
      Inputs = {
        Center = Input {
          Value = { 0.515325670498085, 0.699233716475096 },
          Expression = "True_IK1.StartPos1",
        },
        Pivot = Input { Value = { 0.485088997384184, 0.412232797628335 }, },
        Angle = Input {
          Value = 331.752999846656,
          Expression = "True_IK1.StartAngle*-1+180",
        },
        Input = Input {
          SourceOp = "Transform4",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1142, 390 } },
    },
    Merge3 = Merge {
      Inputs = {
        Background = Input {
          SourceOp = "Merge2",
          Source = "Output",
        },
        Foreground = Input {
          SourceOp = "Transform3",
          Source = "Output",
        },
        PerformDepthMerge = Input { Value = 0, },
      },
      ViewInfo = OperatorInfo { Pos = { 1144, 440 } },
    },
    True_IK1 = Fuse.True_IK {
      CtrlWZoom = false,
      Inputs = {
        StartPos1 = Input { Value = { 0.546413502109705, 0.683544303797468 }, },
        StartAngle = Input { Value = -114.278572250056, },
        MidPos1 = Input { Value = { 0.364855001382227, 0.59966039107524 }, },
        MidAngle = Input { Value = 171.071290733522, },
        EndPos1 = Input { Value = { 0.397685775255832, 0.402373441970997 }, },
        VanishingPointHidden = Input {
          Value = { 0.5, 0.595799236588901 },
          Disabled = true,
        },
        Input = Input {
          SourceOp = "Background1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1412, 288 } },
    },
    Background1 = Background {
      Inputs = {
        Width = Input { Value = 1000, },
        Height = Input { Value = 1000, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
        TopLeftAlpha = Input { Value = 0, },
      },
      ViewInfo = OperatorInfo { Pos = { 1265, 285 } },
    },
    Crop1_1 = Crop {
      Inputs = {
        XSize = Input { Value = 1000, },
        YSize = Input { Value = 1000, },
        Input = Input {
          SourceOp = "Transform1_1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1142, 287 } },
    },
    Crop1 = Crop {
      Inputs = {
        XSize = Input { Value = 1000, },
        YSize = Input { Value = 1000, },
        Input = Input {
          SourceOp = "Transform1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 968, 271 } },
    },
    Transform5 = Transform {
      Inputs = {
        Center = Input { Value = { 0.48901390879993, 0.135658457356582 }, },
        Pivot = Input { Value = { 0.527904214559387, 0.905425287356322 }, },
        Size = Input { Value = 0.419, },
        Input = Input {
          SourceOp = "Crop1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 969, 358 } },
    },
    Transform2 = Transform {
      Inputs = {
        Center = Input { Expression = "True_IK1.MidPos1", },
        Angle = Input { Expression = "True_IK1.MidAngle*-1+180", },
        Input = Input {
          SourceOp = "Transform5",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 967, 391 } },
    },
    Merge2 = Merge {
      Inputs = {
        Background = Input {
          SourceOp = "Background2_1",
          Source = "Output",
        },
        Foreground = Input {
          SourceOp = "Transform2",
          Source = "Output",
        },
        PerformDepthMerge = Input { Value = 0, },
      },
      ViewInfo = OperatorInfo { Pos = { 962, 440 } },
    },
    Transform1_1 = Transform {
      Inputs = {
        Center = Input { Value = { 0.37819582173611, 0.300855704560199 }, },
        Size = Input { Value = 0.427, },
        Input = Input {
          SourceOp = "Background3_1",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1141, 250 } },
    },
    Transform1 = Transform {
      Inputs = {
        Center = Input { Value = { 0.285534591194969, 0.231851179673321 }, },
        Size = Input { Value = 0.427, },
        Input = Input {
          SourceOp = "Background3",
          Source = "Output",
        },
      },
      ViewInfo = OperatorInfo { Pos = { 964, 236 } },
    },
    Background2_1 = Background {
      Inputs = {
        Width = Input { Value = 1000, },
        Height = Input { Value = 1000, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
        TopLeftAlpha = Input { Value = 0, },
      },
      ViewInfo = OperatorInfo { Pos = { 806, 440 } },
    },
    Background3_1 = Background {
      Inputs = {
        Width = Input { Value = 1349, },
        Height = Input { Value = 1768, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
        TopLeftRed = Input { Value = 0.725490196078431, },
        TopLeftGreen = Input { Value = 0.376470588235294, },
        TopLeftBlue = Input { Value = 0.352941176470588, },
        EffectMask = Input {
          SourceOp = "Polygon1_1",
          Source = "Mask",
        }
      },
      ViewInfo = OperatorInfo { Pos = { 1135, 202 } },
    },
    Background3 = Background {
      Inputs = {
        Width = Input { Value = 1590, },
        Height = Input { Value = 2204, },
        ["Gamut.SLogVersion"] = Input { Value = FuID { "SLog2" }, },
        TopLeftRed = Input { Value = 0.725490196078431, },
        TopLeftGreen = Input { Value = 0.376470588235294, },
        TopLeftBlue = Input { Value = 0.352941176470588, },
        EffectMask = Input {
          SourceOp = "Polygon1",
          Source = "Mask",
        }
      },
      ViewInfo = OperatorInfo { Pos = { 960, 174 } },
    },
    Polygon1_1 = PolylineMask {
      DrawMode = "InsertAndModify",
      DrawMode2 = "InsertAndModify",
      Inputs = {
        OutputSize = Input { Value = FuID { "Custom" }, },
        MaskWidth = Input { Value = 1349, },
        MaskHeight = Input { Value = 1768, },
        PixelAspect = Input { Value = { 1, 1 }, },
        ClippingMode = Input { Value = FuID { "None" }, },
        Polyline = Input {
          SourceOp = "Polygon1_1Polyline",
          Source = "Value",
        },
        Polyline2 = Input {
          Value = Polyline {
          },
          Disabled = true,
        },
      },
      ViewInfo = OperatorInfo { Pos = { 1138, 149 } },
    },
    Polygon1_1Polyline = BezierSpline {
      SplineColor = { Red = 173, Green = 255, Blue = 47 },
      NameSet = true,
      KeyFrames = {
        [5] = { 0, Flags = { Linear = true, LockedY = true }, Value = Polyline {
            Closed = true,
            Points = {
              { X = -0.431142419576645, Y = 0.482100248336792, LX = -0.0172143974960877, LY = -0.013126491646778, RX = 0.0172143974960876, RY = 0.013126491646778 },
              { X = 0.407668232917786, Y = 0.491646766662598, LX = -0.0203442866440297, LY = 0.00954652799911315, RX = 0.104779622632362, RY = -0.0491676910917839 },
              { X = 0.47496086359024, Y = 0.214797139167786, LX = 0.0359937274400055, LY = 0.0644391439410555, RX = -0.0407750334245223, RY = -0.0729990594173294 },
              { X = 0.282472610473633, Y = 0.0274462997913361, LX = 0.0485132990495326, LY = -0.00119331834708895, RX = -0.0653053626905823, RY = 0.00160636545006747 },
              { X = 0.0868544578552246, Y = 0.0369928404688835, LX = 0.0651563949639129, LY = -0.00397008761373999, RX = -0.0216688726466578, RY = -0.126946247953739 },
              { X = -0.0010471662080872, Y = -0.341164589063075, LX = 0.0317105468534752, LY = 0.0495694896250491, RX = -0.0455694160398731, RY = -0.0712334828549475 },
              { X = -0.251600931058652, Y = -0.482596992906942, LX = 0.131358150105846, LY = -0.0046052536571177, RX = -0.118067687501038, RY = 0.00413930653875271 },
              { X = -0.484777758489377, Y = -0.278858297955397, LX = 0.014133762640059, LY = -0.0923777185438704, RX = -0.0198689136700494, RY = 0.129862440846579 },
              { X = -0.481220662593842, Y = 0.113365158438683, LX = -0.00745220942804907, LY = -0.102285515639536, RX = 0.00898899993865951, RY = 0.12337877815791 }
            }
          } }
      }
    },
    Polygon1 = PolylineMask {
      DrawMode = "InsertAndModify",
      DrawMode2 = "InsertAndModify",
      Inputs = {
        OutputSize = Input { Value = FuID { "Custom" }, },
        MaskWidth = Input { Value = 1590, },
        MaskHeight = Input { Value = 2204, },
        PixelAspect = Input { Value = { 1, 1 }, },
        ClippingMode = Input { Value = FuID { "None" }, },
        Polyline = Input {
          SourceOp = "Polygon1Polyline",
          Source = "Value",
        },
        Polyline2 = Input {
          Value = Polyline {
          },
          Disabled = true,
        },
      },
      ViewInfo = OperatorInfo { Pos = { 963, 121 } },
    },
    Polygon1Polyline = BezierSpline {
      SplineColor = { Red = 173, Green = 255, Blue = 47 },
      NameSet = true,
      KeyFrames = {
        [5] = { 0, Flags = { Linear = true, LockedY = true }, Value = Polyline {
            Closed = true,
            Points = {
              { X = 0.100372925899689, Y = 0.397116178606439, LX = -0.158451408484856, LY = -0.0194082957510917, RX = 0.0729044530940522, RY = 0.00892987446909667 },
              { X = 0.396342172040127, Y = 0.228836275587515, LX = -0.0462122281689858, LY = 0.169428500182435, RX = 0.0381042761053362, RY = -0.139702208849507 },
              { X = 0.446949601173401, Y = -0.197318002581596, LX = -0.0211175965639038, LY = 0.00508386951901124, RX = 0.0280498456582794, RY = -0.00675274550887315 },
              { X = 0.502652525901794, Y = -0.247126430273056, LX = -0.0138265395350571, LY = 0.0215278410912933, RX = -0.00574712843941335, RY = -0.0146871030635152 },
              { Linear = true, X = 0.485411137342453, Y = -0.291187733411789, LX = 0.00574712843941335, LY = 0.0146871030635152, RX = -0.0181255515279441, RY = 0.00446998521133705 },
              { Linear = true, X = 0.431034475564957, Y = -0.277777791023254, LX = 0.0181255515279441, LY = -0.00446998521133705, RX = 0.0106100819734848, RY = -0.0510855639117888 },
              { Linear = true, X = 0.462864726781845, Y = -0.431034475564957, LX = -0.0106100819734848, LY = 0.0510855639117888, RX = -0.0614500459741429, RY = -0.00766283764693015 },
              { Linear = true, X = 0.278514593839645, Y = -0.454022973775864, LX = 0.0614500459741429, LY = 0.00766283764693015, RX = -0.00663130139482434, RY = 0.0105363935574718 },
              { Linear = true, X = 0.25862067937851, Y = -0.422413796186447, LX = 0.00663130139482434, LY = -0.0105363935574718, RX = -0.194076035478071, RY = -0.0265006375419378 },
              { X = -0.323607414960861, Y = -0.501915693283081, LX = 0.0835543887526667, LY = -0.00383140209534114, RX = -0.0544762330121964, RY = 0.00249801783515035 },
              { X = -0.485411137342453, Y = -0.483716487884521, LX = 0.0536637446846977, LY = -0.00785059378170461, RX = 0.00265251881353209, RY = 0.0440613069449044 },
              { X = -0.477453589439392, Y = -0.351532578468323, LX = -0.0371352870521243, LY = -0.0143678275104682, RX = 0.0744218326833595, RY = 0.0287941777185288 },
              { X = -0.237400531768799, Y = -0.293103456497192, LX = -0.0636604787184012, LY = -0.0229885139684565, RX = 0.044755149761489, RY = 0.0161615873170456 },
              { X = -0.132625997066498, Y = -0.215517237782478, LX = -0.030009692470406, LY = -0.0307123156988342, RX = -0.0101679921361011, RY = 0.0118135364766626 },
              { Linear = true, X = -0.163129970431328, Y = -0.180076628923416, LX = 0.0101679921361011, LY = -0.0118135364766626, RX = 0.0159151183489042, RY = 0.0226692211353916 },
              { X = -0.115384615957737, Y = -0.112068966031075, LX = -0.0477453586633075, LY = -0.0220306518548291, RX = 0.022630502174348, RY = 0.010442160843713 },
              { X = -0.0477453581988811, Y = -0.0804597735404968, LX = -0.0225043777922539, LY = -0.0105835158234324, RX = -0.0140257831176486, RY = 0.0745395400089327 },
              { X = -0.0533999181227919, Y = 0.145452535943864, LX = 0.01508433333076, LY = -0.046443861889078, RX = -0.028993593046021, RY = 0.0892697344702389 }
            }
          } }
      }
    }
  }
}


]]
end






function SampleNodeBlock7() --- rs cam
  return [[

{
  Tools = ordered() {
    Camera3D1 = Camera3D {
      CurrentSettings = 6,
      CustomData = {
        Settings = {
          [1] = {
            Tools = ordered() {
              Camera3D1 = Camera3D {
                Inputs = {
                  ApertureW = Input { Value = 0.831496062992126 },
                  ["SurfacePlaneInputs.ObjectID.ObjectID"] = Input { Value = 1 },
                  AoV = Input { Value = 19.2642683071402 },
                  ["Stereo.Mode"] = Input { Value = FuID { "OffAxis" } },
                  FilmGate = Input { Value = FuID { "BMD_URSA_4K_16x9" } },
                  ApertureH = Input { Value = 0.467716535433071 },
                  ImageInput = Input {
                    SourceOp = "RSCameraExtractor2",
                    Source = "Output"
                  },
                  ["MtlStdInputs.MaterialID"] = Input { Value = 1 }
                },
                CtrlWZoom = false,
                ViewInfo = OperatorInfo { Pos = { -385, 247.5 } },
                CustomData = {
                }
              }
            }
          },
          [6] = {
            Tools = ordered() {
              Camera3D1 = Camera3D {
                Inputs = {
                  FLength = Input { Value = 1000000 },
                  ["Transform3DOp.Translate.Z"] = Input { Expression = "self.ImageInput.Metadata.Translate.Z" },
                  ImagePlaneEnabled = Input { Value = 0 },
                  AoV = Input {
                    Value = 19.2642683071402,
                    Expression = "self.ImageInput.Metadata.RSCameraFOV"
                  },
                  AovType = Input { Value = 1 },
                  ["Transform3DOp.Rotate.Y"] = Input { Expression = "self.ImageInput.Metadata.Rotate.Y" },
                  ApertureH = Input { Value = 0.9 },
                  FilmGate = Input { Value = FuID { "HD" } },
                  ["Transform3DOp.Rotate.X"] = Input { Expression = "self.ImageInput.Metadata.Rotate.X" },
                  ["Transform3DOp.Translate.X"] = Input { Expression = "self.ImageInput.Metadata.Translate.X" },
                  PlaneOfFocus = Input { Expression = "self.ImageInput.Metadata.RSCameraDOFFocusDistance" },
                  ImageInput = Input {
                    SourceOp = "RSCameraExtractor1",
                    Source = "Output"
                  },
                  FilmBack = Input { Value = 1 },
                  ["Transform3DOp.Rotate.RotOrder"] = Input { Value = FuID { "ZXY" } },
                  ["MtlStdInputs.MaterialID"] = Input { Value = 1 },
                  ["Stereo.Mode"] = Input { Value = FuID { "OffAxis" } },
                  ["SurfacePlaneInputs.ObjectID.ObjectID"] = Input { Value = 1 },
                  ["Transform3DOp.Translate.Y"] = Input { Expression = "self.ImageInput.Metadata.Translate.Y" },
                  ApertureW = Input { Value = 1.6 },
                  ["Transform3DOp.Rotate.Z"] = Input { Expression = "self.ImageInput.Metadata.Rotate.Z" }
                },
                Name = "Camera3D1",
                CtrlWZoom = false,
                ViewInfo = OperatorInfo { Pos = { -440, 511.5 } },
                CustomData = {
                }
              }
            }
          }
        }
      },
      Inputs = {
        ["Transform3DOp.Translate.X"] = Input {
          Value = 0.958859324455261,
          Expression = "self.ImageInput.Metadata.Translate.X",
        },
        ["Transform3DOp.Translate.Y"] = Input {
          Value = 116.92407989502,
          Expression = "self.ImageInput.Metadata.Translate.Y",
        },
        ["Transform3DOp.Translate.Z"] = Input {
          Value = -107.473159790039,
          Expression = "self.ImageInput.Metadata.Translate.Z",
        },
        ["Transform3DOp.Rotate.RotOrder"] = Input { Value = FuID { "ZXY" }, },
        ["Transform3DOp.Rotate.X"] = Input {
          Value = -47.3932253638923,
          Expression = "self.ImageInput.Metadata.Rotate.X",
        },
        ["Transform3DOp.Rotate.Y"] = Input {
          Value = -180.262955898845,
          Expression = "self.ImageInput.Metadata.Rotate.Y",
        },
        ["Transform3DOp.Rotate.Z"] = Input {
          Value = -0.000682107510962752,
          Expression = "self.ImageInput.Metadata.Rotate.Z",
        },
        AovType = Input { Value = 1, },
        AoV = Input {
          Value = 23.4018363952637,
          Expression = "self.ImageInput.Metadata['rs/camera/fov']",
        },
        FLength = Input { Value = 98.1136504753142, },
        PlaneOfFocus = Input {
          Value = 100,
          Expression = "self.ImageInput.Metadata['rs/camera/DOFFocusDistance']",
        },
        ["Stereo.Mode"] = Input { Value = FuID { "OffAxis" }, },
        FilmGate = Input { Value = FuID { "HD" }, },
        ApertureW = Input { Value = 1.6, },
        ApertureH = Input { Value = 0.9, },
        ImagePlaneEnabled = Input { Value = 0, },
        ["SurfacePlaneInputs.ObjectID.ObjectID"] = Input { Value = 1, },
        ImageInput = Input {
          SourceOp = "RSCameraExtractor2",
          Source = "Output",
        },
        ["MtlStdInputs.MaterialID"] = Input { Value = 1, },
      },
      ViewInfo = OperatorInfo { Pos = { 1534, 349 } },
    },
    RSCameraExtractor2 = Fuse.RSCameraExtractor {
      ViewInfo = OperatorInfo { Pos = { 1369, 349 } },
      Version = 100
    },
    Note1 = Note {
      Inputs = {
        Comments = Input { Value = "reads the .EXR metadata on the input here, install from reactor", }
      },
      ViewInfo = StickyNoteInfo {
        Pos = { 1096, 326 },
        Flags = {
          Expanded = true
        },
        Size = { 234, 49.3 }
      },
    }
  }
}

]]
end

function SampleNodeBlock6() --- glow
  return [[

  {
  Tools = ordered() {
    FUglow = MacroOperator {
      CtrlWZoom = false,
      Inputs = ordered() {
        Input1 = InstanceInput {
          SourceOp = "Merge1_1",
          Source = "ApplyMode",
        },
        Input2 = InstanceInput {
          SourceOp = "Merge1_1",
          Source = "Gain",
          Default = 0,
        },
        Input3 = InstanceInput {
          SourceOp = "Merge1_1",
          Source = "BlendClone",
          Default = 0.483,
        },
        Input4 = InstanceInput {
          SourceOp = "Blur1_2",
          Source = "LockXY",
          Default = 1,
        },
        Input5 = InstanceInput {
          SourceOp = "Blur1_2",
          Source = "XBlurSize",
          Default = 50,
        },
        Input6 = InstanceInput {
          SourceOp = "Blur1_2",
          Source = "YBlurSize",
          Default = 1,
        },
        MainInput1 = InstanceInput {
          SourceOp = "Transform4_1",
          Source = "Input",
        },
        Input7 = InstanceInput {
          SourceOp = "DirectionalBlur1_1",
          Source = "Length",
          Default = 0.0761,
        },
        Input8 = InstanceInput {
          SourceOp = "DirectionalBlur1_1",
          Source = "Angle",
          Default = 138.9,
        },
        Input9 = InstanceInput {
          SourceOp = "DirectionalBlur1_1",
          Source = "Glow",
          Default = 0,
        }
      },
      Outputs = {
        MainOutput1 = InstanceOutput {
          SourceOp = "Merge4_1_1_1_1",
          Source = "Output",
        }
      },
      ViewInfo = GroupInfo { Pos = { 1542.94, 671.427 } },
      Tools = ordered() {
        Merge4_1_2 = Merge {
          CtrlWShown = false,
          Inputs = {
            Blend = Input {
              Value = 0.483,
              Expression = "Merge1_1.BlendClone",
            },
            Background = Input {
              SourceOp = "Merge4_2",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "Blur1_1_1_1_1_2",
              Source = "Output",
            },
            ApplyMode = Input { Expression = "Merge1_1.ApplyMode", },
            Gain = Input {
              Value = 0,
              Expression = "Merge1_1.Gain",
            },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { 326.125, 199.655 } },
        },
        Merge4_1_1_1_1 = Merge {
          CtrlWShown = false,
          Inputs = {
            Blend = Input { Value = 0.197, },
            Background = Input {
              SourceOp = "Merge4_1_1_2",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "DirectionalBlur1_1",
              Source = "Output",
            },
            ApplyMode = Input { Expression = "Merge1_1.ApplyMode", },
            Gain = Input { Expression = "Merge1_1.Gain", },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { 618.865, 197.534 } },
        },
        Merge4_1_1_2 = Merge {
          CtrlWShown = false,
          Inputs = {
            Blend = Input { Expression = "Merge1_1.BlendClone", },
            Background = Input {
              SourceOp = "Merge4_1_2",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "Blur1_1_1_1_1_1_1",
              Source = "Output",
            },
            ApplyMode = Input { Expression = "Merge1_1.ApplyMode", },
            Gain = Input { Expression = "Merge1_1.Gain", },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { 467.545, 196.12 } },
        },
        Merge4_2 = Merge {
          CtrlWZoom = false,
          CtrlWShown = false,
          Inputs = {
            Blend = Input { Expression = "Merge1_1.BlendClone", },
            Background = Input {
              SourceOp = "Merge3_1",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "Blur1_1_1_1_2",
              Source = "Output",
            },
            ApplyMode = Input { Expression = "Merge1_1.ApplyMode", },
            Gain = Input { Expression = "Merge1_1.Gain", },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { 140.855, 202.873 } },
          Colors = {
            TileColor = { R = 0.972549019607843, G = 0.698039215686274, B = 0.537254901960784 },
            TextColor = { R = 0, G = 0, B = 0 },
          }
        },
        Merge3_1 = Merge {
          CtrlWShown = false,
          Inputs = {
            Blend = Input { Expression = "Merge1_1.BlendClone", },
            Background = Input {
              SourceOp = "Merge2_1",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "Blur1_1_1_2",
              Source = "Output",
            },
            ApplyMode = Input { Expression = "Merge1_1.ApplyMode", },
            Gain = Input {
              Value = 0,
              Expression = "Merge1_1.Gain",
            },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { -50.775, 202.873 } },
        },
        Merge2_1 = Merge {
          CtrlWShown = false,
          Inputs = {
            Blend = Input { Expression = "Merge1_1.BlendClone", },
            Background = Input {
              SourceOp = "Merge1_1",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "Blur1_1_2",
              Source = "Output",
            },
            ApplyMode = Input { Expression = "Merge1_1.ApplyMode", },
            Gain = Input {
              Value = 0,
              Expression = "Merge1_1.Gain",
            },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { -221.185, 202.873 } },
        },
        Blur1_1_1_1_1_2 = Blur {
          CtrlWShown = false,
          Inputs = {
            UseOpenCL = Input {
              Value = 2,
              Expression = "Blur1_2.UseOpenCL",
            },
            XBlurSize = Input {
              Value = 4.8375,
              Expression = "Blur1_2.XBlurSize/16",
            },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { 326.125, 112.681 } },
        },
        Blur1_1_1_2 = Blur {
          CtrlWShown = false,
          Inputs = {
            UseOpenCL = Input {
              Value = 2,
              Expression = "Blur1_2.UseOpenCL",
            },
            XBlurSize = Input {
              Value = 19.35,
              Expression = "Blur1_2.XBlurSize/4",
            },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { -50.775, 114.095 } },
        },
        Blur1_1_1_1_2 = Blur {
          CtrlWShown = false,
          Inputs = {
            UseOpenCL = Input {
              Value = 2,
              Expression = "Blur1_2.UseOpenCL",
            },
            XBlurSize = Input {
              Value = 9.675,
              Expression = "Blur1_2.XBlurSize/8",
            },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { 140.855, 114.802 } },
        },
        Blur1_1_2 = Blur {
          CtrlWShown = false,
          Inputs = {
            UseOpenCL = Input {
              Value = 2,
              Expression = "Blur1_2.UseOpenCL",
            },
            XBlurSize = Input {
              Value = 38.7,
              Expression = "Blur1_2.XBlurSize/2",
            },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { -215.525, 106.317 } },
        },
        Blur1_1_1_1_1_1_1 = Blur {
          CtrlWShown = false,
          Inputs = {
            UseOpenCL = Input {
              Value = 2,
              Expression = "Blur1_2.UseOpenCL",
            },
            XBlurSize = Input {
              Value = 2.41875,
              Expression = "Blur1_2.XBlurSize/32",
            },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { 473.195, 104.903 } },
        },
        Merge1_1 = Merge {
          CtrlWShown = false,
          Inputs = {
            Background = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
            Foreground = Input {
              SourceOp = "Blur1_2",
              Source = "Output",
            },
            Gain = Input { Value = 0, },
            PerformDepthMerge = Input { Value = 0, },
          },
          ViewInfo = OperatorInfo { Pos = { -404.665, 202.873 } },
        },
        Blur1_2 = Blur {
          CtrlWShown = false,
          Inputs = {
            UseOpenCL = Input { Value = 2, },
            XBlurSize = Input { Value = 77.4, },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { -400.735, 99.635 } },
        },
        Transform4_1 = Transform {
          CtrlWShown = false,
          ViewInfo = OperatorInfo { Pos = { -619.575, 178.83 } },
        },
        DirectionalBlur1_1 = DirectionalBlur {
          CtrlWZoom = false,
          CtrlWShown = false,
          Inputs = {
            Type = Input { Value = 2, },
            Length = Input { Value = 0.0641, },
            Angle = Input { Value = 299.9, },
            Input = Input {
              SourceOp = "Transform4_1",
              Source = "Output",
            },
          },
          ViewInfo = OperatorInfo { Pos = { 619.575, 10.15 } },
        }
      },
    }
  },
  ActiveTool = "FUglow"
}

]]

end


  win:Show()
  disp:RunLoop()
  win:Hide()

  return win,win:GetItems()
end

--print(comp.ActiveTool)

-- Create a window
MainWindow()


--else -- trial expired
--[[
    -- Create a new window
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
local width,height = 363,200
 
win = disp:AddWindow({
  ID = 'MyWin',
  WindowTitle = 'FuGraph TRIAL PERIOD EXPIRED',
  Geometry = { 400, 400, width, height },
  Spacing = 10,
 
  ui:VGroup{
    ID = 'root',
   
    -- Add your GUI elements here:
    ui:Label{ ID = 'L', 
    Text = tostring("<font color='#D89696'><center>").. 'TRIAL PERIOD EXPIRED ON '..d..'/'..m..'/'..y,
    Alignment = { AlignHCenter = true },
    Color = {R = 1, G = 0.5, B = 0.5, A = 0.2},
    Font = ui:Font{
          --Family = 'Droid Sans Mono',
          StyleName = 'Bold',
          PixelSize = 12,
          --MonoSpaced = true,
          StyleStrategy = {ForceIntegerMetrics = true},
      },

    },
    ui:Button{ID = 'logo', IconSize = {350,170}, Flat = true, Icon = ui:Icon{File = 'Scripts:/Comp/Fugraph/UI Manager/FUGRAPH_Trial.png'},MaximumSize = {344,170},MinimumSize = {344,170}},
    
  },
})
 
-- The window was closed
function win.On.MyWin.Close(ev)
    disp:ExitLoop()
end
 
-- Add your GUI element based event functions here:
itm = win:GetItems()
 
win:Show()
disp:RunLoop()
win:Hide()

   ]] 
--end -- Trial check






