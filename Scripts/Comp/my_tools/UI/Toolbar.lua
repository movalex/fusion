--[[
Toolbar - v1.0 2019-01-21
by Andrew Hazelden 
Email: andrew@andrewhazelden.com
Web: www.andrewhazelden.com

## Overview ##

This is a Viewer window toolbar demo that re-creates the look of the Fusion 9 toolbar using UI Manager ui:Button controls.

## Usage ##

1. In Fusion select the "Script > UI Manager > Toolbar > Toolbar" menu item.

2. As you click across the button controls in the toolbar window you will see the individual button states printed in the Console view.

]]

local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)
-- local width,height = 1920,26
local width,height = 1000,26
local iconsMedium = {16,26}
local iconsMediumLong = {50,26}

win = disp:AddWindow({
	ID = 'ToolbarWin',
	TargetID = 'ToolbarWin',
	WindowTitle = 'Viewer Toolbar',
	-- Geometry = {0, 540, width, height},
	Geometry = {0, 0, width, height},
	Spacing = 0,
	Margin = 0,
	
	ui:VGroup{
		ID = 'root',
		
		-- Add your GUI elements here:
		
		ui:HGroup{
			ui:HGroup{
				Weight = 0.7,
				
				-- Add three buttons that have an icon resource attached and no border shading
				-- ui:Button{
				--     ID = 'IconButtonSubV',
				--     Text = 'SubV',
				--     Flat = true,
				--     IconSize = {10,10},
				--     Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/TriangleUp.png'},
				--     MinimumSize = iconsMediumLong,
				--     Checkable = true,
				-- },
				ui:Button{
					ID = 'IconButtonZoom',
					Text = '100%',
					Flat = true,
					IconSize = {6,10},
					-- Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/TriangleUp.png'},
					MinimumSize = iconsMediumLong,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonFit',
					Text = 'Fit',
					IconSize = {6,2},
					Flat = true,
					MinimumSize = iconsMediumLong,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonPolyline',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Polyline.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonBSpline',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_BSpline.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonBitmap',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Bitmap.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonPaint',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Paint.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonWand',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Wand.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonRectangle',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Rectangle.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonCircle',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Circle.png'},
					MinimumSize = iconsMedium,
					Checkable = false,
				},
				ui:Button{
					ID = 'IconButtonABuffer',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_ABuffer.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
					Checked = true,
				},
				ui:Button{
					ID = 'IconButtonSplitBuffer',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_SplitBuffer.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonBBuffer',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_BBuffer.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonStereo',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Stereo.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonSnap',
					Text = 'Snap',
					Flat = true,
					MinimumSize = iconsMediumLong,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonColour',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Colour.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
					Checked = true,
				},
				ui:Button{
					ID = 'IconButtonLUT',
					Text = 'LUT',
					Flat = true,
					IconSize = {10,10},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/TriangleUp.png'},
					MinimumSize = iconsMediumLong,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButton360',
					Text = '360°',
					Flat = true,
					IconSize = {10,10},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/TriangleUp.png'},
					MinimumSize = iconsMediumLong,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonROI',
					Text = 'RoI',
					Flat = true,
					IconSize = {10,10},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/TriangleUp.png'},
					MinimumSize = iconsMediumLong,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonDoD',
					Text = 'DoD',
					Flat = true,
					MinimumSize = iconsMediumLong,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonLockCold',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_LockCold.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonControls',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Controls.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
					Checked = true,
				},
				ui:Button{
					ID = 'IconButtonChequers',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Chequers.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonSmR',
					Text = 'SmR',
					Flat = true,
					MinimumSize = iconsMediumLong,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonOne2One',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_One2One.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonNormalise',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Normalise.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
				ui:Button{
					ID = 'IconButtonSliders',
					Flat = true,
					IconSize = {16,16},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/PT_Sliders.png'},
					MinimumSize = iconsMedium,
					Checkable = true,
				},
			},
			ui:HGroup{
				Weight = 0.3,
				ui:Button{
					ID = 'IconButtonTool',
					Text = 'Background 1',
					Flat = true,
					IconSize = {10,10},
					Icon = ui:Icon{File = 'Scripts:/Comp/UI Manager/Toolbar/Icons.zip/TriangleUp.png'},
					Checkable = false,
				},
			},
		},

	},
})

-- The window was closed
function win.On.ToolbarWin.Close(ev)
		disp:ExitLoop()
end

-- Add your GUI element based event functions here:
itm = win:GetItems()

-- function win.On.IconButtonSubV.Clicked(ev)
--     state = itm.IconButtonSubV.Checked
--     print('[SubV][Button State] ', state)
-- end

function get_viewer(param)
    view = comp:GetPreviewList().LeftView.View
    left = view.CurrentViewer
    return left
end


function win.On.IconButtonZoom.Clicked(ev)
	state = itm.IconButtonZoom.Checked
	print('[Zoom][Button State] ', state)

end

function win.On.IconButtonFit.Clicked(ev)
	state = itm.IconButtonFit.Checked
	print('[Fit][Button State] ', state)
