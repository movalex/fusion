--[[
v 2.4
-- update ui position on refresh button
-- add toggle layout buttons to reduce buttons count
-- replace TimeView buttom with ExpandViewer button
-- optional hide LayoutStrip on ExpandViewer press to maximize veiwer real estate (beta!)
-- * known issue: all Fusion floating windows will be closed if LayoutStrip is set to Hide
-- "fix" Resolve positioning
v 2.3.2
toggle UI with launch shortcut (SHIFT+ALT+T)
v 2.3
-- add close preferences button
-- add initial window offset based on left viewer window size
-- add toggle TimeVew button
-- add optional launch on mouse position
    * if you need to launch the tool at custom position, first set prefs to launch at mouse pos, restart the script
    * then open tool preferences and set Save Position
-- add Fusion9 style View Bar with 5 simple layout presets
-- click Add Toolbars! button to launch Customize Toolbars dialogue
v 2.0 
    -- add preferences for save position and stay on top of all windows
    -- now properly working with 3D viewers
v 1.3 add some working buttons 2019-05-21
-- partial implementation for Fusion 16 by Alex Bogomolov
-- email: mail@abogomolov.com
v 1.0 Initial release 2019-01-21
-- original sample script and icons by Andrew Hazelden.
-- MIT License:
Copyright 2020 Alexey Bogomolov
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- If you use this script, and have any comments or issues
   feel free to contact me on the above email adress.
-- general discussion and screenshots: https://www.steakunderwater.com/wesuckless/viewtopic.php?p=23876#p23876
-- donate! https://paypal.me/aabogomolov
]]

ui = fu.UIManager
disp = bmd.UIDispatcher(ui)
comp = fu:GetCurrentComp()
fu:SetData('Toolbar16.CurrentComp', comp:GetAttrs().COMPS_FileName)
timeview_status = comp:IsViewShowing('Time')

local oldprint = print
print = function(...)
    oldprint('[Toolbar16] - ',  ...)
end

-- The app:AddConfig() command will capture the "Escape" hotkey to close the window.
app:AddConfig('ToolbarWin', {
    Target {
        ID = 'ToolbarWin',
    },
    Hotkeys {
        Target = 'ToolbarWin',
        Defaults = true,
        ESCAPE = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
    },
})

function _init(side)
    comp = fu:GetCurrentComp()
    GlView = get_glview(side)
    viewer = GlView.CurrentViewer
    viewer_type = string.sub(tostring(viewer),1,2)
    if not viewer then
        print('Load any 2D tool to the '.. side ..' viewer')
        return nil
    end

    guides_state = viewer:AreGuidesShown()
    controls_state = viewer:AreControlsShown()
    multiview_state = GlView:ShowingQuadView()
    locked_state = GlView:GetLocked()
    stereo_state = GlView:IsStereoEnabled()
    
    if viewer_type ~= "2D" then
        print('This tool is most useful with 2D viewers')
        return
    end

    lut_state = viewer:IsLUTEnabled()
    roi_state = viewer:IsEnableRoI()

    if fu.Version >= 16 then
        checker_state = viewer:IsCheckerEnabled()
        dod_state = viewer:IsDoDShown()
        sliders_state = viewer:IsShowGainGamma()
    else
        -- check DoD, checkers and sliders state it not implemented in Fusion 9
        dod_state = false
        checker_state = false
        sliders_state = false
    end
end


function has_value(tab, val)
    for index, value in pairs(tab) do
        if index == val then
            return true
        end
    end
    return false
end


function get_glview(side)
    local previewList = comp:GetPreviewList()
    if side == 'left' then
        if has_value(previewList, "LeftView") then
            glview = previewList.LeftView.View
        else
            glview = previewList.Left.View
        end
        return glview
    end
    if side == 'right' then
        if has_value(previewList, "RightView") then
            glview = previewList.RightView.View
        else
            glview = previewList.Right.View
        end
        return glview
    end
