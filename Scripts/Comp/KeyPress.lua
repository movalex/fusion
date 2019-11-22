local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

win = disp:AddWindow({
	ID = 'Win',
	Geometry = { 0, 0, 200, 100 },
	WindowTitle = 'KeyEvents',
    WindowFlags = {SplashScreen = true},
    Events = { Close = true, KeyPress = true, KeyRelease = true, },
    ui:VGroup{
        ui:Button{ID = "Button", Text = "Button",},
        ui:Button{ID = "Close", Text = "Close"},
        },
    })

itm = win:GetItems()

function win.On.Win.Close(ev)
	disp:ExitLoop()
end

-- A flag to track shift state
local shiftdown = false

function win.On.Close.Clicked(ev)
    disp:ExitLoop()
end

-- If the shift key is pressed, set our flag
function win.On.Win.KeyPress(ev)
	if ev.Key == 0x1000020 then
		shiftdown = true
		itm.Button.Text = "Shift+Button"
	end
end

-- If the shift key is released, reset our flag
function win.On.Win.KeyRelease(ev)
	if ev.Key == 0x1000020 then
		shiftdown = false
		itm.Button.Text = "Button"
	end
end

-- Now we can use our flag to differentiate button presses
function win.On.Button.Clicked(ev)
	if shiftdown then
		print("Shift+Button")
	else
		print("Button")
	end
end

win:Show()
disp:RunLoop()
win:Hide()