end

function win.On.IconButtonPolyline.Clicked(ev)
	state = itm.IconButtonPolyline.Checked
	print('[Polyline][Button State] ', state)
end

function win.On.IconButtonBSpline.Clicked(ev)
	state = itm.IconButtonBSpline.Checked
	print('[BSpline][Button State] ', state)
end

function win.On.IconButtonBitmap.Clicked(ev)
	state = itm.IconButtonBitmap.Checked
	print('[Bitmap][Button State] ', state)
end

function win.On.IconButtonPaint.Clicked(ev)
	state = itm.IconButtonPaint.Checked
	print('[Paint][Button State] ', state)
end

function win.On.IconButtonWand.Clicked(ev)
	state = itm.IconButtonWand.Checked
	print('[Wand][Button State] ', state)
end

function win.On.IconButtonRectangle.Clicked(ev)
	state = itm.IconButtonRectangle.Checked
	print('[Rectangle][Button State] ', state)
end

function win.On.IconButtonCircle.Clicked(ev)
	state = itm.IconButtonCircle.Checked
	print('[Circle][Button State] ', state)
end

function win.On.IconButtonABuffer.Clicked(ev)
	state = itm.IconButtonABuffer.Checked
	
	itm.IconButtonSplitBuffer.Checked = false
	itm.IconButtonBBuffer.Checked = false
	print('[ABuffer][Button State] ', state)
end

function win.On.IconButtonSplitBuffer.Clicked(ev)
	state = itm.IconButtonSplitBuffer.Checked
	
	itm.IconButtonABuffer.Checked = false
	itm.IconButtonBBuffer.Checked = false
	print('[SplitBuffer][Button State] ', state)
end

function win.On.IconButtonBBuffer.Clicked(ev)
	state = itm.IconButtonBBuffer.Checked
	
	itm.IconButtonABuffer.Checked = false
	itm.IconButtonSplitBuffer.Checked = false
	print('[BBuffer][Button State] ', state)
end

function win.On.IconButtonStereo.Clicked(ev)
	state = itm.IconButtonStereo.Checked
	print('[Stereo][Button State] ', state)
end

function win.On.IconButtonSnap.Clicked(ev)
	state = itm.IconButtonSnap.Checked
	print('[Snap][Button State] ', state)
end

function win.On.IconButtonColour.Clicked(ev)
	state = itm.IconButtonColour.Checked
	print('[Colour][Button State] ', state)
end

function win.On.IconButtonLUT.Clicked(ev)
	state = itm.IconButtonLUT.Checked
	print('[LUT][Button State] ', state)
end

function win.On.IconButton360.Clicked(ev)
	state = itm.IconButton360.Checked
	print('[360][Button State] ', state)
end

function win.On.IconButtonROI.Clicked(ev)
	state = itm.IconButtonROI.Checked
	print('[ROI][Button State] ', state)
    left = get_viewer()
    left:ShowRoI()
    left:Redraw()
end

function win.On.IconButtonDoD.Clicked(ev)
	state = itm.IconButtonDoD.Checked
	print('[DoD][Button State] ', state)
    left = get_viewer()
    left:ShowDoD()
    left:Redraw()
end

function win.On.IconButtonLockCold.Clicked(ev)
	state = itm.IconButtonLockCold.Checked
	print('[LockCold][Button State] ', state)
end

function win.On.IconButtonControls.Clicked(ev)
	state = itm.IconButtonControls.Checked
	print('[Controls][Button State] ', state)
end

function win.On.IconButtonChequers.Clicked(ev)
	state = itm.IconButtonChequers.Checked
	print('[Chequers][Button State] ', state)
end

function win.On.IconButtonSmR.Clicked(ev)
	state = itm.IconButtonSmR.Checked
	print('[SmR][Button State] ', state)
end

function win.On.IconButtonOne2One.Clicked(ev)
	state = itm.IconButtonOne2One.Checked
	print('[One2One][Button State] ', state)
end

function win.On.IconButtonNormalise.Clicked(ev)
	state = itm.IconButtonNormalise.Checked
	print('[Normalise][Button State] ', state)
end

function win.On.IconButtonSliders.Clicked(ev)
	state = itm.IconButtonSliders.Checked
	print('[Sliders][Button State] ', state)
end

function win.On.IconButtonTool.Clicked(ev)
	state = itm.IconButtonTool.Checked
	print('[Tool][Button State] ', state)
end

-- The app:AddConfig() command that will capture the "Shift + Control + W" or "Shift + Control + F4" hotkeys so they will close the window instead of closing the foreground composite.
	app:AddConfig('ToolbarWin', {
		Target {
			ID = 'ToolbarWin',
		},

		Hotkeys {
			Target = 'ToolbarWin',
			Defaults = true,
			
			SHIFT_CONTROL_W = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
			SHIFT_CONTROL_F4 = 'Execute{cmd = [[app.UIManager:QueueEvent(obj, "Close", {})]]}',
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