end


function get_tb_offset(timeview_status)
    TBoffset = 35 -- fusion 9 offset
    if fu.Version >= 16 then
        if fu:GetData('Layouter.Set') then
            return 1
        end
        if fu:GetPrefs('Global.Unsorted.ToolbarState') == false then
            TBoffset = 85 -- fusion 16 offset
        else
            TBoffset = 136 -- fusion 16 offset with default toolbar turned on
        end
        if timeview_status == false then
            -- timeView is off, offset is zero
            TBoffset = TBoffset - 84
        end
    end
    return TBoffset
end

function get_window_xy()
    local view_attrs = get_glview('left'):GetAttrs()
    main_window_dimensions = fu:GetPrefs("Global.Main.Window")
    if not main_window_dimensions or main_window_dimensions.Width == -1 then
        if app:GetVersion().App == 'Fusion' then
            print("[Warning] The Window dimensions are undefined. Please press 'Grab probram layout' button in the Layout Preferences section.")
            app:ShowPrefs("PrefsLayout")
        else
            print('setting UI width to default 1920px until better solution for Resolve arrived')
            main_window_dimensions.Width = 1920
            main_window_dimensions.Height = 1100
        end
    end
    local save_pos = fu:GetData('Toolbar16.SavePos')
    local get_pos = fu:GetData('Toolbar16.Position')
    local at_mouse = fu:GetData('Toolbar16.OnMouse')
    if get_pos and save_pos then
        print('restoring position')
        return get_pos[1], get_pos[2]
    elseif at_mouse then
        print('launching at mouse position')
        local mouseXPos = fu.MouseX
        local mouseYPos = fu.MouseY 
        if mouseXPos > main_window_dimensions.Width - 750/2 then -- half window width - 770 / 2
            mouseXPos = mouseXPos - 750/2
        end
        return mouseXPos, mouseYPos
    else
        local leftOffset = main_window_dimensions.Width*.12
        posX = (main_window_dimensions.Width / 2 - leftOffset) + main_window_dimensions.Left 
        posY = view_attrs.VIEWN_Bottom + get_tb_offset(timeview_status)
        if posY > main_window_dimensions.Height then
            posY = main_window_dimensions.Height - 10
        end
        return posX, posY
    end
end

