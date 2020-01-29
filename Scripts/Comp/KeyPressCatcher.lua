_author = "Alexey Bogomolov <mail@abogomolov.com>"
_date = "2020-01-29"
_VERSION = "0.1"


local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)


mainWindow = fu:GetPrefs("Global.Main.Window")
if not mainWindow or mainWindow.Width == -1 then
	if app:GetVersion().App == 'Fusion' then
		print("[Warning] The Window dimensions are undefined. Please press 'Grab probram layout' button in the Layout Preferences section.")
		app:ShowPrefs("PrefsLayout")
	else
		print('setting UI width to default 1920px until better solution for Resolve arrived')
		mainWindow.Width = 1920
		mainWindow.Height = 1100
	end
end

minWidth, minHeight = 300, 200
originX, originY = mainWindow.Left + (mainWindow.Width/2) - (minWidth/2), mainWindow.Top + (mainWindow.Height/2) - (minHeight/2)




------------------------------------------------------------------------
-- The Main Function
function Main()
	print(string.format("[Layouter] - v%s %s ", _VERSION, _date))
	print(string.format("[Created By] %s\n\n", _author))
	
	-- Check if the Fusion GUI is running
	if fusion == nil then
		print("[Fusion] Error: Please open up the Fusion GUI before running this tool.\n")
	else
		-- Display the progress dialog
		ui = app.UIManager
		disp = bmd.UIDispatcher(ui)

		-- Show the progress window
		local msgwin,msgitm = WinCreate()
		WinUpdate(msgwin, msgitm, "Layouter")
	end
end


local win = disp:AddWindow({
	ID = 'Win',
	Geometry = {originX, originY, minWidth, minHeight},
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
