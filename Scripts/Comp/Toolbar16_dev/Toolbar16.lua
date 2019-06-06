--[[
v 1.3 add some working buttons 2019-05-21
-- partial implementation for Fusion 16 by Alex Bogomolov 
v 1.0 Initial release 2019-01-21
-- original sample script and icons by Andrew Hazelden 
Email:  andrew@andrewhazelden.com
        mail@abogomolov.com
Web: www.andrewhazelden.com
     https://abogomolov.com
     https://paypal.me/aabogomolov
]]

show_on_top = false

function _init(side)
    view = get_viewer(side)
    viewer = view.CurrentViewer
    comp = fu:GetCurrentComp()
    if not viewer then
        print('Load any 2D tool to the '.. side ..' viewer')
        return nil
    end
    locked_state = view:GetLocked()
    multiview_state = view:ShowingQuadView()
    stereo_state = view:IsStereoEnabled()
    controls_state = viewer:AreControlsShown()
    guides_state = viewer:AreGuidesShown()
    lut_state = viewer:IsLUTEnabled()
    roi_state = viewer:IsEnableRoI()


    if fu.Version == 16 and not fu:GetAttrs('FUSIONB_IsResolve') then
        dod_state = viewer:IsDoDShown()
        checker_state = viewer:IsCheckerEnabled()
        sliders_state = viewer:IsShowGainGamma()
    else
        dod_state = false
        checker_state = false
        sliders_state = false
    end
end


function get_viewer(side)
    if side == 'left' then
        if fu.Version == 16 then
            glview = comp:GetPreviewList().LeftView.View
        else
            glview = comp:GetPreviewList().Left.View
        end
    elseif side == 'right' then
        if fu.Version == 16 then
            glview = comp:GetPreviewList().RightView.View
        else
            glview = comp:GetPreviewList().Right.View
        end
    end
    return glview
end

_init('left')

ui = fu.UIManager
disp = bmd.UIDispatcher(ui)

function show_ui()
    width, height = 650,26
    iconsMedium = {16,26}
    iconsMediumLong = {34,26}
    local x = fu:GetMousePos()[1]
    local y = fu:GetMousePos()[2]
    local win = disp:AddWindow({
        ID = 'ToolbarWin',
        TargetID = 'ToolbarWin',
        WindowTitle = 'Viewer Toolbar for Fusion16',
        WindowFlags = {SplashScreen = true,  NoDropShadowWindowHint = true, WindowStaysOnTopHint = show_on_top},
        Geometry = {x - (width) / 2, y, width, height},
        -- Geometry = {0, 0, width, height},
        Spacing = 0,
        Margin = 0,
        
        ui:VGroup{
            ID = 'root',
            -- Add your GUI elements here:
            ui:HGroup{
                ui:HGroup{
                    Weight = 0.8,
                    ui.HGap(0.25,0),
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
                        ID = 'IconButtonMultiView',
                        Text = '',
                        Flat = true,
                        IconSize = {16,16},
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_MultiView.png'},
                        MinimumSize = iconsMedium,
                        Checkable = true,
                        Checked = multiview_state 
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
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/PT_Polyline.png'},
                        MinimumSize = iconsMedium,
                        Checkable = false,
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
                        ID = 'RefreshButtons',
                        Text = '',
                        IconSize = {12,12},
                        MinimumSize = iconsMedium,
                        Icon = ui:Icon{File = 'Scripts:/Comp/Toolbar16/Icons/refresh_icon.png'},
                        Enable = false,
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
                        ID = 'CloseButton',
                        Text = 'Close',
                        Flat = false,
                        MinimumSize = {40,16},
                        Checkable = false
                    },
                    ui.HGap(0.25,0),
                },
            },

        },
    })
    return win
end

win = show_ui()

-- The window was closed

function win.On.ToolbarWin.Close(ev)
    disp:ExitLoop()
end

function win.On.CloseButton.Clicked(ev)
    disp:ExitLoop()
end

-- Add your GUI element based event functions here:

itm = win:GetItems()

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
    view:ShowQuadView(state)
end

function win.On.IconButtonZoom.Clicked(ev)
    state = itm.IconButtonZoom.Checked
    print('[Zoom] is set to 100%')
    view:SetScale(1)
end

function win.On.IconButtonFit.Clicked(ev)
    state = itm.IconButtonFit.Checked
    print('[Fit] to view')
    view:SetScale(0)
end

function win.On.IconButtonStereo.Clicked(ev)
    state = itm.IconButtonStereo.Checked
    print('[Stereo][Button State] ', state)
    view:EnableStereo()
end

function win.On.IconButtonLockCold.Clicked(ev)
    state = itm.IconButtonLockCold.Checked
    print('[LockCold][Button State] ', state)
    view:SetLocked(state)
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

------- change view attrs

function win.On.IconButtonGuides.Clicked(ev)
    state = itm.IconButtonGuides.Checked
    viewer = view.CurrentViewer
    if not viewer then
        return
    end
    viewer:ShowGuides(state)
    viewer:Redraw()
    print('[Guides] [Button state] ', state)
end

function win.On.IconButtonLUT.Clicked(ev)
    state = itm.IconButtonLUT.Checked
    viewer = view.CurrentViewer
    if not viewer then
        return
    end
    print('[LUT][Button State] ', state)
    viewer:EnableLUT(state)
    viewer:Redraw()
end

function win.On.IconButtonROI.Clicked(ev)
    state = itm.IconButtonROI.Checked
    viewer = view.CurrentViewer
    if not viewer then
        return
    end
    print('[ROI][Button State] ', state)
    viewer:EnableRoI(state)
    viewer:Redraw()
end

function win.On.IconButtonDoD.Clicked(ev)
    state = itm.IconButtonDoD.Checked
    viewer = view.CurrentViewer
    if not viewer then
        return
    end
    print('[DoD][Button State] ', state)
    viewer:ShowDoD(state)
    viewer:Redraw()
end

function win.On.IconButtonControls.Clicked(ev)
    state = itm.IconButtonControls.Checked
    viewer = view.CurrentViewer
    if not viewer then
        return
    end
    print('[Controls][Button State] ', state)
    viewer:ShowControls(state)
    viewer:Redraw()
end

function win.On.IconButtonSliders.Clicked(ev)
    state = itm.IconButtonSliders.Checked
    if fu.Version == 16 then
        viewer = view.CurrentViewer
        if not viewer then
            return
        end
        itm.IconButtonControls.Checked = true
        viewer:ShowControls(true)
        viewer:ShowGainGamma(state)
        print('[Sliders][Button State] ', state)
    else
        print('this does not work in Fu9')
    end
end

function win.On.IconButtonChequers.Clicked(ev)
    state = itm.IconButtonChequers.Checked
    if fu.Version == 16 then
        viewer = view.CurrentViewer
        if not viewer then
            return
        end
        viewer:EnableChecker(state)
        viewer:Redraw()
        print('[Chequers][Button State] ', state)
    else
        print('this does not work in Fu9')
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

-- Display the window
win:Show()

-- Keep the window updating until the script is quit
disp:RunLoop()
win:Hide()
app:RemoveConfig('ToolbarWin')
collectgarbage()
print('[Done]')