function show_ui()
    show_on_top = fu:GetData('Toolbar16.OnTop')
    _init('left')
    width, height = 750,26
    iconsMedium = {16,26}
    iconsMediumLong = {34,26}
    local x, y = get_window_xy()
    win = disp:AddWindow({
        ID = 'ToolbarWin',
        TargetID = 'ToolbarWin',
        WindowTitle = 'Viewer Toolbar for Fusion16',
        WindowFlags = {SplashScreen = true, NoDropShadowWindowHint = false, WindowStaysOnTopHint = show_on_top},
        Geometry = {x - (width) / 2, y, width, height},
        Spacing = 0,
        Margin = 0,
        
        ui:VGroup{
            ID = 'root',
            -- Add your GUI elements here:
            ui:HGroup{
                ui:HGroup{
                    Weight = 0.8,
                    ui:HGap(0.25,0),
                    ui:Button{
                        ID = 'IconButtonGuides',
                        Text = '',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Guides.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = guides_state 
                    },
                    ui:Button{
                        ID = 'IconButtonZoom',
                        Text = '100%',
                        Flat = true,
                        IconSize = {6,10},
                        MinimumSize = iconsMediumLong,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonFit',
                        Text = 'Fit',
                        IconSize = {6,2},
                        Flat = true,
                        MinimumSize = {28,26},
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonPolyline',
                        Flat = true,
                        IconSize = {16,16},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Polyline.png'},
                    },
                    ui:Button{
                        ID = 'IconButtonBSpline',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_BSpline.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonBitmap',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Bitmap.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonPaint',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Paint.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonWand',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Wand.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonRectangle',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Rectangle.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonCircle',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Circle.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui:Button{
                        ID = 'IconButtonStereo',
                        Flat = true,
                        Text = '',
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Stereo.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = stereo_state 
                    },
                    ui:Button{
                        ID = 'IconButtonLUT',
                        Text = 'LUT',
                        Flat = true,
                        MinimumSize = {30,16},
                        Checkable = true,
                        Checked = lut_state
                    },
                    ui:Button{
                        ID = 'IconButtonROI',
                        Text = 'RoI',
                        Flat = true,
                        MinimumSize = {30,16},
                        Checkable = true,
                        Checked = roi_state 
                    },
                    ui:Button{
                        ID = 'IconButtonDoD',
                        Text = 'DoD',
                        Flat = true,
                        IconSize = {5,10},
                        MinimumSize = iconsMediumLong,
                        Checkable = true,
                        Checked = dod_state
                    },
                    ui:Button{
                        ID = 'IconButtonLockCold',
                        Flat = true,
                        Text = '',
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_LockCold.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = locked_state
                    },
                    ui:Button{
                        ID = 'IconButtonControls',
                        Flat = true,
                        Text = '',
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Controls.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = controls_state
                    },
                    ui:Button{
                        ID = 'IconButtonChequers',
                        Flat = true,
                        Text = '',
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Chequers.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = checker_state
                    },
                    -- ui:Button{
                    --     ID = 'IconButtonOne2One',
                    --     Flat = true,
                    --     IconSize = {16,16},
                    --     Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_One2One.png'},
                    --     MinimumSize = iconsMedium,
                    --     Checkable = true,
                    -- },
                    -- ui:Button{
                    --     ID = 'IconButtonNormalise',
                    --     Flat = true,
                    --     IconSize = {16,16},
                    --     Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Normalise.png'},
                    --     MinimumSize = iconsMedium,
                    --     Checkable = true,
                    -- },
                    ui:Button{
                        ID = 'IconButtonSliders',
                        Flat = true,
                        Text = '',
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Sliders.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = sliders_state 
                    },
                    ui:Button{
                        ID = 'IconButtonMultiView',
                        Text = '',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_MultiView.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = multiview_state 
                    },
                },
                ui:HGroup{
                    Weight = 0.2,
                    ui:Button{
                        ID = 'Left',
                        Text = 'left',
                        IconSize = {6,2},
                        Flat = true,
                        MinimumSize = iconsMediumLong,
                        Checkable = true,
                        Checked = true,
                    },
                    ui:Button{
                        ID = 'Right',
                        Text = 'right',
                        Flat = true,
                        MinimumSize = iconsMediumLong,
                        IconSize = {6,2},
                        Checkable = true,
                        Checked = false,
                    },
                    ui:Button{
                        ID = 'RefreshButtons',
                        Text = '',
                        IconSize = {12,12},
                        MinimumSize = iconsMedium,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/refresh_icon.png'},
                        Enable = false,
                    },                    
                    ui:Button{
                        ID = 'Layout01',
                        Flat = true,
                        IconSize = {16,16},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Layout01.png'},
                    },                    
                    ui:Button{
                        ID = 'Layout02',
                        Flat = true,
                        IconSize = {16,16},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Layout02.png'},
                    },                    
                    ui:Button{
                        ID = 'Layout03',
                        Flat = true,
                        IconSize = {16,16},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Layout03.png'},
                    },                    
                    ui:Button{
                        ID = 'ExpandViewButton',
                        Flat = true,
                        IconSize = {16,16},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Expand.png'},
                    },                             
                    ui:Button{
                        ID = 'CloseButton',
                        Text = 'Exit',
                        Flat = false,
                        MinimumSize = {40,16},
                        Checkable = false
                    },
                    ui:Button{
                        ID = 'LaunchPrefs',
                        Text = '',
                        Flat = true,
                        IconSize = {6,6},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Triangle.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
                    },
                    ui.HGap(0.25,0),
                },
            },

        },
    })
    return win, {x, y}
end

local main_win = ui:FindWindow("ToolbarWin")
if main_win then
    print('toggle existing UI') 
    if main_win.Hidden then
        main_win:SetHidden(false)
    else
        main_win:SetHidden(true)
    end
    return
else
    win, position = show_ui()
    fu:SetData('Toolbar16.Position', position)
end

-- The window was closed
function win.On.ToolbarWin.Close(ev)
    disp:ExitLoop()
end

function win.On.CloseButton.Clicked(ev)
    disp:ExitLoop()
end

-- show preferences

local prefs_dlg = nil

function toggle_prefs()
    if prefs_dlg then
        if prefs_dlg.Hidden then
            prefs_dlg:Show()
        else
            prefs_dlg:Hide()
            prefs_dlg = nil
        end
    else
        show_prefs_window(position)
    end
end


function show_prefs_window(pos)
    local prefx, prefy = pos[1], pos[2]
    if inspector_hidden then
        prefx = prefx+200
    end
    local offsetY = -128
    if prefy < 120 then
        offsetY = offsetY + 120
    end
    save_pos = fu:GetData('Toolbar16.SavePos')
    on_top = fu:GetData('Toolbar16.OnTop')
    at_mouse = fu:GetData('Toolbar16.OnMouse')
    expand_status = fu:GetData('Toolbar16.ExpandWithLayout')

    prefs_dlg = disp:AddWindow({
        ID = 'TBPrefs',
        TargetID = 'TBPrefs',
        WindowFlags = {SplashScreen = true, NoDropShadowWindowHint = true, WindowStaysOnTopHint = false},
        Geometry = {prefx +135, prefy+offsetY, 250, 120},
            ui:VGroup{
            ID = 'prefs',
                ui:HGroup{
                    ui:CheckBox{
                        ID = 'SavePos',
                        Text = 'save position',
                        Checked = save_pos,
                    },
                    ui:Button{
                        ID = 'FlushData',
                        Text = 'reset prefs',
                        MaximumSize = {80,17},
                    },
                },
                ui:HGroup{
                    ui:CheckBox{
                        ID = 'OnMouse',
                        Text = 'launch at mouse',
                        Checked = at_mouse,
                    },
                        ui:CheckBox{
                        ID = 'OnTop',
                        Text = 'stay on top',
                        Checked = on_top,
                    },
                },
                ui:HGroup{
                    ui:CheckBox{
                        ID = 'ExpandWithLayout',
                        Text = 'hide LayoutStrip (β)',
                        Checked = expand_status,
                    },
                    ui:Button{
                        MaximumSize = {70, 17},
                        ID = 'Layouter',
                        Text = 'Layouter',
                    },
                },
                ui:HGroup{
                    ui:Button{
                        MaximumSize = {135, 17},
                        ID = 'MoreToolbars',
                        Text = 'add toolbars!',
                    },

                    ui:Button{
                        MaximumSize = {80, 17},
                        ID = 'SavePrefs',
                        Text = 'save',
                    },
                }
            },
        })

    pref_itm = prefs_dlg:GetItems()


    function prefs_dlg.On.Layouter.Clicked(ev)
       comp:RunScript("Scripts:Comp/Layouter/Layouter.lua") 
       prefs_dlg:Hide()
       prefs_dlg = nil
    end

    function prefs_dlg.On.SavePrefs.Clicked(ev)
        fu:SetData('Toolbar16.OnMouse', at_mouse)
        fu:SetData('Toolbar16.SavePos', save_pos)
        fu:SetData('Toolbar16.ExpandWithLayout', expand_status)
        fu:SetData('Toolbar16.OnTop', on_top)
        prefs_dlg:Hide()
        prefs_dlg = nil
    end

    function prefs_dlg.On.MoreToolbars.Clicked(ev)
        fu:CustomizeToolbars()
        prefs_dlg:Hide()
        prefs_dlg = nil
    end

    function prefs_dlg.On.OnMouse.Clicked(ev)
        at_mouse = pref_itm.OnMouse.Checked
        if at_mouse then
            pref_itm.SavePos.Checked = false
            save_pos = false
            print('next time UI will open at mouse position')
        else
            print('UI will lauch normally under the viewer')
        end
    end

    function prefs_dlg.On.SavePos.Clicked(ev)
        save_pos = pref_itm.SavePos.Checked
        if save_pos then
            pref_itm.OnMouse.Checked = false
            at_mouse = false
        end
        print('saving main window position set to ' .. tostring(save_pos))
    end

    function prefs_dlg.On.ExpandWithLayout.Clicked(ev)
        expand_status = pref_itm.ExpandWithLayout.Checked
        print('hide LayoutStrip is set to ' .. tostring(expand_status))
    end

    function prefs_dlg.On.OnTop.Clicked(ev)
        on_top = pref_itm.OnTop.Checked
        print('stay on top is set to ' .. tostring(on_top))
    end

    function prefs_dlg.On.FlushData.Clicked(ev)
        fu:SetData('Toolbar16')
        print('toolbar preferences data flushed')
        prefs_dlg:Hide()
        prefs_dlg = nil
    end

    prefs_dlg:Show()
end


itm = win:GetItems()


function win.On.LaunchPrefs.Clicked(ev)
    pref_win = ui:FindWindow('TBPrefs')
    toggle_prefs()
end


function refresh_ui()
    itm.IconButtonStereo.Checked = stereo_state
    itm.IconButtonLUT.Checked = lut_state
    itm.IconButtonROI.Checked = roi_state
    itm.IconButtonDoD.Checked = dod_state
    itm.IconButtonLockCold.Checked = locked_state
    itm.IconButtonControls.Checked = controls_state 
    itm.IconButtonChequers.Checked = checker_state
    itm.IconButtonSliders.Checked = sliders_state
    itm.IconButtonGuides.Checked = guides_state
    itm.IconButtonMultiView.Checked = multiview_state
end


function win.On.Right.Clicked(ev)
    itm.Left.Checked = false
    _init('right')
    refresh_ui()
end

function win.On.Left.Clicked(ev)
    itm.Right.Checked = false
    _init('left')
    refresh_ui()
end

---------- set glview attrs

function win.On.IconButtonMultiView.Clicked(ev)
    state = itm.IconButtonMultiView.Checked
    print('[Guides] [Button State] ' , state)
    GlView:ShowQuadView(state)
end

function win.On.IconButtonZoom.Clicked(ev)
    state = itm.IconButtonZoom.Checked
    print('[Zoom] is set to 100%')
    GlView:SetScale(1)
end

function win.On.IconButtonFit.Clicked(ev)
    state = itm.IconButtonFit.Checked
    print('[Fit] to View')
    GlView:SetScale(0)
end

function win.On.IconButtonStereo.Clicked(ev)
    state = itm.IconButtonStereo.Checked
    print('[Stereo][Button State] ', state)
    GlView:EnableStereo()
end

function win.On.IconButtonLockCold.Clicked(ev)
    state = itm.IconButtonLockCold.Checked
    print('[LockCold][Button State] ', state)
    GlView:SetLocked(state)
end

---------- add tools 
function win.On.IconButtonPolyline.Clicked(ev)
    print('[Polyline] created')
    comp:AddTool('PolylineMask', -32768, -32768)
end

function win.On.IconButtonBSpline.Clicked(ev)
    print('[BSpline] created')
    comp:AddTool('BSplineMask', -32768, -32768)
end

function win.On.IconButtonBitmap.Clicked(ev)
    print('[Bitmap] created')
    comp:AddTool('BitmapMask', -32768, -32768)
end

function win.On.IconButtonPaint.Clicked(ev)
    print('[Paint] created')
    comp:AddTool('PaintMask', -32768, -32768)
end

function win.On.IconButtonWand.Clicked(ev)
    print('[Wand] created')
    comp:AddTool('WandMask', -32768, -32768)
end

function win.On.IconButtonRectangle.Clicked(ev)
    print('[Rectangle] created')
    comp:AddTool('RectangleMask', -32768, -32768)
end

function win.On.IconButtonCircle.Clicked(ev)
    print('[Circle] created')
    comp:AddTool('EllipseMask', -32768, -32768)
end

------- change GlView attrs

function win.On.IconButtonGuides.Clicked(ev)
    state = itm.IconButtonGuides.Checked
    viewer = GlView.CurrentViewer
    if not viewer then
        return
    end
    viewer:ShowGuides(state)
    viewer:Redraw()
    print('[Guides] [Button state] ', state)
end

function win.On.IconButtonLUT.Clicked(ev)
    state = itm.IconButtonLUT.Checked
    viewer = GlView.CurrentViewer
    if not viewer or viewer_type == '3D' then
        return
    end
    print('[LUT][Button State] ', state)
    viewer:EnableLUT(state)
    viewer:Redraw()
end

function win.On.IconButtonROI.Clicked(ev)
    state = itm.IconButtonROI.Checked
    viewer = GlView.CurrentViewer
    if not viewer or viewer_type == '3D' then
        return
    end
    print('[ROI][Button State] ', state)
    viewer:EnableRoI(state)
    viewer:Redraw()
end

function win.On.IconButtonDoD.Clicked(ev)
    state = itm.IconButtonDoD.Checked
    viewer = GlView.CurrentViewer
    if not viewer or viewer_type == '3D' then
        return
    end
    print('[DoD][Button State] ', state)
    viewer:ShowDoD(state)
    viewer:Redraw()
end

function win.On.IconButtonControls.Clicked(ev)
    state = itm.IconButtonControls.Checked
    viewer = GlView.CurrentViewer
    if not viewer then
        return
    end
    print('[Controls][Button State] ', state)
    viewer:ShowControls(state)
    viewer:Redraw()
end

function win.On.IconButtonSliders.Clicked(ev)
    state = itm.IconButtonSliders.Checked
    if fu.Version >= 16 then
        viewer = GlView.CurrentViewer
        if not viewer or viewer_type == '3D' then
            return
        end
        itm.IconButtonControls.Checked = true
        viewer:ShowControls(true)
        viewer:ShowGainGamma(state)
        print('[Sliders][Button State] ', state)
    else
        print('this function does not work in Fu9')
    end
end

function win.On.IconButtonChequers.Clicked(ev)
    state = itm.IconButtonChequers.Checked
    if fu.Version >= 16 then
        viewer = GlView.CurrentViewer
        if not viewer or viewer_type == '3D' then
            return
        end
        viewer:EnableChecker(state)
        viewer:Redraw()
        print('[Chequers][Button State] ', state)
    else
        print('this function does not work in Fu9')
    end
end

function move_window(main_win, Y_offset)
    local view_attrs = get_glview('left'):GetAttrs()
    if not main_win then
        main_win = ui:FindWindow('ToolbarWin')
    end
    local window_ypos = main_win:Y()
    local viewer_Y = view_attrs.VIEWN_Bottom
    Y_pos = viewer_Y + Y_offset
    if Y_pos ~= window_ypos then
        if Y_pos > main_window_dimensions.Height then
            Y_pos = main_window_dimensions.Height - 10
        end
        main_win:Move({main_win:X(), Y_pos})
        position = {position[1], Y_pos}
    end

end


function win.On.RefreshButtons.Clicked(ev)
    if itm.Left.Checked == true then
        side = 'left'
    else
        side = 'right'
    end
    _init(side)
    _init(side)
    refresh_ui()
    current_comp_name = comp:GetAttrs().COMPS_FileName 
    if current_comp_name ~= fu:GetData('Toolbar16.CurrentComp') then
        fu:SetData('Toolbar16.CurrentComp', current_comp_name)
    end
    timeview_status = comp:IsViewShowing('Time')
    offset = get_tb_offset(timeview_status)
    move_window(win, offset)
end

-- Layout change

function win.On.Layout01.Clicked(ev)
    local isViewer2 = comp:IsViewShowing('Viewer2')
    if layout_num and layout_num ~= 1 then
        comp:DoAction("Fusion_View_Show", {view = "Viewer2", show = isViewer2})
    else
        comp:DoAction("Fusion_View_Show", {view = "Viewer2"})
    end
    comp:DoAction("Fusion_View_Show", {view = "Viewer1", show = true})
    comp:DoAction("Fusion_View_Show", {view = "Inspector", show = true})
    comp:DoAction("Fusion_Zone_Expand", {zone = "Right", expand = true})
    at_mouse = fu:GetData('Toolbar16.OnMouse')
    if inspector_hidden and not at_mouse then
        win:Move({win:X() - 200, win:Y()})
        inspector_hidden = false
    end
    layout_num = 1
end

function win.On.Layout02.Clicked(ev)
    local isViewer2 = comp:IsViewShowing('Viewer2')
    if layout_num ~= 2 then
        comp:DoAction("Fusion_View_Show", {view = "Viewer2", show = isViewer2})
    else
        comp:DoAction("Fusion_View_Show", {view = "Viewer2"})
    end
    comp:DoAction("Fusion_View_Show", {view = "Inspector", show = true})
    comp:DoAction("Fusion_Zone_Expand", {zone = "Right", expand = false}) 
    at_mouse = fu:GetData('Toolbar16.OnMouse')
    if inspector_hidden and not at_mouse then
        win:Move({win:X() - 200, win:Y()})
        inspector_hidden = false
    end
    layout_num = 2
end

function win.On.Layout03.Clicked(ev)
    local isViewer2 = comp:IsViewShowing('Viewer2')
    if layout_num == 3 then
        comp:DoAction("Fusion_View_Show", {view = "Viewer2"})
    else
        comp:DoAction("Fusion_View_Show", {view = "Viewer2", show = isViewer2})
    end
    comp:DoAction("Fusion_View_Show", {view = "Viewer1", show = true})
    comp:DoAction("Fusion_View_Show", {view = "Inspector", show = false})
    comp:DoAction("Fusion_Zone_Expand", {zone = "Right", expand = false})
    at_mouse = fu:GetData('Toolbar16.OnMouse')
    if not inspector_hidden and not at_mouse then
        inspector_hidden = true
        win:Move({win:X() + 200, win:Y()})
    end
    layout_num = 3
end

function win.On.ExpandViewButton.Clicked(ev)
    timeview_status = comp:IsViewShowing('Time')
    timeview_status = not timeview_status
    expand_status = fu:GetData('Toolbar16.ExpandWithLayout')
    if expand_status then
        _ViewLayout = comp.CurrentFrame:GetViewLayout()
        _LayoutStripState = _ViewLayout.ViewInfo.LayoutStrip.Show 
        _ViewLayout.ViewInfo.LayoutStrip.Show = timeview_status 
        comp.CurrentFrame:SetViewLayout(_ViewLayout)
    end
    comp:DoAction("Fusion_View_Show", {view = "Time", show = timeview_status})
    local offset = get_tb_offset(timeview_status)
    move_window(win, offset)
end

-- Display the window
win:Show()

-- Keep the window updating until the script is quit
disp:RunLoop()
win:Hide()
app:RemoveConfig('ToolbarWin')
collectgarbage()
print('[Done]')
